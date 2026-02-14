import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'services/food_database_service.dart';
import 'storage_service.dart';
import 'utils.dart';

class FitnessProvider extends ChangeNotifier {
  User? _user;
  List<DailyLog> _dailyLogs = [];
 List<Habit> _habits = [];
  List<Goal> _goals = [];
  List<WorkoutDay> _workouts = [];
  List<FoodItem> _foodDatabase = [];
  List<FoodLog> _foodLogs = [];
  Map<String, List<Exercise>> _exerciseDatabase = {};
  Timer? _midnightTimer;
  String? _lastDayKey;

  User? get user => _user;
  List<DailyLog> get dailyLogs => _dailyLogs;
  List<Habit> get habits => _habits;
  List<Goal> get goals => _goals;
  List<WorkoutDay> get workouts => _workouts;
  List<FoodItem> get foodDatabase => _foodDatabase;
  List<FoodLog> get foodLogs => _foodLogs;
  Map<String, List<Exercise>> get exerciseDatabase => _exerciseDatabase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  FitnessProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    _isLoading = true;
    notifyListeners();

    // Load user data
    _user = await StorageService.instance.getUser();
    
    // Load other data
    _dailyLogs = await StorageService.instance.getDailyLogs();
    _habits = await StorageService.instance.getHabits();
    _goals = await StorageService.instance.getGoals();
    _workouts = await StorageService.instance.getWorkouts();
    
    // Initialize databases
    _foodDatabase = AppUtils.getIndianFoodDatabase();
    _exerciseDatabase = AppUtils.getExerciseDatabase();
    _foodLogs = await StorageService.instance.getFoodLogs();

    await updateDailyLogWithCalories();
    _lastDayKey = _dayKey(DateTime.now());
    _scheduleMidnightRollover();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshFromStorage({bool updateDaily = true}) async {
    _user = await StorageService.instance.getUser();
    _dailyLogs = await StorageService.instance.getDailyLogs();
    _habits = await StorageService.instance.getHabits();
    _goals = await StorageService.instance.getGoals();
    _workouts = await StorageService.instance.getWorkouts();
    _foodLogs = await StorageService.instance.getFoodLogs();
    if (updateDaily) {
      await updateDailyLogWithCalories();
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  String _dayKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _scheduleMidnightRollover() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day).add(
      const Duration(days: 1),
    );
    final duration = nextMidnight.difference(now);
    _midnightTimer = Timer(duration, () async {
      await _handleMidnightRollover(runDailyUpdate: true);
      _scheduleMidnightRollover();
    });
  }

  Future<void> _handleMidnightRollover({bool runDailyUpdate = false}) async {
    final todayKey = _dayKey(DateTime.now());
    if (_lastDayKey == todayKey) return;
    _lastDayKey = todayKey;
    if (runDailyUpdate) {
      await updateDailyLogWithCalories();
    }
    notifyListeners();
  }

  Future<void> updateUser(User user) async {
    _user = user;
    await StorageService.instance.saveUser(user);
    notifyListeners();
  }

  Future<void> addDailyLog(DailyLog log) async {
    _dailyLogs.add(log);
    await StorageService.instance.saveDailyLog(log);
    notifyListeners();
  }

  Future<void> updateDailyLog(DailyLog log) async {
    final index = _dailyLogs.indexWhere((element) => element.id == log.id);
    if (index != -1) {
      _dailyLogs[index] = log;
      await StorageService.instance.saveDailyLog(log);
      notifyListeners();
    }
  }

  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
    await StorageService.instance.saveHabits(_habits);
    notifyListeners();
  }

  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((element) => element.id == habit.id);
    if (index != -1) {
      _habits[index] = habit;
      await StorageService.instance.saveHabits(_habits);
      notifyListeners();
    }
  }

  Future<void> addGoal(Goal goal) async {
    _goals.add(goal);
    await StorageService.instance.saveGoals(_goals);
    notifyListeners();
  }

  Future<void> updateGoal(Goal goal) async {
    final index = _goals.indexWhere((element) => element.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      await StorageService.instance.saveGoals(_goals);
      notifyListeners();
    }
  }

  Future<void> addWorkout(WorkoutDay workout) async {
    _workouts.add(workout);
    await StorageService.instance.saveWorkouts(_workouts);
    notifyListeners();
  }

  Future<void> updateWorkout(WorkoutDay workout) async {
    final index = _workouts.indexWhere((element) => element.id == workout.id);
    if (index != -1) {
      _workouts[index] = workout;
      await StorageService.instance.saveWorkouts(_workouts);
      notifyListeners();
    }
  }

  // Get today's log
  DailyLog? getTodaysLog() {
    final today = DateTime.now();
    final foundLog = _dailyLogs.firstWhere(
      (log) => log.date.day == today.day &&
               log.date.month == today.month &&
               log.date.year == today.year,
      orElse: () => DailyLog(
        id: '',
        date: DateTime(0), // Use a zero date to indicate no log found
        completedExercises: [],
        exerciseEntries: const [],
        caloriesConsumed: 0,
        caloriesBurned: 0,
        weight: 0.0,
        didExerciseToday: false,
      ),
    );
    
    // If the date is zero, it means no log was found for today
    if (foundLog.date == DateTime(0)) {
      return null;
    }
    
    return foundLog;
  }

  Future<void> updateDailyExerciseCheckin(bool didExercise) async {
    final today = DateTime.now();
    final existingIndex = _dailyLogs.indexWhere(
      (log) =>
          log.date.day == today.day &&
          log.date.month == today.month &&
          log.date.year == today.year,
    );

    final existingLog = existingIndex == -1
        ? DailyLog(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            date: today,
            completedExercises: [],
            exerciseEntries: const [],
            caloriesConsumed: 0,
            caloriesBurned: 0,
            weight: getCurrentWeight(),
            didExerciseToday: didExercise,
          )
        : _dailyLogs[existingIndex];

    final updatedLog = DailyLog(
      id: existingLog.id,
      date: existingLog.date,
      completedExercises: existingLog.completedExercises,
      exerciseEntries: existingLog.exerciseEntries,
      caloriesConsumed: existingLog.caloriesConsumed,
      caloriesBurned: existingLog.caloriesBurned,
      weight: existingLog.weight,
      totalCarbs: existingLog.totalCarbs,
      totalProtein: existingLog.totalProtein,
      totalFat: existingLog.totalFat,
      didExerciseToday: didExercise,
    );

    if (existingIndex == -1) {
      await addDailyLog(updatedLog);
    } else {
      await updateDailyLog(updatedLog);
    }
  }

  // Get calories consumed today
  int getTodaysCaloriesConsumed() {
    final todayLog = getTodaysLog();
    return todayLog?.caloriesConsumed ?? 0;
  }

  // Get completed exercises today
  List<String> getTodaysCompletedExercises() {
    final todayLog = getTodaysLog();
    return todayLog?.completedExercises ?? [];
  }

  Future<void> addExerciseEntry(
    String exerciseId,
    int sets,
    int reps,
  ) async {
    final today = DateTime.now();
    final existingIndex = _dailyLogs.indexWhere(
      (log) =>
          log.date.day == today.day &&
          log.date.month == today.month &&
          log.date.year == today.year,
    );

    final existingLog = existingIndex == -1
        ? DailyLog(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            date: today,
            completedExercises: [],
            exerciseEntries: const [],
            caloriesConsumed: 0,
            caloriesBurned: 0,
            weight: getCurrentWeight(),
            didExerciseToday: false,
          )
        : _dailyLogs[existingIndex];

    final updatedEntries = List<ExerciseEntry>.from(
      existingLog.exerciseEntries,
    )..add(
        ExerciseEntry(
          exerciseId: exerciseId,
          sets: sets,
          reps: reps,
          timestamp: DateTime.now(),
        ),
      );

    final updatedCompleted = List<String>.from(
      existingLog.completedExercises,
    );
    if (!updatedCompleted.contains(exerciseId)) {
      updatedCompleted.add(exerciseId);
    }

    final updatedLog = DailyLog(
      id: existingLog.id,
      date: existingLog.date,
      completedExercises: updatedCompleted,
      exerciseEntries: updatedEntries,
      caloriesConsumed: existingLog.caloriesConsumed,
      caloriesBurned: existingLog.caloriesBurned,
      weight: existingLog.weight,
      totalCarbs: existingLog.totalCarbs,
      totalProtein: existingLog.totalProtein,
      totalFat: existingLog.totalFat,
      didExerciseToday: true,
    );

    if (existingIndex == -1) {
      await addDailyLog(updatedLog);
    } else {
      await updateDailyLog(updatedLog);
    }
  }

  int getExerciseStreak() {
    if (_dailyLogs.isEmpty) return 0;

    int streak = 0;
    var current = DateTime.now();
    while (true) {
      final dayHasEntries = _dailyLogs.any(
        (log) =>
            log.date.year == current.year &&
            log.date.month == current.month &&
            log.date.day == current.day &&
            log.exerciseEntries.isNotEmpty,
      );
      if (!dayHasEntries) {
        break;
      }
      streak += 1;
      current = current.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Look up an exercise by id across all muscle group buckets.
  Exercise? getExerciseById(String id) {
    for (final entry in _exerciseDatabase.entries) {
      try {
        return entry.value.firstWhere((e) => e.id == id);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Returns up to [maxDays] of days that contain exercise entries, newest first.
  List<DailyLog> getExerciseHistory({int maxDays = 90}) {
    final history = _dailyLogs
        .where((log) => log.exerciseEntries.isNotEmpty)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (history.length > maxDays) {
      return history.sublist(0, maxDays);
    }
    return history;
  }

  // Get user's current weight
  double getCurrentWeight() {
    if (_user != null) {
      return _user!.weight;
    }
    
    // If no user data, check today's log
    final todayLog = getTodaysLog();
    if (todayLog != null) {
      return todayLog.weight;
    }
    
    // Default weight
    return 70.0;
  }

  double getTdee() {
    final user = _user;
    if (user == null ||
        user.weight <= 0 ||
        user.heightCm <= 0 ||
        user.age <= 0) {
      return 2000.0;
    }

    final bmr = _calculateBmr(user);
    final pal = _activityPal(user.activityLevel);
    return bmr * pal;
  }

  double _calculateBmr(User user) {
    // Use the formula provided by the user (as-is).
    if (user.sex == Sex.female) {
      return 10 * user.weight +
          6.25 * user.heightCm -
          5 * user.age +
          5;
    }
    // male + other
    return 10 * user.weight +
        6.25 * user.heightCm -
        5 * user.age -
        161;
  }

  double _activityPal(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.low:
        return 1.4;
      case ActivityLevel.moderate:
        return 1.6;
      case ActivityLevel.high:
        return 1.8;
    }
  }

  // Get workouts for a specific day
  List<WorkoutDay> getWorkoutsForDay(String day) {
    return _workouts.where((workout) => workout.dayOfWeek == day).toList();
  }

 // Get exercises for a specific workout
  List<Exercise> getExercisesForWorkout(String workoutId) {
    final workout = _workouts.firstWhere((w) => w.id == workoutId, orElse: () => WorkoutDay(id: '', name: '', exercises: [], dayOfWeek: ''));
    return workout.exercises.map((id) {
      for (final exercises in _exerciseDatabase.values) {
        final exercise = exercises.firstWhere((e) => e.id == id, orElse: () => Exercise(
          id: '',
          name: 'Unknown Exercise',
          description: 'No description available',
          muscleGroup: 'Unknown',
          equipmentNeeded: 'N/A',
          difficultyLevel: 'N/A',
          mediaAsset: '',
        ));
        if (exercise.id.isNotEmpty) return exercise;
      }
      return Exercise(
        id: '',
        name: 'Unknown Exercise',
        description: 'No description available',
        muscleGroup: 'Unknown',
        equipmentNeeded: 'N/A',
        difficultyLevel: 'N/A',
        mediaAsset: '',
      );
    }).where((exercise) => exercise.id.isNotEmpty).toList();
  }

  // Food logs management
  Future<void> addFoodLog(FoodLog log) async {
    _foodLogs.add(log);
    await StorageService.instance.saveFoodLog(log);
    await updateDailyLogWithCalories();
    notifyListeners();
  }

  Future<void> updateFoodLog(FoodLog log) async {
    final index = _foodLogs.indexWhere((element) => element.id == log.id);
    if (index != -1) {
      _foodLogs[index] = log;
      await StorageService.instance.saveFoodLog(log);
      await updateDailyLogWithCalories();
      notifyListeners();
    }
  }

  Future<void> deleteFoodLog(String id) async {
    _foodLogs.removeWhere((log) => log.id == id);
    await StorageService.instance.deleteFoodLog(id);
    await updateDailyLogWithCalories();
    notifyListeners();
  }

  List<FoodLog> getTodaysFoodLogs() {
    final today = DateTime.now();
    return _foodLogs.where((log) =>
      log.logDate.day == today.day &&
      log.logDate.month == today.month &&
      log.logDate.year == today.year
    ).toList();
  }

  FoodItem? getFoodByIdSync(String id) {
    return _foodDatabase.firstWhere((food) => food.id == id, orElse: () => FoodItem(id: '', name: 'Unknown', caloriesPerUnit: 0, unit: 'g', category: ''));
  }

  int getTodaysTotalCalories() {
    return getTodaysFoodLogs().fold(0, (sum, log) => sum + log.getTotalCalories());
  }

  // Update daily log with total calories consumed
  Future<void> updateDailyLogWithCalories() async {
    await _handleMidnightRollover(runDailyUpdate: false);
    final today = DateTime.now();
    final foodLogs = getTodaysFoodLogs();
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (var log in foodLogs) {
      final food = await FoodDatabaseService.getFoodById(log.foodItemId);
      if (food != null) {
        final ratio = log.quantity / 100.0;
        totalCarbs += food.carbs * ratio;
        totalProtein += food.protein * ratio;
        totalFat += food.fats * ratio;
        continue;
      }
      final localFood = await FoodDatabaseService.getLocalFoodById(
        log.foodItemId,
      );
      if (localFood != null) {
        final ratio = log.quantity / 100.0;
        totalCarbs += localFood.carbs * ratio;
        totalProtein += localFood.protein * ratio;
        totalFat += localFood.fats * ratio;
        continue;
      }
      final legacyFood = getFoodByIdSync(log.foodItemId);
      if (legacyFood != null) {
        final ratio = log.quantity / 100.0;
        totalCarbs += legacyFood.carbs * ratio;
        totalProtein += legacyFood.protein * ratio;
        totalFat += legacyFood.fats * ratio;
      }
    }

    final existingIndex = _dailyLogs.indexWhere(
      (log) =>
          log.date.day == today.day &&
          log.date.month == today.month &&
          log.date.year == today.year,
    );

    final existingLog = existingIndex == -1
        ? DailyLog(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            date: today,
            completedExercises: [],
            exerciseEntries: const [],
            caloriesConsumed: 0,
            caloriesBurned: 0,
            weight: getCurrentWeight(),
            didExerciseToday: false,
          )
        : _dailyLogs[existingIndex];

    final updatedLog = DailyLog(
      id: existingLog.id.isNotEmpty
          ? existingLog.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      date: existingIndex == -1 ? today : existingLog.date,
      completedExercises: existingLog.completedExercises,
      exerciseEntries: existingLog.exerciseEntries,
      caloriesConsumed: getTodaysTotalCalories(),
      caloriesBurned: existingLog.caloriesBurned,
      weight: existingLog.weight,
      totalCarbs: totalCarbs,
      totalProtein: totalProtein,
      totalFat: totalFat,
      didExerciseToday: existingLog.didExerciseToday,
    );

    if (existingIndex == -1) {
      await addDailyLog(updatedLog);
    } else {
      await updateDailyLog(updatedLog);
    }
  }
}
