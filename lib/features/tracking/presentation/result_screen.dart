import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fl_chart/fl_chart.dart';

import '../domain/models.dart';
import '../../../core/utils/distance_calculator.dart';

class ResultScreen extends StatelessWidget {
  final WalkingSession session;

  const ResultScreen({super.key, required this.session});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final polylineCoordinates = session.points.map((p) => LatLng(p.lat, p.lng)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Finished'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map View
            SizedBox(
              height: 250,
              child: session.points.isEmpty
                  ? const Center(child: Text("No GPS points recorded"))
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: polylineCoordinates.first,
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                        // fit boundaries when map initializes
                        initialCameraFit: CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(polylineCoordinates),
                          padding: const EdgeInsets.all(50),
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.trackingwalk.tracking_walk',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: polylineCoordinates,
                              color: const Color(0xFFFC4C02),
                              strokeWidth: 5,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            
            // Statistics Overview
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatBlock(
                    label: 'Distance',
                    value: session.totalDistance.toStringAsFixed(2),
                    unit: 'km',
                  ),
                  _StatBlock(
                    label: 'Duration',
                    value: _formatDuration(session.duration),
                    unit: '',
                  ),
                  _StatBlock(
                    label: 'Avg Speed',
                    value: session.averageSpeedKmH.toStringAsFixed(1),
                    unit: 'km/h',
                  ),
                ],
              ),
            ),
            const Divider(),
            
            // Speed vs Time Chart Section
            if (session.points.length > 1) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  'Speed over time',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _buildSpeedChart(session),
              const SizedBox(height: 48), // Bottom padding
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedChart(WalkingSession session) {
    if (session.points.length < 2) return const SizedBox();

    List<FlSpot> spots = [];
    final startTime = session.points.first.timestamp;

    for (int i = 1; i < session.points.length; i++) {
      final p1 = session.points[i - 1];
      final p2 = session.points[i];
      
      final distanceKm = calculateDistance(p1.lat, p1.lng, p2.lat, p2.lng);
      final timeDiffSec = p2.timestamp.difference(p1.timestamp).inSeconds;
      
      double speedKmH = 0.0;
      if (timeDiffSec > 0) {
        speedKmH = distanceKm / (timeDiffSec / 3600.0);
      }

      final minutesFromStart = p2.timestamp.difference(startTime).inMinutes.toDouble();
      
      // Prevent wild anomaly speed spikes in case of GPS jumps (cap at 30km/h for walking/running)
      if (speedKmH > 30) speedKmH = 30;

      spots.add(FlSpot(minutesFromStart, speedKmH));
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(right: 24, left: 16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('${value.toInt()}m', style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text('${value.toInt()} km/h', style: const TextStyle(fontSize: 10));
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFFFC4C02),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFFFC4C02).withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatBlock({
    required this.label,
    required this.value,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
