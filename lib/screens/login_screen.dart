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
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSignUp = false;
  String _selectedFareType = 'normal';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  Future<void> _handleUsernameAuth() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both username and password.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        // Show confirmation dialog before creating account
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Confirm Account Details', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please verify your information:', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                _confirmRow('Username', username),
                _confirmRow('Fare Type', _getFareLabel(_selectedFareType)),
                const SizedBox(height: 16),
                const Text('By clicking confirm, you agree that your commute savings will be calculated based on this profile.', 
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Edit', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );

        if (confirm != true) {
          setState(() => _isLoading = false);
          return;
        }

        final user = await _auth.signUp(username, password, fareType: _selectedFareType);
        if (user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!'), backgroundColor: Colors.green),
          );
          _navigateNext();
        }
      } else {
        final user = await _auth.signIn(username, password);
        if (user != null && mounted) {
          _navigateNext();
        }
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('Invalid login credentials')) msg = 'Incorrect username or password.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.split(']').last.trim())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await _auth.signInWithGoogle();
      if (user != null && mounted) {
        _navigateNext();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Auth failed: ${e.toString().split(']').last.trim()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B3E),
      body: Stack(
        children: [
          // 1. MAIN CONTENT
          SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  Hero(
                    tag: 'app_logo',
                    child: Image.asset('assets/image/TaraTrain_Logo.png', height: 140),
                  ),
                  const SizedBox(height: 40),
                  
                  Text(
                    _isSignUp ? 'Create New Account' : 'Welcome Back',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp ? 'Join the community of savvy commuters.' : 'Sign in to access your saved routes.',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 32),

                  // Username Field
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 24),

                  if (_isSignUp) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select Fare Profile',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFareOption(
                      id: 'normal',
                      label: 'Normal Fare',
                      subtitle: 'Standard single-journey pricing',
                      icon: Icons.payments_outlined,
                    ),
                    _buildFareOption(
                      id: 'beep',
                      label: 'Beep Card Holder',
                      subtitle: 'Stored value (20% Savings)',
                      icon: Icons.credit_card,
                    ),
                    _buildFareOption(
                      id: 'white_beep',
                      label: 'White Beep Card',
                      subtitle: 'Seniors / PWD / Student (50% Off)',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.orange)
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0D1B3E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _handleUsernameAuth,
                            child: Text(
                              _isSignUp ? 'Create Account' : 'Sign In',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.white12)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                            ),
                            const Expanded(child: Divider(color: Colors.white12)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            icon: Image.asset('assets/image/google_logo.png', height: 20, errorBuilder: (c,e,s) => const Icon(Icons.g_mobiledata, color: Colors.white)),
                            label: const Text('Continue with Google'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _handleGoogleSignIn,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignUp ? 'Already have an account?' : 'Don\'t have an account?',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            TextButton(
                              onPressed: () => setState(() => _isSignUp = !_isSignUp),
                              child: Text(
                                _isSignUp ? 'Sign In' : 'Sign Up',
                                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // 2. BACK BUTTON (Exit strategy)
          Positioned(
            top: 50,
            left: 20,
            child: InkWell(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  // If we can't pop (e.g. after sign out), go to map as guest
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                  );
                }
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white54, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFareOption({
    required String id,
    required String label,
    required String subtitle,
    required IconData icon,
  }) {
    final bool isSelected = _selectedFareType == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedFareType = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.orange : Colors.white54, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.orange : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.orange, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getFareLabel(String id) {
    switch (id) {
      case 'beep': return 'Beep Card (20%)';
      case 'white_beep': return 'White Beep (50%)';
      default: return 'Normal Fare';
    }
  }
}
