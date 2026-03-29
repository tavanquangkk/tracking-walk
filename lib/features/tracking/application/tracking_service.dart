import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/distance_calculator.dart';
import '../domain/models.dart';
import '../data/hive_storage.dart';

// Provides the overall status of the tracking experience
class TrackingState {
  final bool isTracking;
  final List<LocationPoint> currentPoints;
  final double totalDistance; // in km
  final DateTime? startTime;

  TrackingState({
    required this.isTracking,
    this.currentPoints = const [],
    this.totalDistance = 0.0,
    this.startTime,
  });

  TrackingState copyWith({
    bool? isTracking,
    List<LocationPoint>? currentPoints,
    double? totalDistance,
    DateTime? startTime,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      currentPoints: currentPoints ?? this.currentPoints,
      totalDistance: totalDistance ?? this.totalDistance,
      startTime: startTime ?? this.startTime,
    );
  }

  // Duration calculated on-the-fly
  Duration get currentDuration {
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime!);
  }
}

class TrackingNotifier extends Notifier<TrackingState> {
  StreamSubscription<Position>? _positionStream;

  @override
  TrackingState build() {
    ref.onDispose(() {
      _positionStream?.cancel();
    });
    return TrackingState(isTracking: false);
  }

  Future<void> startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Reset state and set to tracking
    state = TrackingState(
      isTracking: true,
      currentPoints: [],
      totalDistance: 0.0,
      startTime: DateTime.now(),
    );

    // Settings for the location stream.
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2, // Every 2 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _addPoint(position);
    });
  }

  void _addPoint(Position position) {
    final newPoint = LocationPoint(
      lat: position.latitude,
      lng: position.longitude,
      timestamp: position.timestamp,
    );

    double updatedDistance = state.totalDistance;

    if (state.currentPoints.isNotEmpty) {
      final lastPoint = state.currentPoints.last;
      final distanceInKm = calculateDistance(
        lastPoint.lat,
        lastPoint.lng,
        newPoint.lat,
        newPoint.lng,
      );
      updatedDistance += distanceInKm;
    }

    state = state.copyWith(
      currentPoints: [...state.currentPoints, newPoint],
      totalDistance: updatedDistance,
    );
  }

  Future<WalkingSession?> stopTracking() async {
    _positionStream?.cancel();
    _positionStream = null;

    if (state.currentPoints.isEmpty || state.startTime == null) {
      state = TrackingState(isTracking: false);
      return null;
    }

    final duration = DateTime.now().difference(state.startTime!);

    final session = WalkingSession(
      id: const Uuid().v4(),
      points: state.currentPoints,
      totalDistance: state.totalDistance,
      duration: duration,
    );

    // Save locally
    await ref.read(hiveStorageProvider).saveSession(session);

    state = TrackingState(isTracking: false);
    return session;
  }
}
