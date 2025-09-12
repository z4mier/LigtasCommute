import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScreen extends StatefulWidget {
  const QRScreen({super.key});

  @override
  State<QRScreen> createState() => _QRScreenState();
}

enum _PermPhase { checking, granted, denied, permanentlyDenied }

class _QRScreenState extends State<QRScreen> {
  late final MobileScannerController _controller;
  bool _handled = false;       // prevent multiple dialogs
  bool _showScanner = true;    // turn off preview when dialog appears
  DateTime? _lastHit;          // debounce
  _PermPhase _perm = _PermPhase.checking;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted, // fastest in v6.0.2
      formats: const [BarcodeFormat.qrCode],
      facing: CameraFacing.back,
      torchEnabled: false,
      autoStart: true, // let widget start the stream; we won't call start() manually
    );
    _checkPermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---- CAMERA PERMISSION ----
  Future<void> _checkPermission() async {
    setState(() => _perm = _PermPhase.checking);

    final status = await Permission.camera.status;

    if (status.isGranted) {
      setState(() => _perm = _PermPhase.granted);
      return;
    }
    if (status.isPermanentlyDenied) {
      setState(() => _perm = _PermPhase.permanentlyDenied);
      return;
    }

    final req = await Permission.camera.request();

    if (req.isGranted) {
      setState(() => _perm = _PermPhase.granted);
    } else if (req.isPermanentlyDenied) {
      setState(() => _perm = _PermPhase.permanentlyDenied);
    } else {
      setState(() => _perm = _PermPhase.denied);
    }
  }

  // ---- SCAN HANDLER ----
  void _onDetect(BarcodeCapture capture) async {
    if (_handled) return;

    final now = DateTime.now();
    if (_lastHit != null && now.difference(_lastHit!) < const Duration(milliseconds: 250)) {
      return; // light debounce
    }
    _lastHit = now;

    final raw = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (raw == null || raw.isEmpty) return;

    _handled = true;

    // hide preview & stop camera so it won't show behind the dialog
    setState(() => _showScanner = false);
    try {
      await _controller.stop(); // safe even if already stopped
    } catch (_) {}

    if (!mounted) return;
    final data = _safeDecode(raw);
    final proceed = await _showDriverDialog(context, data);

    if (!mounted) return;
    Navigator.pop(context, {
      'raw': raw,
      'data': data,
      'proceeded': proceed == true,
    });
  }

  Map<String, dynamic> _safeDecode(String s) {
    try {
      final v = jsonDecode(s);
      return v is Map<String, dynamic> ? v : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  // ---- DRIVER INFO MODAL ----
  Future<bool?> _showDriverDialog(BuildContext context, Map<String, dynamic> data) {
    final now = DateTime.now();
    final scannedOn = '${_month(now.month)} ${now.day}, ${now.year}, ${_clock(now)}';

    final name = (data['name'] ?? '').toString().trim();
    final busNo = (data['bus_no'] ?? data['bus_number'] ?? '').toString().trim();
    final vehicle = (data['vehicle'] ?? data['vehicle_type'] ?? '').toString().trim();
    final plate = (data['plate'] ?? data['plate_no'] ?? '').toString().trim();
    final driverId = (data['driver_id'] ?? '').toString();

    final badge = driverId.isNotEmpty
        ? 'DRV-$driverId'
        : (data['token'] != null && data['token'].toString().length >= 8
            ? 'DRV-${data['token'].toString().substring(0, 8).toUpperCase()}'
            : 'QR');

    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Driver Info',
      barrierColor: Colors.black.withOpacity(0.6),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Driver Information',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          splashRadius: 20,
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Scanned on $scannedOn',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.75),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  name.isNotEmpty ? name : 'Unknown Driver',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Text(
                                  badge,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _kv(label: 'Vehicle Type', value: vehicle.isNotEmpty ? vehicle : '—'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _kv(
                                  label: 'Bus Number',
                                  value: busNo.isNotEmpty ? busNo : '—',
                                  align: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _kv(label: 'Plate No.', value: plate.isNotEmpty ? plate : '—'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Proceed',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.98, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }

  // small key-value line
  Widget _kv({required String label, required String value, TextAlign align = TextAlign.left}) {
    return Column(
      crossAxisAlignment:
          align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: align,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  // formatting helpers
  String _month(int m) =>
      const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];

  String _clock(DateTime t) {
    var h = t.hour;
    final am = h < 12;
    if (h == 0) h = 12;
    if (h > 12) h -= 12;
    final mm = t.minute.toString().padLeft(2, '0');
    return '$h:$mm ${am ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardWidth = w >= 560 ? 520.0 : w * 0.92;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Container(color: Colors.black54),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                width: cardWidth,
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Scan Driver QR Code',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          splashRadius: 20,
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Permission panes or scanner preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _buildScannerArea(),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Text(
                      'Position the QR code within the frame to scan',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.65),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Permission-driven scanner area
  Widget _buildScannerArea() {
    switch (_perm) {
      case _PermPhase.checking:
        return Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      case _PermPhase.denied:
        return _PermissionPane(
          message: 'Camera permission is required to scan QR codes.',
          actionText: 'Allow Camera',
          onAction: _checkPermission,
        );
      case _PermPhase.permanentlyDenied:
        return _PermissionPane(
          message: 'Camera permission is permanently denied.\nOpen settings to enable it.',
          actionText: 'Open Settings',
          onAction: openAppSettings,
        );
      case _PermPhase.granted:
        if (!_showScanner) {
          // When modal is up, hide preview
          return Container(
            color: Theme.of(context).colorScheme.surface,
            alignment: Alignment.center,
            child: Text(
              'Scanning paused',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          );
        }
        return MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          fit: BoxFit.cover,
        );
    }
  }
}

// Simple permission UI
class _PermissionPane extends StatelessWidget {
  final String message;
  final String actionText;
  final Future<void> Function() onAction;

  const _PermissionPane({
    required this.message,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 36),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onAction, child: Text(actionText)),
        ],
      ),
    );
  }
}
