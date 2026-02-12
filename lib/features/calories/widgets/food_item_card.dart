import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../models/indian_food_model.dart';
import '../../../core/glass_widgets.dart';

class FoodItemCard extends StatefulWidget {
  final IndianFoodModel food;
  final Function(IndianFoodModel food, double grams, String meal) onAdd;

  const FoodItemCard({super.key, required this.food, required this.onAdd});

  @override
  State<FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> {
  bool _isExpanded = false;
  final TextEditingController _gramsController = TextEditingController();
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedUnit = _defaultUnitFor(widget.food);
  }

  @override
  void didUpdateWidget(covariant FoodItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.food.id != widget.food.id) {
      _selectedUnit = _defaultUnitFor(widget.food);
      _gramsController.clear();
    }
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return GlassCard(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Collapsed View
              _buildCollapsedView(theme, isLight),
              
              // Expanded View (conditionally shown)
              if (_isExpanded) _buildExpandedView(theme, isLight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedView(ThemeData theme, bool isLight) {
    final servingWeight = widget.food.servingWeightInGrams;
    final multiplier = servingWeight / 100.0;
    final nutrients = widget.food.getNutrientsForServing(multiplier);
    final sugar = nutrients['sugar'];
    final hasSugar = sugar != null;
    final hasProcessed = widget.food.isProcessed != null;
    final processedLabel = widget.food.isProcessed == null
        ? ''
        : (widget.food.isProcessed! ? 'Processed' : 'Not processed');
    final novaLabel =
        widget.food.novaGroup != null ? 'NOVA ${widget.food.novaGroup}' : '';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.food.name,
                      style: theme.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _nutrientChip(
                    'kcal',
                    nutrients['calories']?.toStringAsFixed(0) ?? '0',
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Serving: ${widget.food.servingSize}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isLight
                      ? LightColors.mutedForeground
                      : DarkColors.mutedForeground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasProcessed) const SizedBox(height: 6),
              if (hasProcessed)
                _nutrientChip(
                  processedLabel,
                  novaLabel,
                  widget.food.isProcessed! ? Colors.orange : Colors.grey,
                  muted: !widget.food.isProcessed!,
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
                  if (hasSugar)
                    _nutrientChip(
                      'Sugar',
                      '${sugar!.toStringAsFixed(1)}g',
                      Colors.orange,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedView(ThemeData theme, bool isLight) {
    final unitOptions = _unitOptions(widget.food);
    final usesGrams = _selectedUnit == 'gram';
    final unitLabel = _unitLabelForType(_selectedUnit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        // Detailed nutrients
        _buildNutrientRow(theme, 'Fibre', widget.food.fiber, 'g'),
        if (widget.food.sugar != null)
          _buildNutrientRow(
            theme,
            'Sugar',
            widget.food.sugar!,
            'g',
          ),
        if (widget.food.isProcessed != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Processed', style: theme.textTheme.bodyMedium),
                Text(
                  '${widget.food.isProcessed! ? 'Yes' : 'No'}'
                  '${widget.food.novaGroup != null ? ' (NOVA ${widget.food.novaGroup})' : ''}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        // Add more nutrients as needed from the database.json
        // For example:
        // _buildNutrientRow(theme, 'Sodium', widget.food.sodium, 'mg'),
        // _buildNutrientRow(theme, 'Potassium', widget.food.potassium, 'mg'),
        const SizedBox(height: 16),
        // Gram input
        Row(
          children: [
            if (unitOptions.length > 1)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: DropdownButton<String>(
                  value: _selectedUnit,
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
                      _selectedUnit = value;
                    });
                  },
                ),
              ),
            Expanded(
              child: TextField(
                controller: _gramsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: usesGrams
                      ? 'Amount (g)'
                      : 'Amount ($unitLabel)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
        if (!usesGrams)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _gramsPreviewText(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isLight
                    ? LightColors.mutedForeground
                    : DarkColors.mutedForeground,
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Meal buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMealButton(theme, 'Breakfast', () {
              final amount = double.tryParse(_gramsController.text) ??
                  (usesGrams ? 100.0 : 1.0);
              final grams =
                  widget.food.gramsForAmount(amount, unitType: _selectedUnit);
              widget.onAdd(widget.food, grams, 'Breakfast');
            }),
            _buildMealButton(theme, 'Lunch', () {
              final amount = double.tryParse(_gramsController.text) ??
                  (usesGrams ? 100.0 : 1.0);
              final grams =
                  widget.food.gramsForAmount(amount, unitType: _selectedUnit);
              widget.onAdd(widget.food, grams, 'Lunch');
            }),
            _buildMealButton(theme, 'Dinner', () {
              final amount = double.tryParse(_gramsController.text) ??
                  (usesGrams ? 100.0 : 1.0);
              final grams =
                  widget.food.gramsForAmount(amount, unitType: _selectedUnit);
              widget.onAdd(widget.food, grams, 'Dinner');
            }),
            _buildMealButton(theme, 'Snack', () {
              final amount = double.tryParse(_gramsController.text) ??
                  (usesGrams ? 100.0 : 1.0);
              final grams =
                  widget.food.gramsForAmount(amount, unitType: _selectedUnit);
              widget.onAdd(widget.food, grams, 'Snack');
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildNutrientRow(ThemeData theme, String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text('${value.toStringAsFixed(1)} $unit', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildMealButton(ThemeData theme, String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
      ),
      child: Text(label),
    );
  }

  Widget _nutrientChip(
    String label,
    String value,
    Color color, {
    bool muted = false,
  }) {
    final bgColor = muted ? color.withOpacity(0.12) : color.withOpacity(0.18);
    final textColor = muted ? color.withOpacity(0.7) : color;
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

  String _defaultUnitFor(IndianFoodModel food) {
    return food.unitType.toLowerCase() == 'gram' ? 'gram' : food.unitType;
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

  String _gramsPreviewText() {
    final amount = double.tryParse(_gramsController.text);
    if (amount == null || amount <= 0) {
      return '~ ${widget.food.servingWeightInGrams.toStringAsFixed(0)} g per ${_unitLabelForType(_selectedUnit)}';
    }
    final grams = widget.food.gramsForAmount(amount, unitType: _selectedUnit);
    return '~ ${grams.toStringAsFixed(0)} g';
  }
}
