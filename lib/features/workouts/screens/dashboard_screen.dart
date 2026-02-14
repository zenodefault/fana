import 'package:flutter/material.dart';
import '../../../core/app_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../core/providers.dart';
import '../../../core/entry_radial_menu.dart';
import '../../../core/glass_widgets.dart';
import '../../../core/widgets.dart';
import '../../todo/screens/todo_screen.dart';
import '../widgets/calendar_card_widget.dart';
import '../../habits/widgets/streak_card.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../../calories/screens/calorie_tracking_screen.dart';
import '../../anatomy/screens/anatomy_screen.dart';
import 'exercise_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key}) : super();

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showRadialMenu = false;
  bool _cardsVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _cardsVisible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FitnessProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Title row with profile icon
                  GlassContainer(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    borderRadius: 18,
                    opacity: 0.2,
                    blur: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            provider.user == null ||
                                    provider.user!.name.isEmpty
                                ? 'Welcome!!'
                                : 'Welcome ${provider.user!.name}!!',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.brightness == Brightness.light
                                  ? LightColors.foreground
                                  : DarkColors.foreground,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GlassContainer(
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.all(6),
                          borderRadius: 20,
                          opacity: 0.24,
                          blur: 14,
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UserProfileScreen(),
                                ),
                              );
                            },
                            icon: AppIcon(AppIcons.user),
                            color: theme.brightness == Brightness.light
                                ? LightColors.foreground
                                : DarkColors.foreground,
                            tooltip: 'Profile',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Metrics grid
                  Container(
                    height: 200, // Fixed height for the grid
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0, // Square aspect ratio
                      shrinkWrap: true,
                      children: [
                        // EXERCISE STREAK CARD
                        _buildAnimatedCard(
                          _buildExerciseStreakCard(provider, theme),
                          delay: 0,
                        ),
                        // STREAK CARD: Shows habit tracking streaks
                        _buildAnimatedCard(
                          const StreakCard(),
                          delay: 80,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // CALENDAR CARD: Shows three months with workout activity dots
                  Container(
                    height:
                        220, // Increased height to accommodate content better
                    child: _buildAnimatedCard(
                      const CalendarCardWidget(),
                      delay: 140,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAnimatedCard(
                    _buildCaloriesProgressCard(provider, theme),
                    delay: 200,
                  ),
                  const SizedBox(height: 12),
                  _buildAnimatedCard(
                    _buildHistoryCard(theme),
                    delay: 220,
                  ),
                ],
              ),
            ),
            // Radial menu overlay when needed - make sure it doesn't interfere with main content
            if (_showRadialMenu)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: Container(
                    color: Colors.transparent,
                    child: EntryRadialMenu(
                      onWorkoutPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnatomyScreen(),
                            settings: const RouteSettings(
                              arguments: {'preselectMuscle': 'Chest'},
                            ),
                          ),
                        );
                      },
                      onTodoPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TodoScreen(),
                          ),
                        );
                      },
                      onClose: () {
                        setState(() {
                          _showRadialMenu = false;
                        });
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseStreakCard(FitnessProvider provider, ThemeData theme) {
    final isLight = theme.brightness == Brightness.light;
    final streak = provider.getExerciseStreak();

    return GlassDashboardCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      opacity: 0.24,
      blur: 14,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnatomyScreen(),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final iconSize = constraints.maxHeight < 140 ? 40.0 : 50.0;
          final titleSize = constraints.maxHeight < 140 ? 14.0 : 16.0;
          final streakSize = constraints.maxHeight < 140 ? 18.0 : 20.0;
          final subtitleSize = constraints.maxHeight < 140 ? 11.0 : 12.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: (isLight ? LightColors.primary : DarkColors.primary)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  AppIcons.dumbbell,
                  color: isLight ? LightColors.primary : DarkColors.primary,
                  size: iconSize * 0.55,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Exercise Streak',
                  style: TextStyle(
                    color:
                        isLight ? LightColors.foreground : DarkColors.foreground,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$streak days',
                  style: TextStyle(
                    color: isLight ? LightColors.primary : DarkColors.primary,
                    fontSize: streakSize,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: (isLight
                                ? LightColors.primary
                                : DarkColors.primary)
                            .withAlpha(120),
                        blurRadius: 6,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Tap to train',
                  style: TextStyle(
                    color: isLight
                        ? LightColors.mutedForeground
                        : DarkColors.mutedForeground,
                    fontSize: subtitleSize,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(ThemeData theme) {
    final isLight = theme.brightness == Brightness.light;

    return GlassDashboardCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      opacity: 0.22,
      blur: 14,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ExerciseHistoryScreen(),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (isLight ? LightColors.primary : DarkColors.primary)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppIcon(
                AppIcons.time,
                size: 26,
                color: isLight ? LightColors.primary : DarkColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exercise History',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review your logged sets & reps',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isLight
                        ? LightColors.mutedForeground
                        : DarkColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          AppIcon(
            AppIcons.chevronRight,
            size: 20,
            color: theme.iconTheme.color?.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(Widget child, {required int delay}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 380),
      opacity: _cardsVisible ? 1 : 0,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 380),
        offset: _cardsVisible ? Offset.zero : const Offset(0, 0.03),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  Widget _buildCaloriesProgressCard(
    FitnessProvider provider,
    ThemeData theme,
  ) {
    final isLight = theme.brightness == Brightness.light;
    final calorieGoal = provider.getTdee();
    final consumed = provider.getTodaysCaloriesConsumed().toDouble();
    final progress = (consumed / calorieGoal).clamp(0.0, 1.0);

    return GlassDashboardCard(
      padding: const EdgeInsets.all(14),
      margin: EdgeInsets.zero,
      opacity: 0.24,
      blur: 14,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CalorieTrackingScreen(),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calories',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isLight
                            ? LightColors.foreground
                            : DarkColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Today',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isLight
                            ? LightColors.mutedForeground
                            : DarkColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: (isLight
                        ? LightColors.mutedForeground
                        : DarkColors.mutedForeground)
                    .withAlpha(50),
              ),
              const SizedBox(width: 12),
              Text(
                '${consumed.toStringAsFixed(0)} kcal',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLight
                      ? LightColors.foreground
                      : DarkColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Container(
                  height: 18,
                  color: isLight ? LightColors.muted : DarkColors.muted,
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isLight
                                  ? LightColors.primary
                                  : DarkColors.primary)
                              .withOpacity(0.35),
                          (isLight
                                  ? LightColors.primary
                                  : DarkColors.primary)
                              .withOpacity(0.15),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${consumed.toStringAsFixed(0)} / ${calorieGoal.toStringAsFixed(0)} kcal',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isLight
                  ? LightColors.mutedForeground
                  : DarkColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  // duplicate exercise streak card removed
}
