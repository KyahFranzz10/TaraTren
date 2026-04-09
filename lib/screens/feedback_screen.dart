import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;

  // 📝 INSTRUCTIONS:
  // 1. Deploy a Google Apps Script as a "Web App" (Access: Anyone).
  // 2. Paste your Web App URL below:
  static const String _scriptUrl =
      'https://script.google.com/macros/s/AKfycbzjDbVotMeRABi4HNqAt5WnEInxGLGiAjwrcSTuSLfkjUd06fX4sLqX2WLMcwitOi2A/exec';

  Future<void> _submitFeedback() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your feedback.')));
      return;
    }

    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;
    final String version = '0.1.23+24';
    final String providedEmail = _emailController.text.trim();
    final String senderLabel = user?.email ?? (providedEmail.isNotEmpty ? providedEmail : 'Guest Commuter');

    try {
      // 1. Silent Log to Firestore (Spark/Free Plan compatible)
      await FirebaseFirestore.instance.collection('feedback').add({
        'content': text,
        'userEmail': senderLabel,
        'userName': user?.displayName ?? 'N/A',
        'userId': user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}',
        'authProvider': user?.providerData.isNotEmpty == true ? user!.providerData[0].providerId : 'None',
        'createdAt': FieldValue.serverTimestamp(),
        'appName': 'TaraTren',
        'version': version,
      });

      // 2. Silent Email via Google Apps Script (Bypasses Blaze Paywall)
      final String mailBody = "Feedback from: $senderLabel\n"
          "Display Name: ${user?.displayName ?? 'N/A'}\n"
          "User UID: ${user?.uid ?? 'Guest'}\n"
          "App Version: $version\n\n"
          "User Feedback:\n$text";

      try {
        await http
            .post(
              Uri.parse(_scriptUrl),
              body: jsonEncode({
                'to': 'jhongarapan@gmail.com',
                'subject': '🆕 TaraTren App Feedback ($version)',
                'body': mailBody,
              }),
            )
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint("Silent Script Error: $e");
      }

      if (mounted) {
        _controller.clear();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.mark_email_read_rounded, color: Colors.green),
                SizedBox(width: 10),
                Text('Feedback Received'),
              ],
            ),
            content: const Text(
                'Thank you! Your message has been sent directly to our development team. We read every report to improve TaraTren.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help us improve Tara Tren',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B3E)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Share your experience, report a bug, or suggest a feature. We read every message!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (FirebaseAuth.instance.currentUser?.email == null) ...[
              const Text('Email Address (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'e.g. commuter@email.com',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              const Text('Sending Feedback as:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null 
                        ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!) 
                        : null,
                      child: FirebaseAuth.instance.currentUser?.photoURL == null 
                        ? const Icon(Icons.person, size: 16, color: Colors.blue) 
                        : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            FirebaseAuth.instance.currentUser?.displayName ?? 'TaraTren Commuter',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            FirebaseAuth.instance.currentUser?.email ?? '',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Text('Your Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Enter your feedback here...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1B3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                onPressed: _isSubmitting ? null : _submitFeedback,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Feedback',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: [
                    Icon(Icons.commute, size: 40, color: Colors.grey),
                    SizedBox(height: 10),
                    Text('Safe travels, Metro Manila Commuter!',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
