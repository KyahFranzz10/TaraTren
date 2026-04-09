import 'package:flutter/material.dart';

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About the Developer'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.redAccent,
              backgroundImage: AssetImage('assets/image/meh.jpg'),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Jhon Francis Garapan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const Text(
            'LRT & MRT Daily Commuter',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'A Labor of Love',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'TaraTren was born out of frustration and hope. As a daily commuter in Manila—especially frequenting the LRT-1 and LRT-2 lines—I saw a need for a transit app that actually works the way we travel.',
                  style: TextStyle(fontSize: 15, height: 1.6),
                ),
                SizedBox(height: 12),
                Text(
                  'I built this app to help fellow Filipinos navigate our complex rail system with better dignity, smarter alerts, and a premium interface that we truly deserve. Thank you for making TaraTren part of your daily journey.',
                  style: TextStyle(fontSize: 15, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            '"Para sa bawat Pilipinong Commuter."',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.blueGrey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
