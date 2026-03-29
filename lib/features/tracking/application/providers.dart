import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_storage.dart';
import 'tracking_service.dart';

// Provider for Tracking Notifier connecting Geolocator and Hive
final trackingProvider =
    NotifierProvider<TrackingNotifier, TrackingState>(() {
  return TrackingNotifier();
});

// Helper provider for getting all sessions from Hive
// We can use a StateProvider that is invalidated, or just return from Hive Storage.
final allSessionsProvider = Provider((ref) {
  final hive = ref.watch(hiveStorageProvider);
  // This will read the values. For dynamic updates, 
  // you might want to use Hive's listenable or a separate StateNotifier for session lists.
  return hive.getAllSessions();
});
