import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About the Developer'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        children: [
          // Profile Section with themed ring
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.orange.withOpacity(0.5)
                      : Colors.indigo.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: const CircleAvatar(
                radius: 75,
                backgroundColor: Colors.redAccent,
                backgroundImage: AssetImage('assets/image/meh.jpg'),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Jhon Francis Garapan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            'IT Graduating Student \n Medyo Train Enthusiast',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.blueGrey,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 40),

          // Story Card with Glassmorphism
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.indigo.withOpacity(0.1)
                  : Colors.indigo.withOpacity(0.04),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark
                    ? Colors.indigo.withOpacity(0.2)
                    : Colors.indigo.withOpacity(0.1),
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: isDark ? Colors.orange : Colors.indigo,
                        size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Trip lang gumawa ng app pero sineryoso',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'TaraTren was born out of frustration and hope. As a daily commuter in Manila—especially frequenting the LRT-1 and LRT-2 lines—I saw a need for a transit app that actually works the way we travel.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'I built this app to help fellow Filipinos navigate our complex rail system with better dignity, smarter alerts, and a premium interface that we truly deserve.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Social/Contact Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialChip(
                context,
                "GitHub",
                () => _launchUrl("https://github.com/KyahFranzz10"),
                leading: Image.network(
                  'https://cdn-icons-png.flaticon.com/512/25/25231.png',
                  width: 16,
                  height: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              _buildSocialChip(
                context,
                "Email",
                () => _launchUrl("mailto:jhongarapan@gmail.com"),
                icon: Icons.alternate_email_rounded,
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Footer Quote
          Opacity(
            opacity: 0.8,
            child: Text(
              '"Para sa bawat Pilipinong Commuter."',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontFamily: 'serif',
                color: isDark ? Colors.orange.shade200 : Colors.indigo.shade800,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSocialChip(
      BuildContext context, String label, VoidCallback onTap,
      {IconData? icon, Widget? leading}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) leading,
            if (icon != null)
              Icon(icon,
                  size: 16, color: isDark ? Colors.white70 : Colors.black87),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87)),
          ],
        ),
      ),
    );
  }
}
