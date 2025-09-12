import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'settings_screen.dart';
import 'qr_screen.dart';
import '../services/my_settings_actions.dart';

class HomeScreen extends StatefulWidget {
  final MySettingsActions actions; // reuse the ONE shared instance
  const HomeScreen({super.key, required this.actions});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 0: Home, 1: QR, 2: Settings

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(
        onRateRide: () => _openRateRideDialog(context),
        onReportIncident: () => _openReportIncidentDialog(context),
      ),
      const SizedBox.shrink(), // QR handled by overlay/popup, this spot stays empty
      SettingsScreen(actions: widget.actions), // same instance
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.directions_bus, color: Colors.black87),
            const SizedBox(width: 8),
            Text(
              "LigtasCommute",
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications_none, color: Colors.black54),
          )
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) async {
          // QR tab
          if (i == 1) {
            final status = await Permission.camera.request();
            final isMobile =
                Theme.of(context).platform == TargetPlatform.android ||
                    Theme.of(context).platform == TargetPlatform.iOS;

            if (isMobile && !status.isGranted) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera permission is required.')),
                );
              }
              if (status.isPermanentlyDenied) openAppSettings();
              return;
            }

            final scanned = await Navigator.of(context).push<String>(
              PageRouteBuilder(
                opaque: false,
                barrierDismissible: true,
                pageBuilder: (_, __, ___) => const QRScreen(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            );

            if (!mounted) return;
            if (scanned != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Scanned: $scanned')));
            }
            return; // don't switch tabs
          }

          setState(() => _currentIndex = i);
        },
        backgroundColor: const Color(0xFFF2F2F2),
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_2), label: "QR"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Settings"),
        ],
      ),
    );
  }

  // ----------- DIALOGS -----------

  Future<void> _openRateRideDialog(BuildContext outerContext) async {
    int driverRate = 0;
    int vehicleRate = 0;
    final commentsCtrl = TextEditingController();

    await showDialog(
      context: outerContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: StatefulBuilder(builder: (innerContext, setLocal) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rate_rounded, color: Color(0xFFFFC107)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Rate Your Ride",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Driver
                        Text("How was your driver?",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        _StarsRow(
                          value: driverRate,
                          onChanged: (v) => setLocal(() => driverRate = v),
                        ),
                        const SizedBox(height: 8),
                        const _RateLabels(),

                        const SizedBox(height: 16),

                        // Vehicle
                        Text("How was the vehicle?",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        _StarsRow(
                          value: vehicleRate,
                          onChanged: (v) => setLocal(() => vehicleRate = v),
                        ),
                        const SizedBox(height: 8),
                        const _RateLabels(),

                        const SizedBox(height: 16),

                        Text("Additional comments (optional)",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextField(
                            controller: commentsCtrl,
                            maxLines: 5,
                            style: GoogleFonts.poppins(fontSize: 13),
                            decoration: InputDecoration(
                              hintText:
                                  "Please provide details about the incident...",
                              hintStyle: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.black45),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              // Close the rating dialog using its own context
                              Navigator.of(dialogContext).pop();
                              // Show success using the OUTER page context
                              _showSuccessDialog(outerContext,
                                  title: "Thank you!",
                                  message:
                                      "Your rating has been successfully submitted");
                            },
                            child: Text("Submit Rating",
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Close (X)
                Positioned(
                  right: 6,
                  top: 6,
                  child: IconButton(
                    splashRadius: 18,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Future<void> _openReportIncidentDialog(BuildContext outerContext) async {
    final typeCtrl = TextEditingController();
    final whereCtrl = TextEditingController();
    final whatCtrl = TextEditingController();
    DateTime? pickedDate;
    TimeOfDay? pickedTime;

    String dateDisplay() {
      if (pickedDate == null) return "dd-mm-yyyy";
      final d = pickedDate!;
      return "${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}";
    }

    String timeDisplay() {
      if (pickedTime == null) return "--:-- --";
      final h = pickedTime!.hourOfPeriod.toString().padLeft(2, '0');
      final m = pickedTime!.minute.toString().padLeft(2, '0');
      final ampm = pickedTime!.period == DayPeriod.am ? "AM" : "PM";
      return "$h:$m $ampm";
    }

    await showDialog(
      context: outerContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: StatefulBuilder(builder: (innerContext, setLocal) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.report_gmailerrorred_outlined,
                                color: Color(0xFFE53935)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Report Incident",
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel("Type of incident"),
                        const SizedBox(height: 6),
                        _TextFieldBox(
                          controller: typeCtrl,
                          hint: "Please specify",
                        ),

                        const SizedBox(height: 12),
                        _FieldLabel("When did this happen?"),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _TapBox(
                                text: dateDisplay(),
                                icon: Icons.calendar_today_rounded,
                                onTap: () async {
                                  final now = DateTime.now();
                                  final d = await showDatePicker(
                                    context: dialogContext,
                                    initialDate: now,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(now.year + 2),
                                  );
                                  if (d != null) {
                                    setLocal(() => pickedDate = d);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _TapBox(
                                text: timeDisplay(),
                                icon: Icons.access_time_rounded,
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: dialogContext,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (t != null) setLocal(() => pickedTime = t);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        _FieldLabel("Where did this happen?"),
                        const SizedBox(height: 6),
                        _TextFieldBox(
                          controller: whereCtrl,
                          hint: "Enter location",
                        ),

                        const SizedBox(height: 12),
                        _FieldLabel("What happened?"),
                        const SizedBox(height: 6),
                        _MultilineBox(
                          controller: whatCtrl,
                          hint:
                              "Please provide details about the incident...",
                        ),

                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              // Close the report dialog using its own context
                              Navigator.of(dialogContext).pop();
                              // Show success using the OUTER page context
                              _showSuccessDialog(outerContext,
                                  title: "Thank you!",
                                  message:
                                      "Your report has been successfully submitted");
                            },
                            child: Text("Submit Report",
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  right: 6,
                  top: 6,
                  child: IconButton(
                    splashRadius: 18,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Future<void> _showSuccessDialog(
    BuildContext outerContext, {
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: outerContext,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Check icon in circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(width: 4, color: const Color(0xFF0F7AAE)),
                  ),
                  child: const Center(
                    child: Icon(Icons.check, size: 36, color: Color(0xFF0F7AAE)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7AAE),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    // IMPORTANT: pop using the dialog's own context
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text("OK", style: GoogleFonts.poppins()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// HOME TAB
// ──────────────────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final VoidCallback onRateRide;
  final VoidCallback onReportIncident;
  const _HomeTab({required this.onRateRide, required this.onReportIncident});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          _SectionCard(
            title: "Safety Insights",
            onViewAll: () {},
            child: Column(
              children: const [
                _InsightTile(text: ""),
                SizedBox(height: 8),
                _InsightTile(text: ""),
                SizedBox(height: 8),
                _InsightTile(text: ""),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: "Community",
            onViewAll: () {},
            headerActions: Row(
              children: [
                ElevatedButton(
                  onPressed: onRateRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black87,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text("Rate Your Ride",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onReportIncident,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text("Report Incident",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            child: Column(
              children: const [
                _CommunityItem(name: "", subtitle: "", stars: null),
                SizedBox(height: 8),
                _CommunityItem(name: "", subtitle: "", stars: null),
                SizedBox(height: 8),
                _CommunityIncidentTile(text: ""),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// REUSABLE UI
// ──────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  final Widget child;
  final Widget? headerActions;

  const _SectionCard({
    required this.title,
    required this.onViewAll,
    required this.child,
    this.headerActions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  title == "Safety Insights" ? Icons.shield_outlined : Icons.groups,
                  color: title == "Safety Insights"
                      ? const Color(0xFFF08C00)
                      : Colors.black87,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: Text("View All", style: GoogleFonts.poppins()),
                ),
              ],
            ),
            if (headerActions != null) ...[
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: headerActions!),
            ],
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String text;
  const _InsightTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
        ),
      ),
    );
  }
}

class _CommunityItem extends StatelessWidget {
  final String name;
  final String subtitle;
  final int? stars;

  const _CommunityItem({
    required this.name,
    required this.subtitle,
    required this.stars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
          if (stars != null)
            Row(
              children: [
                Text(stars.toString(),
                    style:
                        GoogleFonts.poppins(fontSize: 12, color: Colors.black87)),
                const SizedBox(width: 2),
                const Icon(Icons.star, size: 16, color: Color(0xFFFFC107)),
              ],
            ),
        ],
      ),
    );
  }
}

class _CommunityIncidentTile extends StatelessWidget {
  final String text;
  const _CommunityIncidentTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Small reusable pieces for dialogs
// ──────────────────────────────────────────────────────────────────────────────

class _StarsRow extends StatelessWidget {
  final int value; // 0..5
  final ValueChanged<int> onChanged;
  const _StarsRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final idx = i + 1;
        final filled = value >= idx;
        return IconButton(
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          onPressed: () => onChanged(idx),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: const Color(0xFFFFC107),
            size: 28,
          ),
        );
      }),
    );
  }
}

class _RateLabels extends StatelessWidget {
  final labels = const ["Very\nPoor", "Poor", "Average", "Good", "Excellent"];

  const _RateLabels({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: labels
          .map((t) => SizedBox(
                width: 48,
                child: Text(
                  t,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
                ),
              ))
          .toList(),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600));
  }
}

class _TextFieldBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _TextFieldBox({required this.controller, required this.hint, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black45),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _MultilineBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _MultilineBox({required this.controller, required this.hint, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller,
        maxLines: 5,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black45),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _TapBox extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const _TapBox({required this.text, required this.icon, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style:
                    GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
              ),
            ),
            Icon(icon, size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
