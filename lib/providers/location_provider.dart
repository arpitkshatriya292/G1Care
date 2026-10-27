import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final ILocationService _locationService;

  LocationData _currentLocation = LocationData.defaultSimulated();
  bool _isLoading = false;
  String? _errorMessage;

  LocationProvider({ILocationService? locationService})
      : _locationService = locationService ?? LocationService();

  LocationData get currentLocation => _currentLocation;
  double get latitude => _currentLocation.latitude;
  double get longitude => _currentLocation.longitude;
  String get address => _currentLocation.address;
  bool get isSimulated => _currentLocation.isSimulated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Refresh and fetch current location
  Future<LocationData> refreshLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loc = await _locationService.getCurrentLocation();
      _currentLocation = loc;
      _isLoading = false;
      notifyListeners();
      return loc;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return _currentLocation;
    }
  }

  /// Manually set custom simulated location for testing/demo
  void setSimulatedLocation(double lat, double lng, {String? addr}) {
    _currentLocation = LocationData.defaultSimulated(lat: lat, lng: lng, addr: addr);
    notifyListeners();
  }
}
