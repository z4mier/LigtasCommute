// lib/screens/settings_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ========= THEME CONSTANTS (no purple) =========
const kPrimaryDark = Color(0xFF0F172A); // dark navy
const kTextMain = Colors.black87;
const kBorderGray = Color(0xFFE5E7EB);
const kCardBg = Color(0xFFF8F8F8);
const kReqCardBg = Color(0xFF6B7280); // dark gray for requirement cards
const kAccentOrange = Color(0xFFFFC107);

ButtonStyle kPrimaryBtnStyle = ElevatedButton.styleFrom(
  backgroundColor: kPrimaryDark,
  foregroundColor: Colors.white,
  elevation: 0,
  minimumSize: const Size.fromHeight(44),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

ButtonStyle kOutlinedBtnStyle = OutlinedButton.styleFrom(
  side: const BorderSide(color: kPrimaryDark, width: 1.2),
  foregroundColor: kPrimaryDark,
  minimumSize: const Size.fromHeight(44),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

SnackBar kSnack(String msg) => SnackBar(
  content: Text(msg),
  backgroundColor: kPrimaryDark,
  behavior: SnackBarBehavior.floating,
);

InputDecoration kInput(String label) => InputDecoration(
  labelText: label,
  isDense: true,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  enabledBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: kBorderGray),
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
  focusedBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: kPrimaryDark),
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
);

/// =======================
/// Model
/// =======================
class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? location;
  final DateTime memberSince;
  final int points;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.memberSince,
    required this.points,
    this.phone,
    this.location,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) {
    final created = (j['created_at'] ?? j['member_since'] ?? '').toString();
    return AppUser(
      id: (j['id'] ?? j['user_id'] ?? '').toString(),
      fullName: (j['name'] ?? j['full_name'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      phone: (j['phone'] ?? j['mobile'] ?? '').toString().trim().isEmpty
          ? null
          : (j['phone'] ?? j['mobile']).toString(),
      location: (j['location'] ?? j['address'] ?? '').toString().trim().isEmpty
          ? null
          : (j['location'] ?? j['address']).toString(),
      memberSince: DateTime.tryParse(created) ?? DateTime(2025, 1, 1),
      points: j['points'] is int
          ? (j['points'] as int)
          : int.tryParse('${j['points'] ?? 0}') ?? 0,
    );
  }

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? location,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      memberSince: memberSince,
      points: points,
    );
  }
}

/// =======================
/// Backend contract
/// =======================
abstract class SettingsActions {
  Future<AppUser> loadMe();

  Future<AppUser> updateProfile({
    required String fullName,
    required String email,
    String? phone,
    String? location,
  });

  Future<void> updateUsername({
    required String currentUsername,
    required String newUsername,
  });

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> changeLanguage(String code); // "en", "tl", "ceb"
  Future<void> toggleDarkMode(bool enabled);
  Future<void> redeemRewards();
  Future<void> openTerms();
  Future<void> openHelp();
  Future<void> logout();
  bool get isDarkMode;
  String get languageCode;
}

/// =======================
/// Settings Screen
/// =======================
class SettingsScreen extends StatefulWidget {
  final SettingsActions actions;

  const SettingsScreen({super.key, required this.actions});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<AppUser> _me;
  late bool _dark;
  late String _lang;

  @override
  void initState() {
    super.initState();
    _me = widget.actions.loadMe();
    _dark = widget.actions.isDarkMode;
    _lang = widget.actions.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.poppins();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: textStyle.copyWith(
            color: kTextMain,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<AppUser>(
        future: _me,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return _ErrorRetry(
              message: 'Failed to load your profile.',
              onRetry: () => setState(() => _me = widget.actions.loadMe()),
            );
          }
          final user = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileBox(
                user: user,
                onTap: () async {
                  final updated = await showDialog<AppUser?>(
                    context: context,
                    barrierDismissible: true,
                    builder: (_) => _ProfileDialog(user: user, actions: widget.actions),
                  );
                  if (updated != null && mounted) {
                    setState(() => _me = Future.value(updated));
                  }
                },
              ),
              const SizedBox(height: 12),

              _SectionHeader(icon: Icons.public, title: 'Language'),
              _SectionCard(
                child: Column(
                  children: [
                    LangTile(
                      labelLeft: 'US',
                      label: 'English',
                      selected: _lang == 'en',
                      onTap: () => _setLang('en'),
                    ),
                    const SizedBox(height: 8),
                    LangTile(
                      labelLeft: 'PH',
                      label: 'Tagalog',
                      selected: _lang == 'tl',
                      onTap: () => _setLang('tl'),
                    ),
                    const SizedBox(height: 8),
                    LangTile(
                      labelLeft: 'PH',
                      label: 'Cebuano',
                      selected: _lang == 'ceb',
                      onTap: () => _setLang('ceb'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _SectionHeader(icon: Icons.wb_sunny_outlined, title: 'Appearance'),
              _SectionCard(
                child: ListTile(
                  title: Text('Dark Mode', style: textStyle.copyWith(fontWeight: FontWeight.w500)),
                  subtitle: Text('Switch to dark theme', style: textStyle.copyWith(fontSize: 12)),
                  trailing: Switch(
                    value: _dark,
                    onChanged: (v) async {
                      setState(() => _dark = v);
                      await widget.actions.toggleDarkMode(v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _SectionHeader(icon: Icons.emoji_events_outlined, title: 'Loyalty Rewards'),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Points',
                        style: textStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${user.points}',
                            style: textStyle.copyWith(
                                color: Colors.orange[800], fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        Text('points', style: textStyle.copyWith(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Earn points based on your ride', style: textStyle.copyWith(fontSize: 12)),
                    const SizedBox(height: 8),
                    _PointsBar(points: user.points, maxPoints: 100),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: kOutlinedBtnStyle,
                        onPressed: () async {
                          await widget.actions.redeemRewards();
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(kSnack('Redeem flow opened'));
                          }
                        },
                        child: const Text('Redeem Rewards'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _SectionCard(
                child: Column(
                  children: [
                    _LinkTile(label: 'Terms & Privacy', onTap: () async => widget.actions.openTerms()),
                    const Divider(height: 1),
                    _LinkTile(label: 'Help & Support', onTap: () async => widget.actions.openHelp()),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _SectionCard(
                child: ListTile(
                  title: Text('Logout',
                      style: textStyle.copyWith(color: Colors.red, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    await widget.actions.logout();
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _setLang(String code) async {
    if (_lang == code) return;
    setState(() => _lang = code);
    await widget.actions.changeLanguage(code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(kSnack('Language set to ${_langLabel(code)}'));
    }
  }

  String _langLabel(String code) =>
      code == 'en' ? 'English' : code == 'tl' ? 'Tagalog' : 'Cebuano';
}

/// =======================
/// Profile "one box"
/// =======================
class _ProfileBox extends StatelessWidget {
  final AppUser user;
  final VoidCallback onTap;
  const _ProfileBox({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.poppins();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, color: kTextMain),
                const SizedBox(width: 8),
                Text('Profile',
                    style: textStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
                const Spacer(),
                Text('Tap to view profile',
                    style: textStyle.copyWith(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _AvatarCircle(initials: _initials(user.fullName)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        overflow: TextOverflow.ellipsis,
                        style:
                            textStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Member since ${_formatMonthYear(user.memberSince)}',
                        style: textStyle.copyWith(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black45),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    String take(String s) => s.isNotEmpty ? s[0].toUpperCase() : '';
    if (parts.length == 1) return take(parts[0]);
    return take(parts.first) + take(parts.last);
  }

  static String _formatMonthYear(DateTime d) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

/// =======================
/// Dialogs
/// =======================
class _ProfileDialog extends StatefulWidget {
  final AppUser user;
  final SettingsActions actions;
  const _ProfileDialog({required this.user, required this.actions});

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late AppUser _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    final ts = GoogleFonts.poppins();
    return Dialog(
      backgroundColor: Colors.white, // white like first pic
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('Profile', style: ts.copyWith(fontWeight: FontWeight.w600, fontSize: 18)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 4),

              // Avatar + Name (NO email under avatar)
              CircleAvatar(
                radius: 40,
                backgroundColor: kPrimaryDark,
                child: Text(_initials(_user.fullName),
                    style: ts.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
              ),
              const SizedBox(height: 12),
              Text(_user.fullName, style: ts.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 14),

              // Personal Information card (white with border) – email inside
              Container(
                decoration: _cardDeco(),
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Personal Information',
                            style: ts.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () async {
                            final edited = await showDialog<AppUser?>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => _EditProfileDialog(user: _user, actions: widget.actions),
                            );
                            if (edited != null && mounted) setState(() => _user = edited);
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Email first row
                    _InfoRow(icon: Icons.email_outlined, text: _user.email),

                    if (_user.phone != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(icon: Icons.phone_outlined, text: _user.phone!),
                    ],
                    if (_user.location != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(icon: Icons.location_on_outlined, text: _user.location!),
                    ],
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: 'Member since ${_formatMonthYear(_user.memberSince)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Security section → Manage Password ONLY
              Container(
                width: double.infinity,
                decoration: _cardDeco(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Security', style: ts.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        style: kOutlinedBtnStyle.copyWith(
                          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(42)),
                        ),
                        onPressed: () async {
                          await showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => _PasswordOnlyDialog(actions: widget.actions),
                          );
                        },
                        child: const Text('Manage Password'),
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
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    String take(String s) => s.isNotEmpty ? s[0].toUpperCase() : '';
    if (parts.length == 1) return take(parts[0]);
    return take(parts.first) + take(parts.last);
  }

  // White card + light border
  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      );

  String _formatMonthYear(DateTime d) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kTextMain),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// --- Edit Profile dialog (unchanged) ---
class _EditProfileDialog extends StatefulWidget {
  final AppUser user;
  final SettingsActions actions;
  const _EditProfileDialog({required this.user, required this.actions});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _phone;
  late TextEditingController _location;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.fullName);
    _phone = TextEditingController(text: widget.user.phone ?? '');
    _location = TextEditingController(text: widget.user.location ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ts = GoogleFonts.poppins();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('Edit Profile',
                        style: ts.copyWith(fontWeight: FontWeight.w600, fontSize: 18)),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _saving ? null : () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 10),

                CircleAvatar(
                  radius: 40,
                  backgroundColor: kPrimaryDark,
                  child: Text(_initials(_name.text),
                      style: ts.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
                ),

                /// Plain email text (no box) under the avatar
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email_outlined, size: 16, color: kTextMain),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.user.email,
                        style: ts.copyWith(fontSize: 13.5, color: kTextMain),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Personal Information panel with Full Name first
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Personal Information',
                          style: ts.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _name,
                        decoration: kInput('Full Name'),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _phone,
                        decoration: kInput('Phone')
                            .copyWith(prefixIcon: const Icon(Icons.phone_outlined)),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _location,
                        decoration: kInput('Location').copyWith(
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: kPrimaryBtnStyle,
                        onPressed: _saving ? null : _save,
                        child: const Text('Save'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: kOutlinedBtnStyle,
                        onPressed: _saving ? null : () => Navigator.pop(context, null),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
                if (_saving) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 2),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.actions.updateProfile(
        fullName: _name.text.trim(),
        email: widget.user.email, // keep existing email unchanged
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      );
      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(kSnack('Failed to save: $e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    String take(String s) => s.isNotEmpty ? s[0].toUpperCase() : '';
    if (parts.length == 1) return take(parts[0]);
    return take(parts.first) + take(parts.last);
  }
}

/// (Kept for future use if you bring back username change)
class _UsernameOnlyDialog extends StatefulWidget {
  final SettingsActions actions;
  const _UsernameOnlyDialog({required this.actions});

  @override
  State<_UsernameOnlyDialog> createState() => _UsernameOnlyDialogState();
}

class _UsernameOnlyDialogState extends State<_UsernameOnlyDialog> {
  final _curUser = TextEditingController();
  final _newUser = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _curUser.dispose();
    _newUser.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ts = GoogleFonts.poppins();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('Update Username',
                      style: ts.copyWith(fontWeight: FontWeight.w600, fontSize: 18)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _busy ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: _paneDeco(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Change Username',
                        style: ts.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 10),
                    TextField(controller: _curUser, decoration: kInput('Current Username')),
                    const SizedBox(height: 10),
                    TextField(controller: _newUser, decoration: kInput('New Username')),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _ReqCard(
                title: 'Username Requirements:',
                lines: const ['At least 8 characters long', 'Letters, numbers, and underscores only'],
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: kPrimaryBtnStyle,
                onPressed: _busy ? null : _updateUsername,
                child: const Text('Update Username'),
              ),
              if (_busy) const Padding(
                padding: EdgeInsets.only(top: 10),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateUsername() async {
    final cur = _curUser.text.trim();
    final nxt = _newUser.text.trim();

    if (cur.isEmpty || nxt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(kSnack('Please fill both fields.'));
      return;
    }
    if (nxt.length < 8 || !RegExp(r'^[A-Za-z0-9_]+$').hasMatch(nxt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        kSnack('New username must be 8+ chars, letters/numbers/underscores only.'),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await widget.actions.updateUsername(currentUsername: cur, newUsername: nxt);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(kSnack('Username updated.'));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(kSnack('Failed to update username: $e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Password dialog (unchanged)
class _PasswordOnlyDialog extends StatefulWidget {
  final SettingsActions actions;
  const _PasswordOnlyDialog({required this.actions});

  @override
  State<_PasswordOnlyDialog> createState() => _PasswordOnlyDialogState();
}

class _PasswordOnlyDialogState extends State<_PasswordOnlyDialog> {
  final _curPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confPw = TextEditingController();

  bool _showNew = false, _showConf = false, _showCur = false;
  bool _busy = false;

  @override
  void dispose() {
    _curPw.dispose();
    _newPw.dispose();
    _confPw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ts = GoogleFonts.poppins();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('Change Password',
                      style: ts.copyWith(fontWeight: FontWeight.w600, fontSize: 18)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _busy ? null : () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: _paneDeco(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Update your password',
                        style: ts.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _curPw,
                      obscureText: !_showCur,
                      decoration: kInput('Enter your current password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_showCur ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _showCur = !_showCur),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _newPw,
                      obscureText: !_showNew,
                      decoration: kInput('Enter your new password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _showNew = !_showNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _confPw,
                      obscureText: !_showConf,
                      decoration: kInput('Confirm your new password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_showConf ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _showConf = !_showConf),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _ReqCard(
                title: 'Password Requirements:',
                lines: const ['At least 8 characters long', 'Mix of letters, numbers, and special characters'],
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: kPrimaryBtnStyle,
                onPressed: _busy ? null : _updatePassword,
                child: const Text('Update Password'),
              ),
              if (_busy) const Padding(
                padding: EdgeInsets.only(top: 10),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updatePassword() async {
    final cur = _curPw.text.trim();
    final nxt = _newPw.text.trim();
    final cfm = _confPw.text.trim();

    if (cur.isEmpty || nxt.isEmpty || cfm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(kSnack('Please complete all fields.'));
      return;
    }
    if (nxt.length < 8 ||
        !RegExp(r'^(?=.*[A-Za-z])(?=.*\d|.*[^A-Za-z0-9]).{8,}$').hasMatch(nxt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        kSnack('Password must be 8+ chars with letters and numbers/specials.'),
      );
      return;
    }
    if (nxt != cfm) {
      ScaffoldMessenger.of(context).showSnackBar(kSnack('Passwords do not match.'));
      return;
    }

    setState(() => _busy = true);
    try {
      await widget.actions.updatePassword(currentPassword: cur, newPassword: nxt);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(kSnack('Password updated.'));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(kSnack('Failed to update password: $e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// ===== Shared small widgets =====
BoxDecoration _paneDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorderGray),
    );

class _ReqCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _ReqCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    final ts = GoogleFonts.poppins();
    return Container(
      decoration: BoxDecoration(color: kReqCardBg, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ts.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 6),
          for (final l in lines)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(Icons.circle, size: 6, color: Colors.white)),
                const SizedBox(width: 8),
                Expanded(child: Text(l, style: ts.copyWith(color: Colors.white, height: 1.2))),
              ],
            )
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange[700]),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: kTextMain)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: child,
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String initials;
  const _AvatarCircle({required this.initials});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: kPrimaryDark,
      child: Text(initials,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}

/// Language option tile
class LangTile extends StatelessWidget {
  final String labelLeft;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const LangTile({
    required this.labelLeft,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.poppins();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? kPrimaryDark : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? Colors.white : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                labelLeft,
                style: style.copyWith(
                  color: selected ? Colors.black : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LinkTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: GoogleFonts.poppins(color: kTextMain)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black45),
      onTap: onTap,
    );
  }
}

class _PointsBar extends StatelessWidget {
  final int points;
  final int maxPoints;
  const _PointsBar({required this.points, this.maxPoints = 100});

  @override
  Widget build(BuildContext context) {
    final pct = (points.clamp(0, maxPoints)) / maxPoints;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 10,
        decoration:
            BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(999)),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: pct == 0 ? 0.02 : pct,
            child: Container(color: kAccentOrange),
          ),
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message, style: GoogleFonts.poppins(color: kTextMain)),
        const SizedBox(height: 8),
        OutlinedButton(style: kOutlinedBtnStyle, onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}
