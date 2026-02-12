// lib/features/calories/screens/food_search_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_icons.dart';
import '../../../core/services/food_database_service.dart';
import '../../../models/indian_food_model.dart';
import '../../../core/providers.dart';
import '../../../core/models.dart';
import '../../../core/glass_widgets.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<IndianFoodModel> _searchResults = [];
  bool _isLoading = false;
  bool _isOffLoading = false;
  String? _searchQuery;
  String? _offError;
  Timer? _debounce;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadRecentFoods();
  }

  Future<void> _loadRecentFoods() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load popular Indian foods as default
      final results = await FoodDatabaseService.searchFoods('dal');
      if (mounted) {
        setState(() {
          _searchResults = results;
          _offError = FoodDatabaseService.lastOffError;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      _loadRecentFoods();
      return;
    }

    if (!mounted) return;

    final token = ++_searchToken;
    setState(() {
      _isLoading = true;
      _isOffLoading = false;
      _searchQuery = query.trim();
      _offError = null;
    });

    final localResults =
        await FoodDatabaseService.searchLocalFoods(query.trim());

    if (!mounted || token != _searchToken) {
      return;
    }

    if (localResults.isNotEmpty) {
      setState(() {
        _searchResults = localResults;
        _offError = null;
        _isLoading = false;
        _isOffLoading = false;
      });
      return;
    }

    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _offError = null;
        _isLoading = false;
        _isOffLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _isOffLoading = true;
    });

    final results = await FoodDatabaseService.searchFoods(query.trim());

    if (!mounted || token != _searchToken) {
      return;
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _offError = FoodDatabaseService.lastOffError;
        _isLoading = false;
        _isOffLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indian Food Search'),
        backgroundColor: Colors.purple,
        leading: IconButton(
          icon: AppIcon(AppIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Indian foods (dal, roti, biryani...)',
                prefixIcon: AppIcon(AppIcons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: AppIcon(AppIcons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadRecentFoods();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (_isLoading || _isOffLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    minHeight: 2,
                    color: Colors.purple,
                    backgroundColor: Colors.purple.withValues(alpha: 0.2),
                  ),
                  if (_isOffLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Searching Open Food Facts...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(child: _buildFoodList()),
        ],
      ),
    );
  }

  Widget _buildFoodList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(AppIcons.search, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery != null
                  ? (_offError ?? 'No foods found for "$_searchQuery"')
                  : 'Search Indian foods',
              style: const TextStyle(color: Colors.grey, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try: "dal", "roti", "rice", "samosa", "biryani"',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        return _buildFoodCard(food);
      },
    );
  }

  Widget _buildFoodCard(IndianFoodModel food) {
    // Calculate per-serving nutrients
    final servingWeight = food.servingWeightInGrams;
    final multiplier = servingWeight / 100.0;
    final nutrients = food.getNutrientsForServing(multiplier);

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFoodImage(food),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFoodTitle(food),
                      const SizedBox(height: 6),
                      _buildFoodSubtitle(food, nutrients),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildLogButton(food, nutrients),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodImage(IndianFoodModel food) {
    final imageUrl = food.imageUrl;
    final isRemote = imageUrl.startsWith('http');
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.purple.withValues(alpha: 0.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl.isEmpty
            ? AppIcon(AppIcons.food, size: 30, color: Colors.purple)
            : (isRemote
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        AppIcon(AppIcons.food, size: 30, color: Colors.purple),
                  )
                : Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        AppIcon(AppIcons.food, size: 30, color: Colors.purple),
                  )),
      ),
    );
  }

  Widget _buildFoodTitle(IndianFoodModel food) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          food.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (food.hindiName.isNotEmpty)
          Text(
            food.hindiName,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildFoodSubtitle(
    IndianFoodModel food,
    Map<String, double> nutrients,
  ) {
    final sugar = nutrients['sugar'];
    final hasProcessed = food.isProcessed != null;
    final processedLabel =
        food.isProcessed == null ? '' : (food.isProcessed! ? 'Processed' : 'Not processed');
    final novaLabel =
        food.novaGroup != null ? 'NOVA ${food.novaGroup}' : '';
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Serving: ${food.servingSize}',
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _nutrientChip(
              'kcal',
              '${nutrients['calories']?.toStringAsFixed(0)}',
              Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (hasProcessed)
          _nutrientChip(
            processedLabel,
            novaLabel,
            food.isProcessed! ? Colors.orange : Colors.grey,
            muted: !food.isProcessed!,
          ),
        if (hasProcessed) const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _nutrientChip(
              'P',
              '${nutrients['protein']?.toStringAsFixed(1)}g',
              isLight ? Colors.green : Colors.greenAccent,
            ),
            _nutrientChip(
              'C',
              '${nutrients['carbs']?.toStringAsFixed(1)}g',
              isLight ? Colors.blue : Colors.lightBlueAccent,
            ),
            _nutrientChip(
              'F',
              '${nutrients['fats']?.toStringAsFixed(1)}g',
              isLight ? Colors.red : Colors.redAccent,
            ),
            if (sugar != null)
              _nutrientChip(
                'Sugar',
                '${sugar.toStringAsFixed(1)}g',
                Colors.orange,
              ),
          ],
        ),
      ],
    );
  }

  Widget _nutrientChip(
    String label,
    String value,
    Color color, {
    bool muted = false,
  }) {
    final bgColor = muted
        ? color.withValues(alpha: 0.12)
        : color.withValues(alpha: 0.18);
    final textColor = muted ? color.withValues(alpha: 0.7) : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value.isEmpty ? label : '$label $value',
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLogButton(IndianFoodModel food, Map<String, double> nutrients) {
    return SizedBox(
      width: 80,
      child: ElevatedButton(
        onPressed: () => _logFood(food, nutrients),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
        child: const Text(
          'Log',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  void _logFood(IndianFoodModel food, Map<String, double> nutrients) {
    final unitOptions = _unitOptions(food);
    // Show dialog to let user enter custom weight
    showDialog(
      context: context,
      builder: (context) {
        final weightController = TextEditingController();
        String selectedUnit =
            food.unitType.toLowerCase() == 'gram' ? 'gram' : food.unitType;
        double amount = selectedUnit == 'gram' ? food.servingWeightInGrams : 1;
        weightController.text = amount.toString();

        return StatefulBuilder(
          builder: (context, setState) {
            final usesGrams = selectedUnit == 'gram';
            final unitLabel = _unitLabelForType(selectedUnit);
            final parsedAmount = double.tryParse(weightController.text);
            final effectiveAmount = parsedAmount ?? amount;
            final grams = food.gramsForAmount(
              effectiveAmount,
              unitType: selectedUnit,
            );
            final nutrients = food.getNutrientsForServing(grams / 100.0);

            return AlertDialog(
              title: Text('Log Food: ${food.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(usesGrams
                      ? 'Enter amount in grams:'
                      : 'Enter number of $unitLabel:'),
                  Row(
                    children: [
                      if (unitOptions.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: DropdownButton<String>(
                            value: selectedUnit,
                            items: unitOptions
                                .map(
                                  (unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(_unitLabelForType(unit)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                selectedUnit = value;
                                amount = selectedUnit == 'gram'
                                    ? food.servingWeightInGrams
                                    : 1;
                                weightController.text = amount.toString();
                              });
                            },
                          ),
                        ),
                      Expanded(
                        child: TextField(
                          controller: weightController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              amount = double.tryParse(value) ?? amount;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: usesGrams
                                ? 'Amount in grams'
                                : 'Number of $unitLabel',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!usesGrams)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('~ ${grams.toStringAsFixed(0)} g'),
                    ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usesGrams
                            ? 'Nutrients for ${effectiveAmount.toStringAsFixed(0)}g:'
                            : 'Nutrients for ${effectiveAmount.toStringAsFixed(1)} $unitLabel:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Calories: ${nutrients['calories']?.toStringAsFixed(1)} kcal',
                      ),
                      Text(
                        'Protein: ${nutrients['protein']?.toStringAsFixed(1)}g',
                      ),
                      Text(
                        'Carbs: ${nutrients['carbs']?.toStringAsFixed(1)}g',
                      ),
                      Text(
                        'Fats: ${nutrients['fats']?.toStringAsFixed(1)}g',
                      ),
                      Text(
                        'Fiber: ${nutrients['fiber']?.toStringAsFixed(1)}g',
                      ),
                      if (nutrients['sugar'] != null)
                        Text(
                          'Sugar: ${nutrients['sugar']?.toStringAsFixed(1)}g',
                        ),
                      if (food.isProcessed != null)
                        Text(
                          "Processed: ${food.isProcessed! ? 'Yes' : 'No'}"
                          "${food.novaGroup != null ? ' (NOVA ${food.novaGroup})' : ''}",
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final value = double.tryParse(weightController.text);
                    if (value != null && value > 0) {
                      await _logFoodWithCustomAmount(
                        food,
                        value,
                        unitType: selectedUnit,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a valid amount')),
                      );
                    }
                  },
                  child: Text('Log Food'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Log food with custom amount (grams or servings)
  Future<void> _logFoodWithCustomAmount(
    IndianFoodModel food,
    double amount,
    {required String unitType}
  ) async {
    final provider = context.read<FitnessProvider>();

    // Calculate nutrients for the custom weight
    final grams = food.gramsForAmount(amount, unitType: unitType);
    final multiplier = grams / 100.0;
    final nutrients = food.getNutrientsForServing(multiplier);

    final foodLog = FoodLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      foodItemId: food.id,
      foodName: food.name,
      calories: nutrients['calories']!.toInt(),
      quantity: grams.toInt(), // Store the actual weight
      unit: 'g',
      logDate: DateTime.now(),
      mealType: 'General', // Will allow user to select meal type later
    );

    try {
      // Use the provider to add food log and update daily calories
      await provider.addFoodLog(foodLog);
      await provider.updateDailyLogWithCalories(); // Update daily calorie count

      if (mounted) {
        Navigator.pop(context); // Return to calories screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              unitType == 'gram'
                  ? '${food.name} (${grams.toStringAsFixed(0)}g) added to your food log!'
                  : '${food.name} ($amount ${_unitLabelForType(unitType)}) added to your food log!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding food to log: $e')));
      }
    }
  }

  List<String> _unitOptions(IndianFoodModel food) {
    final unit = food.unitType.toLowerCase();
    if (unit == 'gram') return <String>['gram'];
    return <String>['gram', unit];
  }

  String _unitLabelForType(String unitType) {
    switch (unitType.toLowerCase()) {
      case 'gram':
        return 'g';
      case 'bowl':
        return 'bowl(s)';
      case 'cup':
        return 'cup(s)';
      case 'glass':
        return 'glass(es)';
      case 'plate':
        return 'plate(s)';
      case 'piece':
        return 'piece(s)';
      case 'serving':
        return 'serving(s)';
      default:
        return '${unitType.toLowerCase()}(s)';
    }
  }

  Widget _buildAttributionFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(AppIcons.info, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nutritional data sources:',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• Local: Indian Food Composition Tables 2017 (NIN-ICMR)',
              style: TextStyle(color: Colors.blue, fontSize: 11),
            ),
            Text(
              '• Global: Open Food Facts database',
              style: TextStyle(color: Colors.blue, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              'Note: Data from Open Food Facts may vary from actual values.',
              style: TextStyle(color: Colors.orange, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
