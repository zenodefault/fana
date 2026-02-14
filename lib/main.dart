import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'core/theme.dart';
import 'core/providers.dart';
import 'core/navigation.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/indian_food_model.dart';
import 'core/services/food_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  final appDir = await getApplicationDocumentsDirectory();
  Hive.init(appDir.path);

  // Register adapters
  Hive.registerAdapter(IndianFoodModelAdapter());

  // Initialize food database
  await FoodDatabaseService.initialize();

  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FitnessProvider(),
      child: MaterialApp(
        title: 'Sumi',
        theme: FitnessTheme.lightTheme,
        darkTheme: FitnessTheme.darkTheme,
        home: const OnboardingGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class OnboardingGate extends StatelessWidget {
  const OnboardingGate({super.key});

  Future<bool> _isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isOnboardingComplete(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final complete = snapshot.data ?? false;
        if (complete) {
          return const AppShell();
        }
        return const OnboardingScreen();
      },
    );
  }
}
