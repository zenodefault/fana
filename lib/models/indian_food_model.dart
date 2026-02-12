// lib/models/indian_food_model.dart
import 'package:hive/hive.dart';

part 'indian_food_model.g.dart';

@HiveType(typeId: 2)
class IndianFoodModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String hindiName;
  @HiveField(3)
  final String category;
  @HiveField(4)
  final String region;
  @HiveField(5)
  final double calories;
  @HiveField(6)
  final double protein;
  @HiveField(7)
  final double carbs;
  @HiveField(8)
  final double fats;
  @HiveField(9)
  final double fiber;
  @HiveField(10)
  final String servingSize;
  @HiveField(11)
  final List<String> keywords;
  @HiveField(12)
  final bool isVeg;
  @HiveField(13)
  final String imageUrl;
  @HiveField(14)
  final String dataSource;
  @HiveField(15)
  final String lastUpdated;
  @HiveField(16)
  final double? sugar;
  @HiveField(17)
  final int? novaGroup;
  @HiveField(18)
  final bool? isProcessed;
  @HiveField(19, defaultValue: 'gram')
  final String unitType;
  @HiveField(20, defaultValue: 100.0)
  final double unitWeightGrams;

  IndianFoodModel({
    required this.id,
    required this.name,
    required this.hindiName,
    required this.category,
    required this.region,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.fiber,
    required this.servingSize,
    required this.keywords,
    required this.isVeg,
    required this.imageUrl,
    required this.dataSource,
    required this.lastUpdated,
    this.sugar,
    this.novaGroup,
    this.isProcessed,
    required this.unitType,
    required this.unitWeightGrams,
  });

  factory IndianFoodModel.fromJson(Map<String, dynamic> json) {
    final servingSize = json['servingSize']?.toString() ?? '';
    final inferredUnitType = inferUnitType(servingSize);
    final explicitUnitWeight = _normalizeUnitWeight(json['unitWeightGrams']);
    return IndianFoodModel(
      id: json['id'],
      name: json['name'],
      hindiName: json['hindiName'] ?? '',
      category: json['category'],
      region: json['region'],
      calories: json['calories'].toDouble(),
      protein: json['protein'].toDouble(),
      carbs: json['carbs'].toDouble(),
      fats: json['fats'].toDouble(),
      fiber: json['fiber'].toDouble(),
      servingSize: servingSize,
      keywords: List<String>.from(json['keywords'] ?? []),
      isVeg: json['isVeg'] ?? true,
      imageUrl: json['imageUrl'],
      dataSource: json['dataSource'],
      lastUpdated: json['lastUpdated'] ?? '2017-12-31',
      sugar: json['sugar']?.toDouble(),
      novaGroup: json['novaGroup'],
      isProcessed: json['isProcessed'],
      unitType: json['unitType']?.toString() ?? inferredUnitType,
      unitWeightGrams:
          explicitUnitWeight ?? inferUnitWeightGrams(servingSize, unitType: inferredUnitType),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hindiName': hindiName,
      'category': category,
      'region': region,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'fiber': fiber,
      'servingSize': servingSize,
      'keywords': keywords,
      'isVeg': isVeg,
      'imageUrl': imageUrl,
      'dataSource': dataSource,
      'lastUpdated': lastUpdated,
      'sugar': sugar,
      'novaGroup': novaGroup,
      'isProcessed': isProcessed,
      'unitType': unitType,
      'unitWeightGrams': unitWeightGrams,
    };
  }

  // Calculate nutrients for actual serving size
  Map<String, double> getNutrientsForServing(double servingMultiplier) {
    return {
      'calories': calories * servingMultiplier,
      'protein': protein * servingMultiplier,
      'carbs': carbs * servingMultiplier,
      'fats': fats * servingMultiplier,
      'fiber': fiber * servingMultiplier,
      if (sugar != null) 'sugar': sugar! * servingMultiplier,
    };
  }

  // Get serving size in grams
  double get servingWeightInGrams {
    if (unitWeightGrams > 0) return unitWeightGrams;
    return inferUnitWeightGrams(servingSize, unitType: unitType);
  }

  double gramsForAmount(double amount, {String? unitType}) {
    final unit = (unitType ?? this.unitType).toLowerCase();
    if (unit == 'gram' || unit == 'g') {
      return amount;
    }
    return amount * servingWeightInGrams;
  }

  static String inferUnitType(String servingSize) {
    final size = servingSize.toLowerCase();
    if (size.contains('piece') ||
        size.contains('pcs') ||
        size.contains('pc') ||
        size.contains('bar') ||
        size.contains('slice')) {
      return 'piece';
    }
    if (size.contains('cup')) return 'cup';
    if (size.contains('glass')) return 'glass';
    if (size.contains('bowl')) return 'bowl';
    if (size.contains('plate')) return 'plate';
    if (size.contains('serving')) return 'serving';
    if (size.contains('ml')) return 'gram';
    if (RegExp(r'\\d+\\.?\\d*\\s*(g|gm|gms|gram|grams)\\b').hasMatch(size)) {
      return 'gram';
    }
    return 'serving';
  }

  static double inferUnitWeightGrams(String servingSize, {String? unitType}) {
    final size = servingSize.toLowerCase();
    final match = RegExp(
      r'(\\d+\\.?\\d*)\\s*(g|gm|gms|gram|grams|ml)\\b',
      caseSensitive: false,
    ).firstMatch(size);
    if (match != null) {
      return double.parse(match.group(1)!);
    }
    return defaultUnitWeightForType(unitType ?? inferUnitType(servingSize));
  }

  static double defaultUnitWeightForType(String unitType) {
    switch (unitType.toLowerCase()) {
      case 'cup':
        return 240.0;
      case 'glass':
        return 200.0;
      case 'bowl':
        return 200.0;
      case 'plate':
        return 250.0;
      case 'piece':
        return 30.0;
      case 'gram':
        return 100.0;
      default:
        return 100.0;
    }
  }

  static double? _normalizeUnitWeight(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
