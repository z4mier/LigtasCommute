import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligtascommute_app/api_config.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  /// If true, OTP is auto-sent on screen open.
  /// Use `false` for SIGNUP (backend usually already sent one).
  /// Use `true` for LOGIN if you want auto-send.
  final bool autoSend;

  /// (kept for API compatibility; no longer used to show Terms here)
  final bool showTermsAfterVerify;

  const OtpScreen({
    super.key,
    required this.email,
    this.autoSend = false, // <— default OFF to avoid double OTP on sign up
    this.showTermsAfterVerify = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;
  bool isSendingOtp = false;

  // resend cooldown
  static const int _cooldownSeconds = 30;
  int _secondsLeft = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Only auto-send if explicitly requested (e.g., login flow).
    if (widget.autoSend) {
      WidgetsBinding.instance.addPostFrameCallback((_) => sendOtp());
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  void _startCooldown([int? fromServer]) {
    _cooldownTimer?.cancel();
    _secondsLeft =
        fromServer != null && fromServer > 0 ? fromServer : _cooldownSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> sendOtp() async {
    // Guard against duplicates:
    if (isSendingOtp) return;        // <- single-flight guard
    if (_secondsLeft > 0) return;    // <- still cooling down

    setState(() => isSendingOtp = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}send-otp"),
        headers: const {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": widget.email}),
      );

      if (!mounted) return;

      final data = _safeDecode(response.body);

      if (response.statusCode == 200) {
        final cooldownLeft = (data["cooldown_left"] is num)
            ? (data["cooldown_left"] as num).toInt()
            : null;
        _startCooldown(cooldownLeft);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  data["message"]?.toString() ?? "OTP sent successfully!")),
        );
      } else {
        final message = data["message"]?.toString() ?? "Failed to send OTP";
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        if (message.toLowerCase().contains("please wait")) {
          _startCooldown();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error sending OTP: $e")));
    } finally {
      if (mounted) setState(() => isSendingOtp = false);
    }
  }

  Map<String, dynamic> _safeDecode(String body) {
    try {
      final v = jsonDecode(body);
      return v is Map<String, dynamic> ? v : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> verifyOtp() async {
    final otpCode = otpController.text.trim();

    if (otpCode.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter OTP")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}verify-otp"),
        headers: const {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": widget.email,
          "otp": otpCode,
          // IMPORTANT: do NOT auto-login after verify
          "login_after_verify": false,
        }),
      );

      if (!mounted) return;

      final data = _safeDecode(response.body);

      if (response.statusCode == 200) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (r) => false,
          arguments: {
            'verifiedMsg': true,
            'email': widget.email,
          },
        );
      } else {
        final message = data["message"]?.toString() ?? "Invalid OTP";
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = !isSendingOtp && _secondsLeft == 0;

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
                child: Icon(Icons.email, size: 60, color: Color(0xFF0D658B))),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "Verify Your Email",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                "Enter the OTP sent to ${widget.email}",
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                counterText: '',
                labelText: "Enter OTP",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D658B),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify OTP",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: canResend ? sendOtp : null,
                child: Text(
                  isSendingOtp
                      ? "Sending..."
                      : (_secondsLeft > 0
                          ? "Resend in ${_secondsLeft}s"
                          : "Resend OTP"),
                  style: const TextStyle(color: Colors.blueAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
