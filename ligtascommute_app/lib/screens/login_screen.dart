import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'otp_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'package:ligtascommute_app/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool isResetLoading = false;
  bool _obscurePassword = true;

  // ---- helpers --------------------------------------------------------------

  Map<String, dynamic> _safeMap(String body) {
    try {
      final v = jsonDecode(body);
      if (v is Map<String, dynamic>) return v;
      return {};
    } catch (_) {
      return {};
    }
  }

  bool _isVerifiedFromResponse(Map<String, dynamic> data) {
    // { user: { is_verified: true/1 } } or { user: { email_verified_at: "..." } }
    final user = (data['user'] is Map) ? data['user'] as Map : null;
    if (user != null) {
      if (user['is_verified'] == true || user['is_verified'] == 1) return true;
      if (user['email_verified_at'] != null &&
          user['email_verified_at'].toString().isNotEmpty) return true;
    }

    // flat shapes
    if (data['is_verified'] == true || data['is_verified'] == 1) return true;
    if (data['email_verified_at'] != null &&
        data['email_verified_at'].toString().isNotEmpty) return true;

    // { data: { user: {...} } }
    final innerData = (data['data'] is Map) ? data['data'] as Map : null;
    final innerUser = (innerData?['user'] is Map) ? innerData!['user'] as Map : null;
    if (innerUser != null) {
      if (innerUser['is_verified'] == true || innerUser['is_verified'] == 1) return true;
      if (innerUser['email_verified_at'] != null &&
          innerUser['email_verified_at'].toString().isNotEmpty) return true;
    }
    return false;
  }

  // ---- actions --------------------------------------------------------------

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}login'),
        headers: const {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": email, "password": password}),
      );

      final contentType = res.headers['content-type'] ?? '';
      final isJson = contentType.contains('application/json');
      final data = isJson ? _safeMap(res.body) : <String, dynamic>{};

      if (res.statusCode == 200) {
        // a) backend explicitly tells us to verify
        if (data['requires_verification'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
          );
          return;
        }

        // b) infer from payload
        final verified =
            _isVerifiedFromResponse(data) ||
            (() {
              final u = data['user'];
              return u is Map && (u['is_verified'] == 1 || u['is_verified'] == true);
            }());

        if (verified) {
          // Optionally store token: final token = data['token']?.toString();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Logged in successfully")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          return;
        }

        // c) fallback → treat as unverified
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
        );
        return;
      }

      // Non-200
      final msg = data['message']?.toString();
      final preview = isJson
          ? (msg ?? 'Login failed')
          : 'HTTP ${res.statusCode} ${res.reasonPhrase}\n'
            '${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(preview)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _openForgotPasswordDialog() async {
    final TextEditingController forgotEmailController =
        TextEditingController(text: emailController.text.trim());

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1F2937),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              "Reset Password",
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Enter your account email. We’ll send a reset link or OTP to continue.",
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: forgotEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "you@example.com",
                    labelText: "Email Address",
                    labelStyle: GoogleFonts.poppins(color: Colors.black87),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.black54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D658B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isResetLoading
                    ? null
                    : () async {
                        final email = forgotEmailController.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please enter your email")),
                          );
                          return;
                        }
                        setLocal(() => isResetLoading = true);
                        await _requestPasswordReset(email);
                        if (context.mounted) {
                          setLocal(() => isResetLoading = false);
                          Navigator.pop(ctx);
                        }
                      },
                child: isResetLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text("Send reset", style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}forgot-password'),
        headers: const {"Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final data = _safeMap(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"]?.toString() ?? "Reset link sent. Please check your email.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"]?.toString() ?? "Could not start password reset")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  // ---- UI helpers -----------------------------------------------------------

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.black87),
      prefixIcon: Icon(icon, color: Colors.black54),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top header
            Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0D658B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(150),
                  bottomRight: Radius.circular(150),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_bus, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    "LigtasCommute",
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    "Safety that rides with you",
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Title
            Text(
              "Login",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 30),

            // Inputs + Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: emailController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      label: "Email Address",
                      hint: "Enter your email",
                      icon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: _inputDecoration(
                      label: "Password",
                      hint: "Enter your password",
                      icon: Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black54,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _openForgotPasswordDialog,
                      child: Text(
                        "Forgot password?",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D658B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: isLoading ? null : loginUser,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Sign in",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                    child: Text.rich(
                      TextSpan(
                        text: "Don’t have an account? ",
                        style: GoogleFonts.poppins(color: Colors.white),
                        children: [
                          TextSpan(
                            text: "Sign up",
                            style: GoogleFonts.poppins(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
