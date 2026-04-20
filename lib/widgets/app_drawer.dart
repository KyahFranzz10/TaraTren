import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import '../screens/route_planner_screen.dart';
import '../screens/saved_routes_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // 1. Drawer Header (Live User Info)
          StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              final user = snapshot.data?.session?.user ?? Supabase.instance.client.auth.currentUser;
              final displayName = user?.userMetadata?['display_name'] ?? user?.userMetadata?['name'];
              final photoUrl = user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['picture'];
              final bool isGuest = user == null || user.isAnonymous;

              Widget header = UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.8 : 1.0),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? const Icon(Icons.person, color: Colors.green, size: 40) : null,
                ),
                accountName: Text(
                  displayName?.isNotEmpty == true
                      ? displayName!
                      : 'Sign In?', 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
                accountEmail: Text(user?.email ?? 'Save your favorite routes'),
              );

              if (isGuest) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                  },
                  child: header,
                );
              }
              return header;
            }
          ),
          
          // 2. Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _sectionHeader(context, 'EXPLORE & NAVIGATE'),
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
                  Icons.route_rounded, 
                  'Route Planner', 
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RoutePlannerScreen()));
                  }
                ),
                 _drawerItem(
                  context, 
                  Icons.bookmarks_outlined, 
                  'Saved Routes', 
                  isLocked: AuthService().isGuest,
                  onTap: () {
                    if (AuthService().isGuest) {
                      _showAccountRequiredDialog(context, "Saved Routes", "Save your frequent paths for quick offline access.");
                    } else {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedRoutesScreen()));
                    }
                  }
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1),
                ),
                _sectionHeader(context, 'COMMUTER TOOLS'),


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
                  isLocked: AuthService().isGuest,
                  onTap: () {
                    if (AuthService().isGuest) {
                      _showAccountRequiredDialog(context, "Digital Trip Journal", "Automatically track your travel history and view your commute statistics.");
                    } else {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TripJournalScreen()));
                    }
                  }
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1),
                ),
                _sectionHeader(context, 'APP SETTINGS & INFO'),
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
                if (!AuthService().isGuest)
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

                  if (confirm == true && context.mounted) {
                    AuthService().signOut(); 
                    
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
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
                  const Text('v0.3.0', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
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

  void _showAccountRequiredDialog(BuildContext context, String feature, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(child: Text('$feature Locked')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign in to unlock your $feature.', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close drawer
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            child: const Text('Sign In Now'),
          ),
        ],
      )
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white54 
            : Colors.black45,
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, {required VoidCallback onTap, bool isLocked = false}) {
    return ListTile(
      leading: Icon(
        icon, 
        color: isLocked 
          ? Colors.grey.withValues(alpha: 0.5)
          : (Theme.of(context).brightness == Brightness.dark ? Colors.orange : const Color(0xFF0D1B3E))
      ),
      title: Text(title, style: TextStyle(
        fontWeight: FontWeight.w600, 
        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(isLocked ? 0.4 : 0.9)
      )),
      trailing: isLocked ? const Icon(Icons.lock_outline, size: 16, color: Colors.grey) : null,
      onTap: onTap,
    );
  }
}
