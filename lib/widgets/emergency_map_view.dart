import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_constants.dart';
import '../models/emergency_incident.dart';

class EmergencyMapView extends StatefulWidget {
  final EmergencyIncident incident;
  final List<LatLng> routePoints;
  final LatLng? ambulancePosition;
  final String ambulanceLabel;
  final bool isInteractive;
  final double height;

  const EmergencyMapView({
    super.key,
    required this.incident,
    this.routePoints = const [],
    this.ambulancePosition,
    this.ambulanceLabel = 'G1-AMB-01 (En Route)',
    this.isInteractive = true,
    this.height = 360,
  });

  @override
  State<EmergencyMapView> createState() => _EmergencyMapViewState();
}

class _EmergencyMapViewState extends State<EmergencyMapView> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant EmergencyMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If ambulance moves, gently follow
    if (widget.ambulancePosition != null &&
        widget.ambulancePosition != oldWidget.ambulancePosition) {
      // Keep map responsive without jerking camera
    }
  }

  void _recenterOnPatient() {
    _mapController.move(
      LatLng(widget.incident.latitude, widget.incident.longitude),
      15.0,
    );
  }

  void _recenterOnAmbulance() {
    if (widget.ambulancePosition != null) {
      _mapController.move(widget.ambulancePosition!, 15.0);
    }
  }

  void _fitAllMarkers() {
    final points = <LatLng>[
      LatLng(widget.incident.latitude, widget.incident.longitude),
    ];
    if (widget.ambulancePosition != null) {
      points.add(widget.ambulancePosition!);
    }
    if (widget.incident.hospitalLatitude != null &&
        widget.incident.hospitalLongitude != null) {
      points.add(LatLng(
        widget.incident.hospitalLatitude!,
        widget.incident.hospitalLongitude!,
      ));
    }

    if (points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientPos = LatLng(widget.incident.latitude, widget.incident.longitude);
    final ambPos = widget.ambulancePosition ??
        (widget.incident.ambulanceLatitude != null && widget.incident.ambulanceLongitude != null
            ? LatLng(widget.incident.ambulanceLatitude!, widget.incident.ambulanceLongitude!)
            : null);
    final hospPos = widget.incident.hospitalLatitude != null && widget.incident.hospitalLongitude != null
        ? LatLng(widget.incident.hospitalLatitude!, widget.incident.hospitalLongitude!)
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: patientPos,
                initialZoom: 14.0,
                interactionOptions: InteractionOptions(
                  flags: widget.isInteractive ? InteractiveFlag.all : InteractiveFlag.none,
                ),
              ),
              children: [
                // OpenStreetMap Standard Tiles (Free & Open, No API Keys)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.g1care.g1care',
                  maxZoom: 19,
                ),

                // Route Polyline Layer
                if (widget.routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.routePoints,
                        strokeWidth: 4.5,
                        color: AppColors.emergencyRed.withValues(alpha: 0.85),
                      ),
                    ],
                  ),

                // Markers Layer
                MarkerLayer(
                  markers: [
                    // 1. PATIENT MARKER 📍
                    Marker(
                      point: patientPos,
                      width: 80,
                      height: 80,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.emergencyRed,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              widget.incident.patientName.split(' ').first,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Icon(
                            Icons.location_on,
                            color: AppColors.emergencyRed,
                            size: 38,
                          ),
                        ],
                      ),
                    ),

                    // 2. DIGITAL AMBULANCE MARKER 🚑
                    if (ambPos != null)
                      Marker(
                        point: ambPos,
                        width: 90,
                        height: 90,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4),
                                ],
                              ),
                              child: const Text(
                                '🚑 G1-AMB',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 2),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 6),
                                ],
                              ),
                              child: const Icon(
                                Icons.emergency,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 3. HOSPITAL MARKER 🏥
                    if (hospPos != null)
                      Marker(
                        point: hospPos,
                        width: 90,
                        height: 90,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4),
                                ],
                              ),
                              child: const Text(
                                '🏥 Hospital',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Icon(
                              Icons.local_hospital,
                              color: AppColors.secondary,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Top Status Overlay (Simulation & Attribution)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_tethering, color: AppColors.secondary, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'DEMO • SIMULATED TRACKING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Right Map Control Action Buttons
            if (widget.isInteractive)
              Positioned(
                bottom: 12,
                right: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'map_fit_${widget.incident.incidentId}',
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      onPressed: _fitAllMarkers,
                      tooltip: 'Fit Route',
                      child: const Icon(Icons.crop_free, size: 20),
                    ),
                    const SizedBox(height: 6),
                    FloatingActionButton.small(
                      heroTag: 'map_patient_${widget.incident.incidentId}',
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.emergencyRed,
                      onPressed: _recenterOnPatient,
                      tooltip: 'Patient Location',
                      child: const Icon(Icons.my_location, size: 20),
                    ),
                    if (ambPos != null) ...[
                      const SizedBox(height: 6),
                      FloatingActionButton.small(
                        heroTag: 'map_amb_${widget.incident.incidentId}',
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        onPressed: _recenterOnAmbulance,
                        tooltip: 'Ambulance Location',
                        child: const Icon(Icons.directions_car, size: 20),
                      ),
                    ],
                  ],
                ),
              ),

            // Bottom OSM Attribution (Required by OpenStreetMap policy)
            Positioned(
              bottom: 4,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
