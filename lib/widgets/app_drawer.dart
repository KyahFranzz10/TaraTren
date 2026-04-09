import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/navigation_controller.dart';
import '../screens/login_screen.dart';
import '../screens/fare_calculator_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/future_lines_screen.dart';
import '../screens/trip_journal_screen.dart';
import '../screens/changelog_screen.dart';
import '../screens/savings_comparison_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // 1. Drawer Header (Live User Info)
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.userChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1B3E),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.green, size: 40) : null,
                ),
                accountName: Text(
                  user?.displayName?.isNotEmpty == true
                      ? user!.displayName!
                      : 'Guest Commuter', 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
                accountEmail: Text(user?.email ?? 'Happy Commuting!'),
              );
            }
          ),
          
          // 2. Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(
                  context, 
                  Icons.home, 
                  'Home', 
                  onTap: () {
                    NavigationController().setTab(0);
                    Navigator.pop(context);
                  }
                ),
                
                 _drawerItem(
                  context, 
                  Icons.map_outlined, 
                  'Future Manila Network', 
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const FutureLinesScreen()));
                  }
                ),


                 _drawerItem(
                  context, 
                  Icons.payments_outlined, 
                  'Fare Calculator', 
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const FareCalculatorScreen()));
                  }
                ),

                 _drawerItem(
                  context, 
                  Icons.savings_outlined, 
                  'Savings Comparison', 
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SavingsComparisonScreen()));
                  }
                ),

                _drawerItem(
                  context, 
                  Icons.history_edu, 
                  'Digital Trip Journal', 
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TripJournalScreen()));
                  }
                ),

                const Divider(),
                _drawerItem(
                  context, 
                  Icons.settings_outlined, 
                  'Settings', 
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  }
                ),
                _drawerItem(
                  context, 
                  Icons.feedback_outlined, 
                  'Feedback', 
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackScreen()));
                  }
                ),
                
                const Divider(),
                _drawerItem(
                  context, 
                  Icons.logout, 
                  'Sign Out', 
                  onTap: () async {
                    // Show confirmation dialog before signing out
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out from TaraTren?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (context.mounted) Navigator.pop(context); // Close drawer
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    }
                  }
                ),
              ],
            ),
          ),
          
          // 3. Footer — tap to view changelog
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangelogScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 13, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text('V0.2.1-Alpha', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Text('· What\'s New', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0D1B3E)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
