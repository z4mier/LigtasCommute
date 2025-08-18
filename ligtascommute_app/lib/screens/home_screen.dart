import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 0: Home, 1: QR, 2: Settings

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const _QrTab(),
      const _SettingsTab(),
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
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFFF2F2F2),
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_2),
            label: "QR",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          // Safety Insights Card
          _SectionCard(
            title: "Safety Insights",
            onViewAll: () {},
            child: Column(
              children: [
                _InsightTile(text: ""), // blank placeholders
                const SizedBox(height: 8),
                _InsightTile(text: ""),
                const SizedBox(height: 8),
                _InsightTile(text: ""),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Community Card
          _SectionCard(
            title: "Community",
            onViewAll: () {},
            headerActions: Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107), // yellow-ish
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text("Rate Your Ride", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935), // red-ish
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text("Report Incident", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            child: Column(
              children: [
                _CommunityItem(name: "", subtitle: "", stars: null),
                const SizedBox(height: 8),
                _CommunityItem(name: "", subtitle: "", stars: null),
                const SizedBox(height: 8),
                _CommunityIncidentTile(text: ""),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrTab extends StatelessWidget {
  const _QrTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("",
          style: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: 16,
          )),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("",
          style: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: 16,
          )),
    );
  }
}

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
                  color: title == "Safety Insights" ? const Color(0xFFF08C00) : Colors.black87,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
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
              Align(
                alignment: Alignment.centerLeft,
                child: headerActions!,
              ),
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
  final int? stars; // null → hide star

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
                Text(name, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
          if (stars != null) Row(
            children: [
              Text(stars.toString(), style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87)),
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
