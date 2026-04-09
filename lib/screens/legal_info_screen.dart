import 'package:flutter/material.dart';

class LegalInfoScreen extends StatelessWidget {
  const LegalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal & Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildLegalSection(
            title: 'Privacy Policy (DPA 2012)',
            content: 'TaraTren is committed to protecting your privacy in compliance with the Data Privacy Act of 2012 (RA 10173).\n\n'
                '• Collection: We collect your precise GPS location data while the app is in the foreground and background.\n'
                '• Purpose: This data is used solely to provide station arrival notifications, real-time trip tracking, and to improve community-sourced train status.\n'
                '• Storage: Your raw location data is processed on-device. Anonymized speed/position data may be shared with our real-time database to help other commuters see live train positions.\n'
                '• Consent: By enabling location services, you consent to this collection for transit navigation purposes.',
            icon: Icons.privacy_tip,
            color: Colors.indigo,
          ),
          const Divider(height: 32),
          _buildLegalSection(
            title: 'Disclaimer of Liability',
            content: 'TaraTren is provided "as is" for informational and community-driven purposes only.\n\n'
                '• Accuracy: Train positions, schedules, and fare data may be simulated or provided by other users. We do not guarantee 100% accuracy.\n'
                '• Responsibility: The developer is not liable for any missed connections, delays, or issues resulting from the use of this application.\n'
                '• Reliability: Manila transit is unpredictable. Always listen to official station announcements and follow local transit personnel.',
            icon: Icons.warning_rounded,
            color: Colors.orange,
          ),
          const Divider(height: 32),
          _buildLegalSection(
            title: 'Non-Affiliation Disclaimer',
            content: 'TaraTren is an independent, community-driven mobile application.\n\n'
                '• No Official Status: This project is not affiliated with, endorsed by, or sponsored by the Department of Transportation (DOTr), LRTA, LRMC, MRTC, or PNR.\n'
                '• Trademarks: All transit line names (LRT-1, LRT-2, MRT-3, PNR) and logos are property of their respective owners and are used here for identification and informational purposes only.',
            icon: Icons.info_outline,
            color: Colors.blueGrey,
          ),
          const Divider(height: 32),
          _buildLegalSection(
            title: 'Mapping & Data Credits',
            content: '• Map Interface: Powered by Leaflet/flutter_map.\n'
                '• Imagery: © OpenStreetMap, © CARTO, and ESRI World Imagery (Maxar, Earthstar Geographics).\n'
                '• Transit Data: Community-sourced and Open GTFS Manila datasets.',
            icon: Icons.map,
            color: Colors.green,
          ),
          const SizedBox(height: 40),
          const Center(
            child: Text(
              'TaraTren v0.2.1-Alpha\nOfficial Legal & Privacy Documentation',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLegalSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
