import 'package:hive/hive.dart';

class LocationPoint {
  final double lat;
  final double lng;
  final DateTime timestamp;

  LocationPoint({
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory LocationPoint.fromMap(Map<dynamic, dynamic> map) {
    return LocationPoint(
      lat: map['lat'] as double,
      lng: map['lng'] as double,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}

class LocationPointAdapter extends TypeAdapter<LocationPoint> {
  @override
  final int typeId = 0;

  @override
  LocationPoint read(BinaryReader reader) {
    final map = reader.readMap();
    return LocationPoint.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, LocationPoint obj) {
    writer.writeMap(obj.toMap());
  }
}

class WalkingSession {
  final String id;
  final List<LocationPoint> points;
  final double totalDistance;
  final Duration duration;

  WalkingSession({
    required this.id,
    required this.points,
    required this.totalDistance,
    required this.duration,
  });

  // Helper getters for UI
  double get averageSpeedKmH {
    if (duration.inSeconds == 0) return 0.0;
    return totalDistance / (duration.inSeconds / 3600.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'points': points.map((p) => p.toMap()).toList(),
      'totalDistance': totalDistance,
      'duration': duration.inMilliseconds,
    };
  }

  factory WalkingSession.fromMap(Map<dynamic, dynamic> map) {
    return WalkingSession(
      id: map['id'] as String,
      points: (map['points'] as List)
          .map((p) => LocationPoint.fromMap(p as Map<dynamic, dynamic>))
          .toList(),
      totalDistance: map['totalDistance'] as double,
      duration: Duration(milliseconds: map['duration'] as int),
    );
  }
}

class WalkingSessionAdapter extends TypeAdapter<WalkingSession> {
  @override
  final int typeId = 1;

  @override
  WalkingSession read(BinaryReader reader) {
    final map = reader.readMap();
    return WalkingSession.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, WalkingSession obj) {
    writer.writeMap(obj.toMap());
  }
}
