import '../../models/indian_food_model.dart';

class FoodAdapter {

  /// Converts a food entry from database.json to an IndianFoodModel object
  static IndianFoodModel? databaseJsonToIndianFoodModel(dynamic foodData) {
    try {
      // print('DEBUG: Processing food data: $foodData');
      // Extract required fields from database.json format
      final foodCode = foodData['food_code'];
      final foodName = foodData['food_name'];
      final energyKcal = foodData['energy_kcal']?.toDouble() ?? 0.0;
      final protein = foodData['protein_g']?.toDouble() ?? 0.0;
      final carbs = foodData['carb_g']?.toDouble() ?? 0.0;
      final fats = foodData['fat_g']?.toDouble() ?? 0.0;
      final fiber = foodData['fibre_g']?.toDouble() ?? 0.0;
      final servingUnit = foodData['servings_unit'] ?? '100 g';
      final unitType = _inferUnitType(servingUnit.toString());
      final unitWeightGrams = _inferUnitWeightGrams(
        servingUnit.toString(),
        foodData: foodData,
        unitType: unitType,
        energyKcal: energyKcal,
      );

      if (foodCode == null || foodName == null) {
        return null;
      }

      // Create keywords from food name and other relevant fields
      final keywords = <String>{
        foodName.toLowerCase(),
        ...foodName.toLowerCase().split(' '),
      }.toList();

      // Attempt to categorize the food based on its name
      String category = 'General Food';
      final lowerName = foodName.toLowerCase();
      if (lowerName.contains('rice') ||
          lowerName.contains('chawal') ||
          lowerName.contains('biryani')) {
        category = 'Cereals & Grains';
      } else if (lowerName.contains('dal') ||
          lowerName.contains('lentil') ||
          lowerName.contains('pulse')) {
        category = 'Lentils & Legumes';
      } else if (lowerName.contains('vegetable') ||
          lowerName.contains('sabji') ||
          lowerName.contains('curry')) {
        category = 'Vegetables & Curries';
      } else if (lowerName.contains('fruit') ||
          lowerName.contains('mango') ||
          lowerName.contains('apple')) {
        category = 'Fruits';
      } else if (lowerName.contains('milk') ||
          lowerName.contains('yogurt') ||
          lowerName.contains('curd')) {
        category = 'Dairy Products';
      } else if (lowerName.contains('chicken') ||
          lowerName.contains('mutton') ||
          lowerName.contains('fish')) {
        category = 'Non-Vegetarian';
      } else if (lowerName.contains('roti') ||
          lowerName.contains('chapati') ||
          lowerName.contains('bread')) {
        category = 'Breads';
      } else if (lowerName.contains('sweet') ||
          lowerName.contains('halwa') ||
          lowerName.contains('ladoo')) {
        category = 'Sweets & Desserts';
      } else if (lowerName.contains('tea') ||
          lowerName.contains('coffee') ||
          lowerName.contains('drink')) {
        category = 'Beverages';
      }

      // Determine if food is vegetarian based on name
      bool isVeg = true;
      if (lowerName.contains('chicken') ||
          lowerName.contains('mutton') ||
          lowerName.contains('beef') ||
          lowerName.contains('pork') ||
          lowerName.contains('fish') ||
          lowerName.contains('egg') ||
          lowerName.contains('non-veg')) {
        isVeg = false;
      }

      return IndianFoodModel(
        id: 'db_$foodCode', // Prefix to distinguish from other sources
        name: foodName,
        hindiName: '', // Database doesn't have Hindi names, leave empty
        category: category,
        region: 'International', // Default region for comprehensive database
        calories: energyKcal,
        protein: protein,
        carbs: carbs,
        fats: fats,
        fiber: fiber,
        servingSize: servingUnit.toString(),
        keywords: keywords,
        isVeg: isVeg,
        imageUrl: '', // Database doesn't provide image URLs
        dataSource: 'Nutrient Database',
        lastUpdated: DateTime.now().toIso8601String().split('T')[0],
        sugar: null,
        novaGroup: null,
        isProcessed: null,
        unitType: unitType,
        unitWeightGrams: unitWeightGrams,
      );
    } catch (e) {
      print('Error converting database.json food to IndianFoodModel: $e');
      return null;
    }
  }

  static String _inferUnitType(String servingSize) {
    return IndianFoodModel.inferUnitType(servingSize);
  }

  static double _inferUnitWeightGrams(
    String servingSize, {
    required dynamic foodData,
    required String unitType,
    required double energyKcal,
  }) {
    final explicitWeight = foodData['unit_weight_g'];
    if (explicitWeight != null) {
      final parsed = double.tryParse(explicitWeight.toString());
      if (parsed != null && parsed > 0) return parsed;
    }

    final unitServingKcal = foodData['unit_serving_energy_kcal'];
    if (unitServingKcal != null &&
        energyKcal > 0 &&
        unitServingKcal is num &&
        unitServingKcal > 0) {
      final grams = (unitServingKcal / energyKcal) * 100.0;
      if (grams.isFinite && grams > 0) return grams;
    }

    final parsedFromText =
        IndianFoodModel.inferUnitWeightGrams(servingSize, unitType: unitType);
    if (parsedFromText > 0) return parsedFromText;

    return IndianFoodModel.defaultUnitWeightForType(unitType);
  }
}
