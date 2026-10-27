import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_constants.dart';
import '../../services/medical_id_service.dart';
import '../../services/firestore_service.dart';

class DoctorQrScannerScreen extends StatefulWidget {
  const DoctorQrScannerScreen({super.key});

  @override
  State<DoctorQrScannerScreen> createState() => _DoctorQrScannerScreenState();
}

class _DoctorQrScannerScreenState extends State<DoctorQrScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  CameraFacing _cameraFacing = CameraFacing.back;
  late AnimationController _animController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    _processQrString(rawValue.trim());
  }

  Future<void> _processQrString(String rawQrString) async {
    setState(() {
      _isProcessing = true;
    });

    final trimmed = rawQrString.trim();

    // 1. Check if scanned string is an opaque G1Care security QR token
    if (MedicalIdService.isOpaqueQrToken(trimmed)) {
      final medicalId = MedicalIdService.lookupMedicalIdByToken(trimmed);
      if (medicalId == null) {
        if (!mounted) return;
        _showUnknownTokenDialog(trimmed);
        return;
      }

      final firestoreService = FirestoreService();
      final result = await firestoreService.fetchProfileWithSourceByMedicalId(medicalId);
      if (!mounted) return;

      if (result.profile != null) {
        final snapshot = result.profile!.toEmergencySnapshot(
          integrityTag: 'AUTHENTICATED_TOKEN_RESOLVED',
        );
        await Navigator.pushNamed(
          context,
          '/doctor/triage',
          arguments: snapshot,
        );
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }
    }

    // 2. Legacy / Direct Medical ID Entry (e.g. G1-MED-2026-XXXXXX)
    if (trimmed.startsWith('G1-MED-')) {
      final firestoreService = FirestoreService();
      final result = await firestoreService.fetchProfileWithSourceByMedicalId(trimmed);
      if (!mounted) return;

      if (result.profile != null) {
        final syntheticSnapshot = result.profile!.toEmergencySnapshot();
        await Navigator.pushNamed(
          context,
          '/doctor/triage',
          arguments: syntheticSnapshot,
        );
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }
    }

    // 3. Backward-compatible check for legacy signed JSON payload
    final verification = MedicalIdService.verifyQrPayload(rawQrString);
    if (verification.isValid && verification.payload != null) {
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        '/doctor/triage',
        arguments: verification.payload,
      );
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      return;
    }

    // 4. Invalid / Malformed QR
    if (!mounted) return;
    _showScanErrorDialog(verification.error ?? 'Unrecognized or malformed QR code format.');
  }

  void _showUnknownTokenDialog(String token) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.warningOrange, size: 28),
            SizedBox(width: 10),
            Text('Unknown Security Token', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The scanned opaque token was not found in the active emergency directory. Please ensure the patient profile is active or enter the Medical ID manually.',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningOrangeBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Scanned Token: $token',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppColors.warningOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openManualEntrySheet();
            },
            child: const Text('Enter ID Manually'),
          ),
        ],
      ),
    );
  }

  void _showScanErrorDialog(String errorReason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.emergencyRed, size: 28),
            SizedBox(width: 10),
            Text('Invalid QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The scanned QR code is not a valid G1Care Emergency ID or failed cryptographic integrity verification.',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.emergencyRedBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.3)),
              ),
              child: Text(
                errorReason,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppColors.emergencyRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openManualEntrySheet();
            },
            child: const Text('Enter ID Manually'),
          ),
        ],
      ),
    );
  }

  void _openManualEntrySheet() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manual Medical ID Lookup',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the patient\'s G1Care Medical ID (e.g. G1-MED-2026-A8F9K2) or paste an emergency payload string.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Medical ID or QR Payload',
                  hintText: 'e.g. G1-MED-2026-A8F9K2',
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final text = textController.text.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(ctx);
                    _processQrString(text);
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Retrieve Emergency Record'),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Patient Emergency QR'),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
            tooltip: 'Toggle Flash',
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android, color: Colors.white),
            tooltip: 'Switch Camera',
            onPressed: () async {
              await _controller.switchCamera();
              setState(() {
                _cameraFacing = _cameraFacing == CameraFacing.back
                    ? CameraFacing.front
                    : CameraFacing.back;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Live Camera Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography_outlined, size: 64, color: Colors.white70),
                      const SizedBox(height: 16),
                      Text(
                        'Camera Unavailable: ${error.errorCode.name}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please verify camera permissions in device settings, or use manual Medical ID entry below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _openManualEntrySheet,
                        icon: const Icon(Icons.keyboard_outlined),
                        label: const Text('Enter Medical ID Manually'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Custom Viewfinder Overlay
          LayoutBuilder(
            builder: (context, constraints) {
              final scanAreaSize = constraints.maxWidth * 0.72;
              final topOffset = (constraints.maxHeight - scanAreaSize) / 2 - 40;
              final leftOffset = (constraints.maxWidth - scanAreaSize) / 2;

              return Stack(
                children: [
                  // Darkened background cutout
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.6),
                      BlendMode.srcOut,
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            backgroundBlendMode: BlendMode.dstOut,
                          ),
                        ),
                        Positioned(
                          top: topOffset,
                          left: leftOffset,
                          width: scanAreaSize,
                          height: scanAreaSize,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Viewfinder Border & Corner Guides
                  Positioned(
                    top: topOffset,
                    left: leftOffset,
                    width: scanAreaSize,
                    height: scanAreaSize,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.secondary, width: 2.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  // Animated Scanning Laser Line
                  Positioned(
                    top: topOffset,
                    left: leftOffset,
                    width: scanAreaSize,
                    height: scanAreaSize,
                    child: AnimatedBuilder(
                      animation: _scanLineAnimation,
                      builder: (context, child) {
                        return Align(
                          alignment: Alignment(0, (_scanLineAnimation.value * 2) - 1),
                          child: Container(
                            height: 2,
                            width: scanAreaSize - 20,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Top Guidance Banner
                  Positioned(
                    top: topOffset - 54,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner, color: AppColors.secondary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Align patient Emergency QR in frame',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar for Manual Entry
                  Positioned(
                    bottom: 40,
                    left: 24,
                    right: 24,
                    child: Column(
                      children: [
                        if (_isProcessing)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Verifying cryptographic payload...',
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70, width: 1.5),
                            backgroundColor: Colors.black.withValues(alpha: 0.5),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _openManualEntrySheet,
                          icon: const Icon(Icons.keyboard_outlined, color: Colors.white),
                          label: const Text(
                            'Enter Medical ID Manually / Demo Input',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
