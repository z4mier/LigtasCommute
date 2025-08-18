import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsPrivacyScreen extends StatefulWidget {
  final String email;
  final VoidCallback onAccepted;

  const TermsPrivacyScreen({
    super.key,
    required this.email,
    required this.onAccepted,
  });

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen> {
  final PageController _page = PageController();
  bool accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Text("LigtasCommute Terms and Privacy Policy",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _page,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _PageWrap(
                        title: "LigtasCommute Terms and Privacy Policy",
                        child: _PageOneContent(),
                        trailing: Text("Next",
                            style: GoogleFonts.poppins(color: Colors.white)),
                        onTrailingPressed: () => _page.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        ),
                      ),
                      _PageWrap(
                        title: "LigtasCommute Terms and Privacy Policy",
                        child: _PageTwoContent(),
                        bottom: Row(
                          children: [
                            Checkbox(
                              value: accepted,
                              onChanged: (v) => setState(() => accepted = v ?? false),
                              side: const BorderSide(color: Colors.white70),
                              checkColor: Colors.white,
                              activeColor: const Color(0xFF0D658B),
                            ),
                            Expanded(
                              child: Text(
                                "I have read and accept the Terms and Privacy Policy.",
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        trailing: Text("OK",
                            style: GoogleFonts.poppins(
                                color: accepted ? Colors.white : Colors.white30)),
                        onTrailingPressed: accepted ? widget.onAccepted : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageWrap extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? bottom;
  final Widget? trailing;
  final VoidCallback? onTrailingPressed;

  const _PageWrap({
    required this.title,
    required this.child,
    this.bottom,
    this.trailing,
    this.onTrailingPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Last Updated: June 17, 2025",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 8),
              child: child,
            ),
          ),

          if (bottom != null) ...[
            const SizedBox(height: 8),
            bottom!,
          ],

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                backgroundColor: const Color(0xFF0D658B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onTrailingPressed,
              child: trailing ?? const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageOneContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final st = GoogleFonts.poppins(color: Colors.white70, height: 1.5);
    final sb = GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Welcome to LigtasCommute! By using this app, you agree to the following terms and conditions. "
             "Please read them carefully before using our services.\n", style: st),
        Text("1. Acceptance of Terms", style: sb),
        Text(
            "By accessing or using LigtasCommute, you acknowledge that you have read, "
            "understood, and agree to these Terms and Conditions.", style: st),
        const SizedBox(height: 10),
        Text("2. User Registration", style: sb),
        Text("Provide accurate info and keep it updated. You’re responsible for keeping your login details secure.",
            style: st),
        const SizedBox(height: 10),
        Text("3. Location and GPS Use", style: sb),
        Text(
            "We use GPS and mobile data to track your trip and send alerts. By using the app, you allow location access. "
            "If offline, your last known location may be sent via SMS for safety alerts.", style: st),
        const SizedBox(height: 10),
        Text("4. QR Code Verification", style: sb),
        Text("Scan the vehicle’s QR code before boarding. Confirm the driver and vehicle match in person.", style: st),
      ],
    );
  }
}

class _PageTwoContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final st = GoogleFonts.poppins(color: Colors.white70, height: 1.5);
    final sb = GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("5. Safety & Emergency Features", style: sb),
        Text(
            "Use the emergency alert function only when you feel unsafe. Misuse may result in account suspension.", style: st),
        const SizedBox(height: 10),
        Text("6. Feedback & Reports", style: sb),
        Text("Submit respectful, honest feedback only. Avoid false or harmful reports.", style: st),
        const SizedBox(height: 10),
        Text("7. Privacy Policy", style: sb),
        Text(
            "We collect your name, contact number, GPS data, trip activity, and feedback to operate the app. "
            "Your data is stored securely and not shared with advertisers. You may request to update or delete your data.",
            style: st),
        const SizedBox(height: 10),
        Text("8. Changes to Terms", style: sb),
        Text("We may revise these terms anytime. Continued use after updates means you accept the new terms.", style: st),
      ],
    );
  }
}
