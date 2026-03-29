import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/models.dart';

final hiveStorageProvider = Provider<HiveStorage>((ref) {
  return HiveStorage();
});

class HiveStorage {
  static const String sessionBoxName = 'walking_sessions';

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LocationPointAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(WalkingSessionAdapter());
    }

    // Open box
    await Hive.openBox<WalkingSession>(sessionBoxName);
  }

  Future<void> saveSession(WalkingSession session) async {
    final box = Hive.box<WalkingSession>(sessionBoxName);
    await box.put(session.id, session);
  }

  List<WalkingSession> getAllSessions() {
    final box = Hive.box<WalkingSession>(sessionBoxName);
    return box.values.toList().cast<WalkingSession>();
  }

  WalkingSession? getSession(String id) {
    final box = Hive.box<WalkingSession>(sessionBoxName);
    return box.get(id);
  }

  Future<void> deleteSession(String id) async {
    final box = Hive.box<WalkingSession>(sessionBoxName);
    await box.delete(id);
  }
}
