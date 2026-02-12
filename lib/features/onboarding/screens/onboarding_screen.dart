import 'package:flutter/material.dart';
import '../../../core/app_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../core/glass_widgets.dart';
import '../../../core/models.dart';
import '../../../core/providers.dart';
import '../../../core/navigation.dart';
import '../../habits/services/habit_service.dart';
import '../../habits/models/habit_model.dart' as habit_models;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _step = 0;
  int _previousStep = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  Sex _sex = Sex.other;
  ActivityLevel _activityLevel = ActivityLevel.low;

  String _fitnessFocus = 'General';

  final Map<String, bool> _defaultHabits = {
    'Drink Water': true,
    '10-minute Walk': true,
    'Meditation': true,
  };

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final name = _nameController.text.trim().isEmpty
        ? 'User'
        : _nameController.text.trim();
    final weight = double.tryParse(_weightController.text) ?? 70.0;
    final heightCm = double.tryParse(_heightController.text) ?? 0.0;
    final age = int.tryParse(_ageController.text) ?? 0;

    final user = User(
      id: const Uuid().v4(),
      name: name,
      weight: weight,
      age: age,
      sex: _sex,
      heightCm: heightCm,
      activityLevel: _activityLevel,
      createdAt: DateTime.now(),
    );
    final provider = Provider.of<FitnessProvider>(context, listen: false);
    await provider.updateUser(user);
    await provider.updateDailyLogWithCalories();

    final now = DateTime.now();
    final goals = <Goal>[
      Goal(
        id: const Uuid().v4(),
        title: 'Fitness Focus',
        description: _fitnessFocus,
        targetValue: 1,
        currentValue: 1,
        unit: 'focus',
        startDate: now,
        endDate: now,
      ),
    ];
    for (final goal in goals) {
      await provider.addGoal(goal);
    }

    final coreHabits = _defaultHabits.entries
        .where((entry) => entry.value)
        .map(
          (entry) => Habit(
            id: const Uuid().v4(),
            name: entry.key,
            description: '',
            completedToday: false,
            completionHistory: const {},
          ),
        )
        .toList();
    for (final habit in coreHabits) {
      await provider.addHabit(habit);
    }

    final habitList = _defaultHabits.entries
        .where((entry) => entry.value)
        .map(
          (entry) => habit_models.Habit(
            id: const Uuid().v4(),
            name: entry.key,
            description: '',
            category: 'Health',
            priority: 'Medium',
            isDaily: true,
            reminderTime: '08:00',
            startDate: now,
            completionHistory: const {},
            streakHistory: const {},
          ),
        )
        .toList();
    await HabitService.instance.saveHabits(habitList);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await provider.refreshFromStorage();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AppShell(),
      ),
    );
  }

  void _next() {
    if (_step < 3) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _back() {
    if (_step > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: PageView(
          controller: _controller,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) => setState(() {
            _previousStep = _step;
            _step = index;
          }),
          children: [
            _buildStart(theme, isLight),
            _buildProfile(theme, isLight),
            _buildGoals(theme, isLight),
            _buildHabits(theme, isLight),
          ],
        ),
      ),
    );
  }

  Widget _buildStart(ThemeData theme, bool isLight) {
    return _centeredStep(
      theme,
      title: 'Let’s build your plan',
      subtitle: 'Takes under 1 minute to personalize your journey.',
      icon: AppIcons.chart,
      accentColor: isLight ? const Color(0xFF5B8CFF) : const Color(0xFF7AA2FF),
      isLight: isLight,
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Track workouts, habits, and nutrition in one place.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isLight
                    ? LightColors.mutedForeground
                    : DarkColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                child: const Text('Start'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(ThemeData theme, bool isLight) {
    return _centeredStep(
      theme,
      title: 'About You',
      subtitle: 'This helps us personalize your goals.',
      icon: AppIcons.user,
      accentColor: isLight ? const Color(0xFF5BD1A2) : const Color(0xFF6FE2B8),
      isLight: isLight,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _textField(_nameController, 'Name', isLight: isLight),
            const SizedBox(height: 12),
            _textField(
              _weightController,
              'Weight (kg)',
              keyboardType: TextInputType.number,
              isLight: isLight,
            ),
            const SizedBox(height: 12),
            _textField(
              _heightController,
              'Height (cm)',
              keyboardType: TextInputType.number,
              isLight: isLight,
            ),
            const SizedBox(height: 12),
            _textField(
              _ageController,
              'Age',
              keyboardType: TextInputType.number,
              isLight: isLight,
            ),
            const SizedBox(height: 12),
            _segmentedControl<Sex>(
              label: 'Sex',
              options: const [
                SegmentedOption(label: 'Male', value: Sex.male),
                SegmentedOption(label: 'Female', value: Sex.female),
                SegmentedOption(label: 'Other', value: Sex.other),
              ],
              selected: _sex,
              onChanged: (value) => setState(() => _sex = value),
              isLight: isLight,
            ),
            const SizedBox(height: 12),
            _segmentedControl<ActivityLevel>(
              label: 'Activity',
              options: const [
                SegmentedOption(label: 'Low', value: ActivityLevel.low),
                SegmentedOption(label: 'Moderate', value: ActivityLevel.moderate),
                SegmentedOption(label: 'High', value: ActivityLevel.high),
              ],
              selected: _activityLevel,
              onChanged: (value) => setState(() => _activityLevel = value),
              isLight: isLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoals(ThemeData theme, bool isLight) {
    return _centeredStep(
      theme,
      title: 'Goals',
      subtitle: 'Choose your fitness focus.',
      icon: AppIcons.flag,
      accentColor: isLight ? const Color(0xFFFFB347) : const Color(0xFFFFC069),
      isLight: isLight,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _chipGroup(
              label: 'Fitness Focus',
              options: const [
                'Strength',
                'Endurance',
                'Flexibility',
                'Fat loss',
                'General',
              ],
              selected: _fitnessFocus,
              onSelected: (value) => setState(() => _fitnessFocus = value),
              isLight: isLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabits(ThemeData theme, bool isLight) {
    return _centeredStep(
      theme,
      title: 'Starter Habits',
      subtitle: 'We can add a few habits to kickstart your streaks.',
      icon: AppIcons.calories,
      accentColor: isLight ? const Color(0xFF62D6FF) : const Color(0xFF7BE0FF),
      isLight: isLight,
      child: GlassCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ..._defaultHabits.keys.map((habit) {
              final enabled = _defaultHabits[habit] ?? true;
              return _habitTile(
                habit,
                enabled,
                onChanged: (value) {
                  setState(() {
                    _defaultHabits[habit] = value;
                  });
                },
                isLight: isLight,
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _completeOnboarding,
                child: const Text('Finish'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centeredStep(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required List<List<dynamic>> icon,
    required bool isLight,
    required Widget child,
    Color? accentColor,
  }) {
    final accent = accentColor ??
        (isLight ? LightColors.primary : DarkColors.primary);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      width: index == _step ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _step
                            ? accent
                            : (isLight
                                ? LightColors.mutedForeground.withOpacity(0.25)
                                : DarkColors.mutedForeground.withOpacity(0.25)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GlassContainer(
                  padding: const EdgeInsets.all(12),
                  child: AppIcon(
                    icon,
                    size: 32,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSymbolRow(isLight),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) {
                    final offset = _previousStep < _step ? 12.0 : -12.0;
                    return FadeTransition(
                      opacity: animation,
                      child: Transform.translate(
                        offset: Offset(0, offset * (1 - animation.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    key: ValueKey(_step),
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isLight
                              ? LightColors.foreground
                              : DarkColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isLight
                              ? LightColors.mutedForeground
                              : DarkColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(width: double.infinity, child: child),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_step > 0)
                      TextButton(
                        onPressed: _back,
                        child: const Text('Back'),
                      ),
                    if (_step > 0 && _step < 3) const SizedBox(width: 12),
                    if (_step < 3)
                      ElevatedButton(
                        onPressed: _next,
                        child: const Text('Next'),
                      ),
                  ],
                ),
                if (_step == 1) ...[
                  const SizedBox(height: 10),
                  Text(
                    'We use these info to calculate total kcal required for the day.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isLight
                          ? LightColors.mutedForeground
                          : DarkColors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSymbolRow(bool isLight) {
    final List<List<List<dynamic>>> icons = _stepSymbols();
    if (icons.isEmpty) return const SizedBox.shrink();
    final color =
        isLight ? LightColors.mutedForeground : DarkColors.mutedForeground;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: icons
          .map(
            (icon) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppIcon(
                icon,
                size: 16,
                color: color,
              ),
            ),
          )
          .toList(),
    );
  }

  List<List<List<dynamic>>> _stepSymbols() {
    switch (_step) {
      case 0:
        return [AppIcons.dumbbell, AppIcons.calories, AppIcons.habits];
      case 1:
        return [AppIcons.user, AppIcons.flag, AppIcons.chart];
      case 2:
        return [AppIcons.flag, AppIcons.chart, AppIcons.trendUp];
      case 3:
        return [AppIcons.habits, AppIcons.streak, AppIcons.calendar];
      default:
        return const [];
    }
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    required bool isLight,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor:
            (isLight ? Colors.black : Colors.white).withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color:
                (isLight ? Colors.black : Colors.white).withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color:
                (isLight ? Colors.black : Colors.white).withOpacity(0.18),
          ),
        ),
      ),
    );
  }

  Widget _segmentedControl<T>({
    required String label,
    required List<SegmentedOption<T>> options,
    required T selected,
    required ValueChanged<T> onChanged,
    required bool isLight,
  }) {
    final active = isLight ? Colors.black : Colors.white;
    final inactive = isLight ? Colors.black54 : Colors.white60;
    final border = isLight
        ? Colors.black.withOpacity(0.08)
        : Colors.white.withOpacity(0.08);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.black.withOpacity(0.04)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: options.map((option) {
              final isSelected = option.value == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(option.value),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 160),
                    scale: isSelected ? 1.0 : 0.97,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isLight
                                ? Colors.white
                                : Colors.white.withOpacity(0.12))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        option.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected ? active : inactive,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _chipGroup({
    required String label,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
    required bool isLight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final isSelected = option == selected;
            return GestureDetector(
              onTap: () => onSelected(option),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 150),
                scale: isSelected ? 1.0 : 0.96,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isLight
                            ? Colors.black.withOpacity(0.9)
                            : Colors.white.withOpacity(0.14))
                        : (isLight
                            ? Colors.black.withOpacity(0.06)
                            : Colors.white.withOpacity(0.08)),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isLight
                              ? Colors.black.withOpacity(0.08)
                              : Colors.white.withOpacity(0.12)),
                    ),
                  ),
                  child: Text(
                    option,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? (isLight ? Colors.white : Colors.white)
                              : (isLight ? Colors.black87 : Colors.white70),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _habitTile(
    String label,
    bool enabled, {
    required ValueChanged<bool> onChanged,
    required bool isLight,
  }) {
    final bg = isLight
        ? Colors.black.withOpacity(0.04)
        : Colors.white.withOpacity(0.06);
    final border = isLight
        ? Colors.black.withOpacity(0.08)
        : Colors.white.withOpacity(0.12);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class SegmentedOption<T> {
  final String label;
  final T value;

  const SegmentedOption({required this.label, required this.value});
}
