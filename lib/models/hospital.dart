import 'dart:math';

class Hospital {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String phone;
  final String emergencyCapability; // e.g. 'Level 1 Trauma Center', '24/7 Cardiac & Emergency Care'
  final bool isAvailable;

  const Hospital({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phone,
    required this.emergencyCapability,
    this.isAvailable = true,
  });

  /// Deterministic curated list of emergency hospitals in Pune Region for prototype demo
  static const List<Hospital> defaultHospitals = [
    Hospital(
      id: 'PUNE-HOSP-001',
      name: 'Ruby Hall Clinic (Emergency & Trauma)',
      latitude: 18.5326,
      longitude: 73.8785,
      address: '40 Sassoon Road, Pune Station Area, Pune',
      phone: '+91 20 6645 5100',
      emergencyCapability: 'Level 1 Trauma • 24/7 ICU & Cath Lab',
    ),
    Hospital(
      id: 'PUNE-HOSP-002',
      name: 'Jehangir Hospital (Emergency Care)',
      latitude: 18.5302,
      longitude: 73.8770,
      address: '32 Sassoon Road, Central Pune',
      phone: '+91 20 6681 1000',
      emergencyCapability: '24/7 Acute Stroke & Cardiac Emergency',
    ),
    Hospital(
      id: 'PUNE-HOSP-003',
      name: 'Sahyadri Super Speciality Hospital',
      latitude: 18.5135,
      longitude: 73.8340,
      address: 'Plot No. 30-C, Erandwane, Karve Road, Pune',
      phone: '+91 20 6721 3000',
      emergencyCapability: '24/7 Comprehensive Emergency & Trauma',
    ),
    Hospital(
      id: 'PUNE-HOSP-004',
      name: 'KEM Hospital Pune (Emergency Dept)',
      latitude: 18.5218,
      longitude: 73.8715,
      address: 'Rasta Peth, Sardar Moodliar Road, Pune',
      phone: '+91 20 6603 7300',
      emergencyCapability: '24/7 Multi-Speciality Trauma Center',
    ),
    Hospital(
      id: 'PUNE-HOSP-005',
      name: 'Deenanath Mangeshkar Hospital',
      latitude: 18.4996,
      longitude: 73.8322,
      address: 'Near Mhatre Bridge, Erandwane, Pune',
      phone: '+91 20 4015 1000',
      emergencyCapability: 'Advanced Emergency Care & Burn Unit',
    ),
  ];

  /// Find nearest hospital from given patient coordinates
  static Hospital findNearest(double lat, double lng, {List<Hospital>? hospitals}) {
    final list = hospitals ?? defaultHospitals;
    if (list.isEmpty) return defaultHospitals.first;

    Hospital nearest = list.first;
    double minDistance = double.infinity;

    for (final hosp in list) {
      final d = calculateDistanceKm(lat, lng, hosp.latitude, hosp.longitude);
      if (d < minDistance) {
        minDistance = d;
        nearest = hosp;
      }
    }
    return nearest;
  }

  /// Haversine distance in kilometers
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
