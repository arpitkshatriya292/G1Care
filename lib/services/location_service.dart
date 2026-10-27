import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final bool isSimulated;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.isSimulated,
    required this.timestamp,
  });

  /// Default baseline simulated location (Pune City Center / Shivajinagar)
  factory LocationData.defaultSimulated({double? lat, double? lng, String? addr}) {
    return LocationData(
      latitude: lat ?? 18.5204,
      longitude: lng ?? 73.8567,
      address: addr ?? 'FC Road, Shivajinagar, Pune, Maharashtra, India',
      isSimulated: true,
      timestamp: DateTime.now(),
    );
  }
}

abstract class ILocationService {
  Future<LocationData> getCurrentLocation();
}

class LocationService implements ILocationService {
  /// Attempt to fetch real GPS location from device, with seamless fallback to Pune simulated coordinates
  @override
  Future<LocationData> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location service disabled on device. Using simulated Pune prototype location.');
        return LocationData.defaultSimulated();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied. Using simulated Pune prototype location.');
          return LocationData.defaultSimulated();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied. Using simulated Pune prototype location.');
        return LocationData.defaultSimulated();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Live GPS (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
        isSimulated: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error getting device location ($e). Using simulated Pune prototype location.');
      return LocationData.defaultSimulated();
    }
  }
}
