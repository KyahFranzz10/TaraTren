import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../data/metro_stations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  
  // Local state for optimistic updates
  final Map<String, dynamic> _optimisticData = {};

  final List<String> _futureLines = [
    'Metro Manila Subway (MMS)',
    'North-South Commuter Railway (NSCR)',
    'MRT Line 7 (MRT-7)',
    'LRT Line 4 (LRT-4)',
    'Makati Intra-city Subway',
    'South Long Haul (SLH)',
    'Unified Grand Central Terminal',
  ];

  final List<String> _trainSets = [
    'LRT1: 1G BN/ACEC',
    'LRT1: 2G Adtranz/Hyundai',
    'LRT1: 3G Kinki Sharyo',
    'LRT1: 4G CAF/Mitsubishi',
    'LRT2: Hyundai Rotem',
    'MRT3: ČKD Tatra RT8D5M',
    'MRT3: CRRC Dalian',
  ];

  Future<void> _handleSignOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    }
  }

  Future<void> _showListPicker({required String title, required List<String> items, required Function(String) onSave}) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.all(20), child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E)))),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(items[index], style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    onSave(items[index]);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStation() async {
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StationPickerSheet(stations: metroStations),
    );
    if (picked != null) {
      setState(() => _optimisticData['fav_station'] = picked);
      await _auth.updateCommuterProfile(favStation: picked);
    }
  }

  Future<void> _updateField(String key, String value, Future<void> Function() updateFn) async {
    setState(() => _optimisticData[key] = value);
    try {
      await updateFn();
    } catch (e) {
      // Revert on error
      setState(() => _optimisticData.remove(key));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final metadata = user?.userMetadata;
    final displayName = metadata?['display_name'] ?? metadata?['name'] ?? 'Commuter';
    final email = user?.email ?? 'Guest Account';
    final String? rawAvatarUrl = metadata?['avatar_url'] ?? metadata?['picture'];
    // Request higher resolution if it's a Google/Social provider thumbnail (e.g., =s96-c to =s400-c)
    String? avatarUrl = rawAvatarUrl;
    if (avatarUrl != null && avatarUrl.contains('=s96-c')) {
      avatarUrl = avatarUrl.replaceAll('=s96-c', '=s400-c');
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _auth.getProfileStream(),
        builder: (context, snapshot) {
          final dbData = snapshot.data ?? {};
          
          // Clear optimistic data if it matches the DB data (Sync complete)
          _optimisticData.removeWhere((key, value) => dbData[key] == value);
          
          // Merge Database Data with Optimistic Local Data
          final profileData = {...dbData, ..._optimisticData};
          
          final favStation = profileData['fav_station'] ?? (snapshot.connectionState == ConnectionState.waiting ? 'Loading...' : 'None');
          final futureLine = profileData['future_line_hype'] ?? (snapshot.connectionState == ConnectionState.waiting ? 'Loading...' : 'None');
          final favTrainSet = profileData['fav_train_set'] ?? (snapshot.connectionState == ConnectionState.waiting ? 'Loading...' : 'None');

          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)]),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null ? Text(displayName[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E))) : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(email, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                    ],
                  ),
                ),

                // Preferences
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _prefCard(Icons.location_on, 'FAVORITE STATION', favStation, Colors.orange, _pickStation),
                        const SizedBox(height: 12),
                        _prefCard(Icons.rocket_launch, 'FUTURE LINE HYPE', futureLine, Colors.blueAccent, 
                          () => _showListPicker(
                            title: 'What line are you excited for?', 
                            items: _futureLines, 
                            onSave: (v) => _updateField('future_line_hype', v, () => _auth.updateCommuterProfile(futureLineHype: v))
                          )),
                        const SizedBox(height: 12),
                        _prefCard(Icons.train, 'FAVORITE TRAIN SET', favTrainSet, Colors.teal, 
                          () => _showListPicker(
                            title: 'Pick Favorite Train Set', 
                            items: _trainSets, 
                            onSave: (v) => _updateField('fav_train_set', v, () => _auth.updateCommuterProfile(favTrainSet: v))
                          )),
                      ],
                    ),
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text("SESSION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
                        ),
                      ),
                      _actionTile(Icons.logout, 'Sign Out', 'Securely end your session', Colors.grey, _handleSignOut),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  "TARATREN v0.3.0 PRE-RELEASE",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.withOpacity(0.5), letterSpacing: 2),
                ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _prefCard(IconData icon, String label, String value, Color color, VoidCallback onTap) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.grey.shade400 : Colors.grey, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, color: isDark ? Colors.grey.shade500 : Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle, Color color, VoidCallback? onTap) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100)),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))
                ]),
              ),
              Icon(Icons.chevron_right, color: isDark ? Colors.grey.shade500 : Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> stations;
  const _StationPickerSheet({required this.stations});
  @override
  State<_StationPickerSheet> createState() => _StationPickerSheetState();
}

class _StationPickerSheetState extends State<_StationPickerSheet> {
  String _query = '';
  Color _lineColor(String line) {
    switch (line.toUpperCase()) {
      case 'LRT1': return const Color(0xFF2E7D32);
      case 'LRT2': return const Color(0xFF6A1B9A);
      case 'MRT3': return const Color(0xFFFBC02D);
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseStations = widget.stations.where((s) {
      final line = s['line'].toString().toUpperCase();
      final isExtension = s['isExtension'] == true;
      final isOperationalLine = line.contains('LRT1') || line.contains('LRT2') || line.contains('MRT3');
      return isOperationalLine && !isExtension && s['name'].toString().toLowerCase().contains(_query.toLowerCase());
    }).toList();
    final Map<String, List<Map<String, dynamic>>> grouped = {
      'LRT1': baseStations.where((s) => s['line'] == 'LRT1').toList(),
      'LRT2': baseStations.where((s) => s['line'] == 'LRT2').toList(),
      'MRT3': baseStations.where((s) => s['line'] == 'MRT3').toList(),
    };

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Set Favorite Station', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E))),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final entry in grouped.entries)
                  if (entry.value.isNotEmpty) ...[
                    Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Row(children: [Container(width: 4, height: 16, decoration: BoxDecoration(color: _lineColor(entry.key), borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), Text(entry.key, style: TextStyle(color: _lineColor(entry.key), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2))])),
                    ...entry.value.map((s) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 12), leading: Container(width: 32, height: 32, decoration: BoxDecoration(color: _lineColor(entry.key).withOpacity(0.1), shape: BoxShape.circle), child: Center(child: Text(s['code'] ?? '??', style: TextStyle(color: _lineColor(entry.key), fontSize: 9, fontWeight: FontWeight.w900)))), title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))), onTap: () => Navigator.pop(context, s['name']))),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
