import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/services/food_database_service.dart';
import '../../../models/indian_food_model.dart';
import 'dart:async';
import '../../../core/app_icons.dart';

import 'food_item_card.dart';

class FoodSearchBottomSheet extends StatefulWidget {
  final Function(IndianFoodModel food, double grams, String meal) onFoodAdded;

  const FoodSearchBottomSheet({super.key, required this.onFoodAdded});

  @override
  State<FoodSearchBottomSheet> createState() => _FoodSearchBottomSheetState();
}

class _FoodSearchBottomSheetState extends State<FoodSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<IndianFoodModel> _searchResults = [];
  Timer? _debounce;
  int _searchToken = 0;
  bool _isLoading = false;
  bool _isOffLoading = false;
  String? _offError;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _offError = null;
        _isLoading = false;
        _isOffLoading = false;
      });
      return;
    }

    final token = ++_searchToken;
    setState(() {
      _isLoading = true;
      _isOffLoading = false;
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
    setState(() {
      _searchResults = results;
      _offError = FoodDatabaseService.lastOffError;
      _isLoading = false;
      _isOffLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Input Field
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search for a food item...',
              prefixIcon: AppIcon(AppIcons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isLight ? LightColors.muted : DarkColors.muted,
            ),
          ),
          if (_isLoading || _isOffLoading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    minHeight: 2,
                    color: isLight ? LightColors.primary : DarkColors.primary,
                    backgroundColor:
                        (isLight ? LightColors.primary : DarkColors.primary)
                            .withOpacity(0.2),
                  ),
                  if (_isOffLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Searching Open Food Facts...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isLight
                              ? LightColors.mutedForeground
                              : DarkColors.mutedForeground,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Search results list
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Start typing to search'
                          : (_offError != null
                              ? _offError!
                              : 'No results found'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isLight ? LightColors.mutedForeground : DarkColors.mutedForeground,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final food = _searchResults[index];
                      return FoodItemCard(
                        food: food,
                        onAdd: (food, grams, meal) {
                          widget.onFoodAdded(food, grams, meal);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
