import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/disaster/disaster_models.dart';
import '../../providers/disaster_provider.dart';

class DisasterHubScreen extends StatefulWidget {
  const DisasterHubScreen({super.key});

  @override
  State<DisasterHubScreen> createState() => _DisasterHubScreenState();
}

class _DisasterHubScreenState extends State<DisasterHubScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(18.5240, 73.8540); // Pune / Shivajinagar region

  void _showScenarioSwitcherModal(BuildContext context) {
    final disasterProvider = Provider.of<DisasterProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 10),
                Text(
                  'Select Disaster Scenario',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Switch simulated disaster scenarios to test active user health states, map overlays, and safety guidance.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildScenarioChip(context, disasterProvider, DisasterType.flood, 'FLOOD', Icons.water_rounded),
                _buildScenarioChip(context, disasterProvider, DisasterType.heatwave, 'HEATWAVE', Icons.wb_sunny_rounded),
                _buildScenarioChip(context, disasterProvider, DisasterType.cyclone, 'CYCLONE', Icons.cyclone_rounded),
                _buildScenarioChip(context, disasterProvider, DisasterType.earthquake, 'EARTHQUAKE', Icons.vibration_rounded),
                _buildScenarioChip(context, disasterProvider, DisasterType.airPollution, 'AIR POLLUTION', Icons.masks_rounded),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioChip(
    BuildContext context,
    DisasterProvider provider,
    DisasterType type,
    String label,
    IconData icon,
  ) {
    final isSelected = provider.disaster.type == type;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      onSelected: (selected) {
        if (selected) {
          provider.setDisasterScenario(type);
          try {
            _mapController.move(
              LatLng(type.centerLatitude, type.centerLongitude),
              14.2,
            );
          } catch (_) {}
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final disasterProvider = Provider.of<DisasterProvider>(context);
    final disaster = disasterProvider.disaster;
    final selectedUser = disasterProvider.selectedUser;
    final guidance = DisasterSafetyGuidance.forType(disaster.type);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'G1Care DISASTER HUB',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'PUBLIC ACCESS • NO LOGIN REQUIRED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            tooltip: 'Switch Disaster Scenario',
            onPressed: () => _showScenarioSwitcherModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PUBLIC NOTICE / TAGLINE BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withValues(alpha: 0.08),
              child: const Row(
                children: [
                  Icon(Icons.public_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'From Health Monitoring to Disaster Response — Real-Time Public Safety Hub',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. DISASTER STATUS & DETAILS CARD
                  _buildDisasterStatusCard(context, disasterProvider),

                  const SizedBox(height: 16),

                  // 3. SCENARIO SELECTOR BAR
                  _buildScenarioBar(context, disasterProvider),

                  const SizedBox(height: 16),

                  // 4. ACTIVE USER MONITORING STATS SUMMARY
                  _buildActiveUserSummary(disasterProvider),

                  const SizedBox(height: 16),

                  // 5. MAP HEADER & INTERACTIVE MAP VIEW
                  _buildMapSectionHeader(context, disasterProvider),

                  const SizedBox(height: 8),

                  _buildInteractiveMap(disasterProvider),

                  // 6. SELECTED USER MONITORING CARD (Shown when a user marker is clicked)
                  if (selectedUser != null) ...[
                    const SizedBox(height: 12),
                    _buildSelectedUserCard(disasterProvider, selectedUser),
                  ],

                  const SizedBox(height: 20),

                  // 7. SAFETY GUIDANCE SECTION
                  _buildSafetyGuidanceSection(guidance),

                  const SizedBox(height: 20),

                  // 8. EMERGENCY CONTACTS & HELPLINES
                  _buildEmergencyContactsSection(guidance),

                  const SizedBox(height: 20),

                  // 9. DATA PRIVACY & EDGE AI ARCHITECTURE NOTE
                  _buildPrivacyArchitectureCard(),

                  const SizedBox(height: 24),

                  // 10. BACK TO LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('BACK TO LOGIN SCREEN', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildDisasterStatusCard(BuildContext context, DisasterProvider provider) {
    final disaster = provider.disaster;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: disaster.type.color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: disaster.type.color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: disaster.type.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: disaster.type.color,
                  child: Icon(disaster.type.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disaster.type.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: disaster.type.color,
                        ),
                      ),
                      Text(
                        'SEVERITY: ${disaster.severity.displayName.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRed,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔴 ', style: TextStyle(fontSize: 8)),
                      Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        disaster.affectedArea,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.campaign_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'OFFICIAL ADVISORY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        disaster.advisory,
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Source: ${disaster.source}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Broadcast: Live Feed',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioBar(BuildContext context, DisasterProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DISASTER SCENARIO SWITCHER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            InkWell(
              onTap: () => _showScenarioSwitcherModal(context),
              child: const Text(
                'View All',
                style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCompactScenarioPill(provider, DisasterType.heatwave, 'Heatwave'),
              const SizedBox(width: 8),
              _buildCompactScenarioPill(provider, DisasterType.flood, 'Flood'),
              const SizedBox(width: 8),
              _buildCompactScenarioPill(provider, DisasterType.cyclone, 'Cyclone'),
              const SizedBox(width: 8),
              _buildCompactScenarioPill(provider, DisasterType.earthquake, 'Earthquake'),
              const SizedBox(width: 8),
              _buildCompactScenarioPill(provider, DisasterType.airPollution, 'Air Pollution'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactScenarioPill(DisasterProvider provider, DisasterType type, String label) {
    final isSelected = provider.disaster.type == type;
    return GestureDetector(
      onTap: () {
        provider.setDisasterScenario(type);
        try {
          _mapController.move(
            LatLng(type.centerLatitude, type.centerLongitude),
            14.2,
          );
        } catch (_) {}
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.black12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: 14,
              color: isSelected ? Colors.white : type.color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveUserSummary(DisasterProvider provider) {
    final totalActive = provider.totalActiveUsersCount;
    final safe = provider.safeUsersCount;
    final moderate = provider.moderateUsersCount;
    final high = provider.highRiskUsersCount;
    final critical = provider.criticalUsersCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.people_alt_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'ACTIVE USER MONITORING',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total Active Users: $totalActive',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Live telemetry and health-risk distribution across the affected disaster zone.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Disaster-Specific Health Risk distribution badges (🟢 Safe, 🟡 Moderate, 🟠 High Risk, 🔴 Critical)
          Row(
            children: [
              Expanded(
                child: _buildRiskStatBadge(
                  label: 'SAFE',
                  count: safe,
                  color: AppColors.successGreen,
                  bgColor: const Color(0xFFE8F5E9),
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildRiskStatBadge(
                  label: 'MODERATE',
                  count: moderate,
                  color: const Color(0xFFFBC02D),
                  bgColor: const Color(0xFFFFFDE7),
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildRiskStatBadge(
                  label: 'HIGH RISK',
                  count: high,
                  color: const Color(0xFFFF6D00),
                  bgColor: const Color(0xFFFFF3E0),
                  icon: Icons.error_outline_rounded,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildRiskStatBadge(
                  label: 'CRITICAL',
                  count: critical,
                  color: AppColors.emergencyRed,
                  bgColor: const Color(0xFFFFEBEE),
                  icon: Icons.emergency_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskStatBadge({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSectionHeader(BuildContext context, DisasterProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'AFFECTED ZONE & USER RISK MAP',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        Row(
          children: [
            InkWell(
              onTap: () {
                _mapController.move(_initialCenter, 14.2);
              },
              child: const Row(
                children: [
                  Icon(Icons.center_focus_strong_rounded, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Center',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInteractiveMap(DisasterProvider provider) {
    final users = provider.monitoredUsers;
    final shelters = provider.safeLocations;
    final disaster = provider.disaster;

    return Container(
      height: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(disaster.type.centerLatitude, disaster.type.centerLongitude),
              initialZoom: 14.2,
            ),
            children: [
              // 1. OpenStreetMap Tile Layer (Loaded in app mode, guarded in headless widget tests)
              if (!Platform.environment.containsKey('FLUTTER_TEST'))
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.g1care.disasterhub',
                ),

              // 2. Simulated Hazard / Affected Radius Circle
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(disaster.type.centerLatitude, disaster.type.centerLongitude),
                    radius: disaster.type.hazardRadiusMeters,
                    useRadiusInMeter: true,
                    color: disaster.type.color.withValues(alpha: 0.18),
                    borderColor: disaster.type.color,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),

              // 3. User Health/Risk Markers & Shelter Markers
              MarkerLayer(
                markers: [
                  // Safe Shelters & Hospitals
                  ...shelters.map((shelter) {
                    final isHospital = shelter.type == 'Hospital';
                    return Marker(
                      point: LatLng(shelter.latitude, shelter.longitude),
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isHospital ? AppColors.emergencyRed : AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Icon(
                          isHospital ? Icons.local_hospital_rounded : Icons.roofing_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    );
                  }),

                  // Active Monitored Users (Disaster-specific GPS distribution & Health states)
                  ...users.map((user) {
                    final isSelected = provider.selectedUser?.userId == user.userId;
                    final showIdPill = isSelected || users.length <= 15;
                    return Marker(
                      point: LatLng(user.latitude, user.longitude),
                      width: isSelected ? 76 : (showIdPill ? 52 : 28),
                      height: isSelected ? 60 : (showIdPill ? 46 : 28),
                      child: GestureDetector(
                        onTap: () {
                          provider.selectMonitoredUser(user);
                          _mapController.move(LatLng(user.latitude, user.longitude), 15.5);
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Compact anonymous ID pill
                              if (showIdPill) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    user.userId.split(' ').first,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],

                              // Marker node with state color & icon
                              Container(
                                width: isSelected ? 34 : 22,
                                height: isSelected ? 34 : 22,
                                decoration: BoxDecoration(
                                  color: user.riskState.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: isSelected ? 3 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: user.riskState.color.withValues(alpha: isSelected ? 0.6 : 0.4),
                                      blurRadius: isSelected ? 8 : 4,
                                      spreadRadius: isSelected ? 2 : 0,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  user.riskState.icon,
                                  color: Colors.white,
                                  size: isSelected ? 18 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Floating Map Legend
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'HEALTH / RISK STATE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  _buildLegendItem(AppColors.successGreen, '🟢 Safe'),
                  _buildLegendItem(const Color(0xFFFBC02D), '🟡 Moderate'),
                  _buildLegendItem(const Color(0xFFFF6D00), '🟠 High Risk'),
                  _buildLegendItem(AppColors.emergencyRed, '🔴 Critical'),
                ],
              ),
            ),
          ),

          // Instructions Pill
          Positioned(
            bottom: 8,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Tap any user marker to inspect anonymous health telemetry',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedUserCard(DisasterProvider provider, DisasterMonitoredUser user) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: user.riskState.color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: user.riskState.color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with anonymous identifier
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: user.riskState.color,
                child: Icon(user.riskState.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.userId,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'STATUS: ${user.riskState.displayName.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: user.riskState.color,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: 'Deselect',
                onPressed: () => provider.selectMonitoredUser(null),
              ),
            ],
          ),
          const Divider(height: 16),

          // Health State & Location
          Text(
            user.healthState,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${user.locationName} (${user.locationStatus})',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Vitals Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildTelemetryMetric(
                  icon: Icons.favorite_rounded,
                  color: AppColors.emergencyRed,
                  label: 'Heart Rate',
                  value: user.heartRate != null ? '${user.heartRate} BPM' : '--',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryMetric(
                  icon: Icons.air_rounded,
                  color: AppColors.primary,
                  label: 'SpO2',
                  value: user.spo2 != null ? '${user.spo2}%' : '--',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryMetric(
                  icon: Icons.thermostat_rounded,
                  color: const Color(0xFFE65100),
                  label: 'Body Temp',
                  value: user.bodyTemperature != null ? '${user.bodyTemperature}°C' : '--',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Wearable & Update Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    user.isWearableConnected ? Icons.watch_rounded : Icons.watch_off_outlined,
                    size: 14,
                    color: user.isWearableConnected ? AppColors.successGreen : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.isWearableConnected ? 'Wristband Connected' : 'Wristband Offline',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: user.isWearableConnected ? AppColors.successGreen : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                'Updated: ${user.lastUpdatedText}',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryMetric({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSafetyGuidanceSection(DisasterSafetyGuidance guidance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: guidance.type.color.withValues(alpha: 0.15),
                child: Icon(guidance.type.icon, size: 16, color: guidance.type.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SAFETY GUIDANCE: ${guidance.type.displayName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      guidance.overview,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          ...guidance.keyRules.map((rule) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: guidance.type.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(rule.icon, size: 14, color: guidance.type.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.title,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rule.description,
                          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection(DisasterSafetyGuidance guidance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.emergencyRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.phone_in_talk_rounded, color: AppColors.emergencyRed, size: 20),
              SizedBox(width: 8),
              Text(
                'EMERGENCY HELPLINES & SUPPORT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.emergencyRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: guidance.emergencyContacts.map((contact) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.3)),
                ),
                child: Text(
                  contact,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emergencyRed,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyArchitectureCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy & Architecture Notice',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Disaster Mode uses anonymized identifiers for public monitoring. Personal Identifiable Information (PII), patient identities, and full medical histories are strictly protected.',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
