import 'package:flutter/material.dart';
import '../services/auth_service.dart';

import '../services/settings_service.dart';
import 'onboarding_screen.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final SettingsService _settings = SettingsService();
  bool _isLoading = false;

  void _navigateNext() {
    if (_settings.hasCompletedOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await _auth.signInWithGoogle();
      if (user == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in cancelled by user.')),
        );
      } else if (mounted) {
        _navigateNext();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: ${e.toString().split(']').last.trim()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestSignIn() async {
    final TextEditingController nameController = TextEditingController();
    final String? username = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1B3E),
          title: const Text('Enter Username', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g. Juan De La Cruz',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Skip', style: TextStyle(color: Colors.white54)),
              onPressed: () {
                Navigator.of(context).pop('Guest Commuter');
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0D1B3E),
              ),
              child: const Text('Continue'),
              onPressed: () {
                Navigator.of(context).pop(nameController.text.trim().isEmpty 
                    ? 'Guest Commuter' 
                    : nameController.text.trim());
              },
            ),
          ],
        );
      },
    );

    if (username == null) return;

    setState(() => _isLoading = true);
    try {
      final user = await _auth.signInAnonymously(username: username);
      if (user != null && mounted) {
        _navigateNext();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guest Sign-In Error: ${e.toString().split(']').last.trim()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF0D1B3E), // Midnight Navy Blue
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            
            // The Official Branded Logo Image
            Image.asset(
              'assets/image/TaraTrain_Logo.png',
              height: 220,
              width: 220,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.train,
                color: Colors.white,
                size: 100,
              ),
            ),
            
            const Spacer(flex: 2),
            
            // Login Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const Text(
                    'Welcome to Tara Tren',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sign in to sync your favorite stations.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0D1B3E),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: _handleSignIn,
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _handleGuestSignIn,
                    child: const Text('Continue as Guest', style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
