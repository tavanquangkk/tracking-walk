import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/tracking/application/providers.dart';
import 'features/tracking/data/hive_storage.dart';
import 'features/tracking/presentation/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive before running app
  final container = ProviderContainer();
  final hiveStorage = container.read(hiveStorageProvider);
  await hiveStorage.init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TrackingWalkApp(),
    ),
  );
}

class TrackingWalkApp extends StatelessWidget {
  const TrackingWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Strava',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFC4C02), // Strava orange
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFC4C02),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
