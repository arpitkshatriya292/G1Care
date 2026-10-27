import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/disaster/disaster_models.dart';
import '../../../providers/disaster_provider.dart';
import '../../../providers/location_provider.dart';

class DisasterSafeLocationScreen extends StatefulWidget {
  const DisasterSafeLocationScreen({super.key});

  @override
  State<DisasterSafeLocationScreen> createState() => _DisasterSafeLocationScreenState();
}

class _DisasterSafeLocationScreenState extends State<DisasterSafeLocationScreen> {
  final MapController _mapController = MapController();
  SafeLocation? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    final disasterProvider = Provider.of<DisasterProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);

    final patientLoc = LatLng(
      locationProvider.currentLocation.latitude,
      locationProvider.currentLocation.longitude,
    );

    final locations = disasterProvider.safeLocations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disaster Safe Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Center My Location',
            onPressed: () {
              _mapController.move(patientLoc, 15.0);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Disaster-Aware Routing Advisory Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.warningOrangeBg,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_rounded, color: AppColors.warningOrange, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DISASTER-AWARE ROUTING ADVISORY',
                        style: TextStyle(
                          color: AppColors.warningOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Standard civilian road routes may be flooded, obstructed, or unstable during ${disasterProvider.disaster.type.displayName}. Always follow verified high-ground evacuation corridors.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Map Area
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: patientLoc,
                    initialZoom: 14.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.g1care.emergency',
                    ),

                    // Hazard / Affected Area Circle representation
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: LatLng(18.5204, 73.8567),
                          radius: 1200,
                          useRadiusInMeter: true,
                          color: disasterProvider.disaster.type.color.withValues(alpha: 0.2),
                          borderColor: disasterProvider.disaster.type.color,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),

                    // Markers
                    MarkerLayer(
                      markers: [
                        // Patient Marker
                        Marker(
                          point: patientLoc,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 1),
                              ],
                            ),
                            child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 24),
                          ),
                        ),

                        // Safe Shelter & Hospital Markers
                        ...locations.map((loc) {
                          final isSelected = _selectedLocation?.id == loc.id;
                          final isHospital = loc.type == 'Hospital';

                          return Marker(
                            point: LatLng(loc.latitude, loc.longitude),
                            width: isSelected ? 48 : 38,
                            height: isSelected ? 48 : 38,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedLocation = loc;
                                });
                                _mapController.move(LatLng(loc.latitude, loc.longitude), 15.5);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isHospital ? AppColors.emergencyRed : AppColors.successGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isHospital ? AppColors.emergencyRed : AppColors.successGreen)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isHospital ? Icons.local_hospital_rounded : Icons.roofing_rounded,
                                  color: Colors.white,
                                  size: isSelected ? 24 : 18,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),

                // Map Legend
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('You', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.successGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('Safe Shelter', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.emergencyRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('Hospital', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Safe Locations List
          Expanded(
            flex: 4,
            child: Container(
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Verified Safe Shelters & Hospitals',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${locations.length} Locations',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: locations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final loc = locations[index];
                        final isSelected = _selectedLocation?.id == loc.id;
                        final isHospital = loc.type == 'Hospital';

                        return Card(
                          elevation: isSelected ? 3 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSelected
                                  ? (isHospital ? AppColors.emergencyRed : AppColors.successGreen)
                                  : AppColors.cardBorder,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                _selectedLocation = loc;
                              });
                              _mapController.move(LatLng(loc.latitude, loc.longitude), 15.5);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isHospital
                                        ? AppColors.emergencyRedBg
                                        : AppColors.successGreenBg,
                                    child: Icon(
                                      isHospital ? Icons.local_hospital_rounded : Icons.roofing_rounded,
                                      color: isHospital ? AppColors.emergencyRed : AppColors.successGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                loc.name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              '${loc.distanceKm} km',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isHospital
                                                    ? AppColors.emergencyRed
                                                    : AppColors.successGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          loc.capacity,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          loc.routeNote,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
