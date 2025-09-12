// lib/screens/signup_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:ligtascommute_app/api_config.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // === THEME (match Login) ===
  static const _aqua = Color(0xFF22D3EE);     // light aqua/cyan accent
  static const _aquaOverlay = Color(0x2622D3EE);
  static const _darkNavyBg = Color(0xFF111827);
  static const _headerTeal = Color(0xFF0D658B);

  Map<String, dynamic> _safeDecode(String body) {
    try {
      final v = jsonDecode(body);
      return v is Map<String, dynamic> ? v : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String? _firstValidationError(Map<String, dynamic> data) {
    if (data['errors'] is Map) {
      final errs = data['errors'] as Map;
      if (errs.isNotEmpty) {
        final firstVal = errs.values.first;
        if (firstVal is List && firstVal.isNotEmpty) {
          return firstVal.first.toString();
        }
        return firstVal.toString();
      }
    }
    return null;
  }

  Future<void> signupUser() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 8 characters")),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}register'),
        headers: const {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "name": fullName,
          "email": email,
          "phone": phone,
          "password": password,
        }),
      );

      if (!mounted) return;

      final data = _safeDecode(res.body);
      debugPrint('signup status: ${res.statusCode}');
      debugPrint('signup body  : ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"]?.toString() ??
                  "Account created! Please verify your email.",
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              email: email,
              showTermsAfterVerify: true,
            ),
          ),
        );
        return;
      }

      final firstErr = _firstValidationError(data);
      if (firstErr != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(firstErr)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"]?.toString() ?? "Signup failed (${res.statusCode})",
            ),
          ),
        );
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
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // === InputDecoration WITHOUT floating labels (same as Login) ===
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.black45, fontSize: 13.5),
      // no labelText → no floating label
      prefixIcon: Icon(icon, color: Colors.black54),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _aqua, width: 1.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkNavyBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header (same family as Login)
            Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _headerTeal,
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
                    "Join LigtasCommute",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Create your account to start safe commuting",
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Title (match Login style)
            Text(
              "Create Account",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _LabeledField(
                    label: "Full Name",
                    child: TextField(
                      controller: fullNameController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: "Enter your full name",
                        icon: Icons.person_outline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _LabeledField(
                    label: "Email",
                    child: TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: "Enter your email",
                        icon: Icons.email_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _LabeledField(
                    label: "Phone Number",
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: "Enter your phone number",
                        icon: Icons.phone_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _LabeledField(
                    label: "Password",
                    child: TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: "Create password",
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.black54,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _LabeledField(
                    label: "Confirm Password",
                    child: TextField(
                      controller: confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: "Confirm your password",
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black54,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword = !_obscureConfirmPassword,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Create Account
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _headerTeal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(double.infinity, 50),
                      elevation: 0,
                    ).copyWith(
                      overlayColor: const WidgetStatePropertyAll(_aquaOverlay),
                    ),
                    onPressed: isLoading ? null : signupUser,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Create Account",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Already have an account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      AuthLink(
                        text: "Sign in",
                        onTap: () {
                          // Named route to match your MaterialApp routes
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                    ],
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

/// Label above a field (white), no floating label
class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final Color labelColor;
  const _LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.labelColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// Bold aqua link with hover underline (same as Login’s Sign up)
class AuthLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const AuthLink({super.key, required this.text, required this.onTap});

  @override
  State<AuthLink> createState() => _AuthLinkState();
}

class _AuthLinkState extends State<AuthLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.poppins(
      color: _SignupScreenState._aqua,
      fontWeight: FontWeight.w700,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 120),
          style: base.copyWith(
            decoration: _hovering ? TextDecoration.underline : TextDecoration.none,
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}
