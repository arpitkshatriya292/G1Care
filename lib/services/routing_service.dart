import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/hospital.dart';

class RouteResult {
  final List<LatLng> waypoints;
  final double distanceKm;
  final int durationMinutes;
  final bool isSimulatedRoute;

  const RouteResult({
    required this.waypoints,
    required this.distanceKm,
    required this.durationMinutes,
    required this.isSimulatedRoute,
  });

  /// Fallback geometric waypoint interpolation for offline / no-network situations
  factory RouteResult.interpolate(LatLng start, LatLng end, {int steps = 15}) {
    final points = <LatLng>[];
    final directDistance = Hospital.calculateDistanceKm(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );

    // City route factor (~1.3x direct distance)
    final adjustedDist = directDistance * 1.3;
    final minutes = max(2, (adjustedDist / 35.0 * 60).round()); // Assuming 35 km/h emergency speed

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      // Slight natural curve perturbation
      final perp = sin(t * pi) * 0.002;
      final lat = start.latitude + (end.latitude - start.latitude) * t + perp;
      final lng = start.longitude + (end.longitude - start.longitude) * t + perp;
      points.add(LatLng(lat, lng));
    }

    return RouteResult(
      waypoints: points,
      distanceKm: double.parse(adjustedDist.toStringAsFixed(1)),
      durationMinutes: minutes,
      isSimulatedRoute: true,
    );
  }
}

class RoutingService {
  static bool useOfflineOnly = false;

  /// Fetch driving route from free public OSRM service with automatic fallback to waypoint interpolation
  static Future<RouteResult> getRoute(LatLng start, LatLng end) async {
    if (useOfflineOnly || (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'))) {
      return RouteResult.interpolate(start, end);
    }
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes[0] as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;

          final waypoints = coordinates.map((coord) {
            final List<dynamic> pair = coord as List<dynamic>;
            return LatLng(
              (pair[1] as num).toDouble(),
              (pair[0] as num).toDouble(),
            );
          }).toList();

          final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSecs = (route['duration'] as num?)?.toDouble() ?? 0.0;

          return RouteResult(
            waypoints: waypoints,
            distanceKm: double.parse((distanceMeters / 1000.0).toStringAsFixed(1)),
            durationMinutes: max(1, (durationSecs / 60.0).round()),
            isSimulatedRoute: false,
          );
        }
      }
    } catch (e) {
      debugPrint('OSRM routing request notice ($e). Utilizing offline waypoint generator.');
    }

    // High quality offline mathematical route generator fallback
    return RouteResult.interpolate(start, end);
  }
}
