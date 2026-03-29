import 'dart:math' as math;

/// Calculates the distance between two GPS coordinates using the Haversine formula.
/// Returns the distance in kilometers.
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadiusKm = 6371.0;

  final double dLat = _degreesToRadians(lat2 - lat1);
  final double dLon = _degreesToRadians(lon2 - lon1);

  final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degreesToRadians(lat1)) *
          math.cos(_degreesToRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadiusKm * c;
}

double _degreesToRadians(double degrees) {
  return degrees * math.pi / 180.0;
}
