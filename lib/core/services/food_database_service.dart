// lib/core/services/food_database_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/indian_food_model.dart';
import 'food_adapter.dart';

class FoodDatabaseService {
  static const String _boxName = 'indian_foods';
  static const String _assetsPath =
      'lib/core/services/database.json'; // Updated to use the new database
  static bool _offConfigured = false;
  static const int _minOffQueryLength = 3;
  static const Duration _offTimeout = Duration(seconds: 20);
  static const Duration _cacheTtl = Duration(minutes: 10);
  static const int _maxCacheItems = 50;
  static const String _cacheKeysKey = 'food_cache_ids';
  static final Map<String, List<IndianFoodModel>> _searchCache = {};
  static final Map<String, DateTime> _searchCacheTimes = {};
  static final Map<String, String> _searchCacheSource = {};
  static List<IndianFoodModel>? _localDbCache;
  static String? lastOffError;

  static Future<void> initialize() async {
    try {
      // Open Hive box
      final box = await Hive.openBox<IndianFoodModel>(_boxName);
      if (box.length > _maxCacheItems) {
        await _trimCache(box);
      }
    } catch (e) {
      print('Error initializing food database: $e');
    }
  }

  static Future<void> ensureBoxOpen() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<IndianFoodModel>(_boxName);
    }
  }

  static Future<List<IndianFoodModel>> searchLocalFoods(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    final cached = _searchCache[normalizedQuery];
    final cachedAt = _searchCacheTimes[normalizedQuery];
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl &&
        _searchCacheSource[normalizedQuery] == 'local') {
      return cached;
    }

    final allFoods = await _loadLocalFoods();

    if (normalizedQuery.isEmpty) {
      return allFoods;
    }

    final localResults = _searchLocalInList(allFoods, normalizedQuery);
    if (localResults.isNotEmpty) {
      await _cacheFoods(localResults);
      _searchCache[normalizedQuery] = localResults;
      _searchCacheTimes[normalizedQuery] = DateTime.now();
      _searchCacheSource[normalizedQuery] = 'local';
    }
    return localResults;
  }

  static Future<List<IndianFoodModel>> searchFoods(String query) async {
    lastOffError = null;
    final normalizedQuery = query.trim().toLowerCase();
    final cached = _searchCache[normalizedQuery];
    final cachedAt = _searchCacheTimes[normalizedQuery];
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    final allFoods = await _loadLocalFoods();

    if (normalizedQuery.isEmpty) {
      return allFoods;
    }

    print('DEBUG: Searching for: $normalizedQuery');
    print('DEBUG: Total foods in local DB: ${allFoods.length}');

    final localResults = _searchLocalInList(allFoods, normalizedQuery);
    print('DEBUG: Found ${localResults.length} local results');

    if (localResults.isNotEmpty) {
      await _cacheFoods(localResults);
      _searchCache[normalizedQuery] = localResults;
      _searchCacheTimes[normalizedQuery] = DateTime.now();
      _searchCacheSource[normalizedQuery] = 'local';
      return localResults;
    }

    if (normalizedQuery.length >= _minOffQueryLength) {
      final indiaResults = await _searchOpenFoodFacts(
        normalizedQuery,
        country: OpenFoodFactsCountry.INDIA,
      );
      if (indiaResults.isNotEmpty) {
        _searchCache[normalizedQuery] = indiaResults;
        _searchCacheTimes[normalizedQuery] = DateTime.now();
        _searchCacheSource[normalizedQuery] = 'off';
        return indiaResults;
      }
      final globalResults = await _searchOpenFoodFacts(
        normalizedQuery,
        country: null,
        ignoreGlobalCountry: true,
      );
      if (globalResults.isNotEmpty) {
        _searchCache[normalizedQuery] = globalResults;
        _searchCacheTimes[normalizedQuery] = DateTime.now();
        _searchCacheSource[normalizedQuery] = 'off';
        return globalResults;
      }
    }

    return <IndianFoodModel>[];
  }

  static Future<List<IndianFoodModel>> _loadLocalFoods() async {
    if (_localDbCache != null) return _localDbCache!;
    final jsonString = await rootBundle.loadString(_assetsPath);
    final jsonData = json.decode(jsonString);
    final foodsJson = jsonData['Nutrient Data'] as List;
    _localDbCache = foodsJson
        .map((food) => FoodAdapter.databaseJsonToIndianFoodModel(food))
        .where((food) => food != null)
        .cast<IndianFoodModel>()
        .toList();
    return _localDbCache!;
  }

  static List<IndianFoodModel> _searchLocalInList(
    List<IndianFoodModel> allFoods,
    String lowerQuery,
  ) {
    final localResults = allFoods.where((food) {
      final nameMatch = food.name.toLowerCase().contains(lowerQuery);
      final hindiMatch = food.hindiName.toLowerCase().contains(lowerQuery);
      final keywordMatch = food.keywords.any(
        (k) => k.toLowerCase().contains(lowerQuery),
      );
      final categoryMatch = food.category.toLowerCase().contains(lowerQuery);
      final regionMatch = food.region.toLowerCase().contains(lowerQuery);

      return nameMatch ||
          hindiMatch ||
          keywordMatch ||
          categoryMatch ||
          regionMatch;
    }).toList();

    if (localResults.isNotEmpty) {
      localResults.sort((a, b) {
        final aScore = _calculateRelevanceScore(a, lowerQuery);
        final bScore = _calculateRelevanceScore(b, lowerQuery);
        return bScore.compareTo(aScore);
      });
    }

    return localResults;
  }

  static void _ensureOpenFoodFactsConfig() {
    if (_offConfigured) return;
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'Sumi',
      url: 'https://github.com/',
    );
    OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.INDIA;
    OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
      OpenFoodFactsLanguage.ENGLISH,
    ];
    _offConfigured = true;
  }

  static Future<List<IndianFoodModel>> _searchOpenFoodFacts(
    String query, {
    OpenFoodFactsCountry? country,
    bool ignoreGlobalCountry = false,
  }) async {
    OpenFoodFactsCountry? previousCountry;
    Object? lastError;
    try {
      _ensureOpenFoodFactsConfig();
      previousCountry = OpenFoodAPIConfiguration.globalCountry;
      if (ignoreGlobalCountry) {
        OpenFoodAPIConfiguration.globalCountry = null;
      }

      for (var attempt = 1; attempt <= 2; attempt++) {
        try {
          final ProductSearchQueryConfiguration configuration =
              ProductSearchQueryConfiguration(
            parametersList: <Parameter>[
              SearchTerms(terms: <String>[query]),
              PageSize(size: 10),
              PageNumber(page: 1),
            ],
            country: country,
            fields: <ProductField>[
              ProductField.BARCODE,
              ProductField.NAME,
              ProductField.GENERIC_NAME,
              ProductField.BRANDS,
              ProductField.CATEGORIES,
              ProductField.COUNTRIES,
              ProductField.SERVING_SIZE,
              ProductField.QUANTITY,
              ProductField.IMAGE_FRONT_URL,
              ProductField.NUTRIMENTS,
              ProductField.INGREDIENTS_ANALYSIS_TAGS,
              ProductField.NOVA_GROUP,
              ProductField.LAST_MODIFIED,
            ],
            version: ProductQueryVersion.v3,
          );

          final SearchResult result = await OpenFoodAPIClient.searchProducts(
            null,
            configuration,
          ).timeout(_offTimeout);

          final products = result.products ?? <Product>[];
          if (products.isEmpty) {
            return <IndianFoodModel>[];
          }

          final mapped = products
              .where((product) => product.getBestProductName(
                        OpenFoodFactsLanguage.ENGLISH,
                      ).isNotEmpty)
              .map((product) => _mapOpenFoodProduct(product, query))
              .toList();
          await _upsertFoods(mapped);
          return mapped;
        } on TimeoutException catch (e) {
          lastError = e;
          if (attempt < 2) {
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
        } catch (e) {
          lastError = e;
          break;
        }
      }
      if (lastError != null) {
        lastOffError =
            lastError is TimeoutException
                ? 'Open Food Facts timed out. Check your connection and try again.'
                : 'Open Food Facts is unavailable right now.';
        print('OpenFoodFacts search error: $lastError');
      }
      return <IndianFoodModel>[];
    } finally {
      if (ignoreGlobalCountry) {
        OpenFoodAPIConfiguration.globalCountry = previousCountry;
      }
    }
  }

  static Future<void> _upsertFoods(List<IndianFoodModel> foods) async {
    await _cacheFoods(foods);
  }

  static Future<void> _cacheFoods(List<IndianFoodModel> foods) async {
    if (foods.isEmpty) return;
    await ensureBoxOpen();
    final box = Hive.box<IndianFoodModel>(_boxName);
    final prefs = await SharedPreferences.getInstance();
    final List<String> ids =
        List<String>.from(prefs.getStringList(_cacheKeysKey) ?? <String>[]);

    for (final food in foods) {
      ids.remove(food.id);
      ids.insert(0, food.id);
      final existingKey = box.keys.firstWhere(
        (key) => box.get(key)?.id == food.id,
        orElse: () => null,
      );
      if (existingKey != null) {
        await box.put(existingKey, food);
      } else {
        await box.add(food);
      }
    }

    if (ids.length > _maxCacheItems) {
      ids.removeRange(_maxCacheItems, ids.length);
    }
    await prefs.setStringList(_cacheKeysKey, ids);
    await _trimCache(box, ids: ids);
  }

  static Future<void> _trimCache(
    Box<IndianFoodModel> box, {
    List<String>? ids,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final keepIds =
        ids ?? List<String>.from(prefs.getStringList(_cacheKeysKey) ?? <String>[]);
    final keepSet = keepIds.toSet();
    final keysToDelete = <dynamic>[];
    for (final key in box.keys) {
      final food = box.get(key);
      if (food == null || !keepSet.contains(food.id)) {
        keysToDelete.add(key);
      }
    }
    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }
  }

  static IndianFoodModel? getFoodByIdSync(String id) {
    if (!Hive.isBoxOpen(_boxName)) return null;
    final box = Hive.box<IndianFoodModel>(_boxName);
    final direct = box.get(id);
    if (direct != null) return direct;
    try {
      return box.values.firstWhere((food) => food.id == id);
    } catch (_) {
      return null;
    }
  }

  static IndianFoodModel _mapOpenFoodProduct(
    Product product,
    String query,
  ) {
    final nutriments = product.nutriments;
    final kcal = nutriments?.getValue(
          Nutrient.energyKCal,
          PerSize.oneHundredGrams,
        ) ??
        nutriments?.getValue(
          Nutrient.energyKCal,
          PerSize.serving,
        ) ??
        0.0;
    final carbs = nutriments?.getValue(
          Nutrient.carbohydrates,
          PerSize.oneHundredGrams,
        ) ??
        nutriments?.getValue(
          Nutrient.carbohydrates,
          PerSize.serving,
        ) ??
        0.0;
    final protein = nutriments?.getValue(
          Nutrient.proteins,
          PerSize.oneHundredGrams,
        ) ??
        nutriments?.getValue(
          Nutrient.proteins,
          PerSize.serving,
        ) ??
        0.0;
    final fats = nutriments?.getValue(
          Nutrient.fat,
          PerSize.oneHundredGrams,
        ) ??
        nutriments?.getValue(
          Nutrient.fat,
          PerSize.serving,
        ) ??
        0.0;
    final fiber = nutriments?.getValue(
          Nutrient.fiber,
          PerSize.oneHundredGrams,
        ) ??
        nutriments?.getValue(
          Nutrient.fiber,
          PerSize.serving,
        ) ??
        0.0;
    final sugar = nutriments?.getValue(
          Nutrient.sugars,
          PerSize.oneHundredGrams,
        ) ??
        nutriments?.getValue(
          Nutrient.sugars,
          PerSize.serving,
        );

    final isVeg =
        product.ingredientsAnalysisTags?.vegetarianStatus ==
            VegetarianStatus.VEGETARIAN ||
        product.ingredientsAnalysisTags?.veganStatus == VeganStatus.VEGAN;
    final novaGroup = product.novaGroup;
    final isProcessed = novaGroup != null ? novaGroup >= 3 : null;

    final name =
        product.getBestProductName(OpenFoodFactsLanguage.ENGLISH).trim();
    final servingText =
        (product.servingSize?.trim().isNotEmpty == true
                ? product.servingSize!.trim()
                : null) ??
            (product.quantity?.trim().isNotEmpty == true
                ? product.quantity!.trim()
                : '100 g');
    final unitType = IndianFoodModel.inferUnitType(servingText);
    final unitWeightGrams =
        IndianFoodModel.inferUnitWeightGrams(servingText, unitType: unitType);

    return IndianFoodModel(
      id: product.barcode?.trim().isNotEmpty == true
          ? 'off_${product.barcode}'
          : 'off_${name.toLowerCase().replaceAll(' ', '_')}',
      name: name,
      hindiName: '',
      category: product.categories?.split(',').first.trim().isNotEmpty == true
          ? product.categories!.split(',').first.trim()
          : 'Open Food Facts',
      region: product.countries?.split(',').first.trim().isNotEmpty == true
          ? product.countries!.split(',').first.trim()
          : 'Global',
      calories: kcal,
      protein: protein,
      carbs: carbs,
      fats: fats,
      fiber: fiber,
      servingSize: servingText,
      keywords: <String>{
        query.toLowerCase(),
        if (product.brands != null) product.brands!.toLowerCase(),
        if (product.categories != null) product.categories!.toLowerCase(),
      }.toList(),
      isVeg: isVeg,
      imageUrl: product.imageFrontUrl ?? '',
      dataSource: 'Open Food Facts',
      lastUpdated:
          product.lastModified?.toIso8601String() ?? DateTime.now().toIso8601String(),
      sugar: sugar,
      novaGroup: novaGroup,
      isProcessed: isProcessed,
      unitType: unitType,
      unitWeightGrams: unitWeightGrams,
    );
  }

  static int _calculateRelevanceScore(IndianFoodModel food, String query) {
    int score = 0;

    if (food.name.toLowerCase().contains(query)) score += 10;
    if (food.name.toLowerCase().startsWith(query)) score += 15;
    if (food.hindiName.toLowerCase().contains(query)) score += 8;
    if (food.keywords.any((k) => k.toLowerCase().contains(query))) score += 5;
    if (food.category.toLowerCase().contains(query)) score += 3;
    if (food.region.toLowerCase().contains(query)) score += 2;

    return score;
  }

  static Future<IndianFoodModel?> getFoodById(String id) async {
    final box = Hive.box<IndianFoodModel>(_boxName);
    final direct = box.get(id);
    if (direct != null) return direct;
    try {
      return box.values.firstWhere((food) => food.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<IndianFoodModel?> getLocalFoodById(String id) async {
    final foods = await _loadLocalFoods();
    try {
      return foods.firstWhere((food) => food.id == id);
    } catch (_) {
      return null;
    }
  }
}
