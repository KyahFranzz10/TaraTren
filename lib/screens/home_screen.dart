import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import '../models/station.dart';
import '../data/mock_data.dart';
import '../services/location_service.dart';
import '../services/navigation_controller.dart';
import '../services/transit_alert_service.dart';
import '../services/offline_storage_service.dart';
import '../delegates/station_search_delegate.dart';
import '../widgets/cached_tile_provider.dart';
import 'station_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _nearestStation;
  double _distance = 0;

  @override
  void initState() {
    super.initState();
    _loadNearestStation();
  }

  Future<void> _loadNearestStation() async {
    final pos = await LocationService().getCurrentPosition();
    if (pos != null) {
      final nearest = LocationService().getNearestStation(pos);
      if (mounted) {
        setState(() {
          _nearestStation = nearest;
          _distance = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            nearest['lat'],
            nearest['lng'],
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. GLOBAL SEARCH BAR
          GestureDetector(
            onTap: () => showSearch(context: context, delegate: StationSearchDelegate()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.blueGrey),
                  SizedBox(width: 12),
                  Text("Search Stations, Cities, or Landmarks...", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Live Breaking News Ticker (Eagle Eye Alerts)
          _buildTransitTicker(),
          const SizedBox(height: 24),

          // 3. Dynamic Nearest Station Card
          if (_nearestStation != null) ...[
            Builder(builder: (context) {
              final String lineCode = _nearestStation!['line'];
              final String cleanLine = lineCode == 'LRT1' ? 'LRT-1' : (lineCode == 'LRT2' ? 'LRT-2' : 'MRT-3');
              final currentLine = trainLines.firstWhere((l) => l.name == cleanLine, orElse: () => trainLines[0]);
              final lineColor = Color(currentLine.color);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Nearest Station', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 12),
                   GestureDetector(
                     onTap: () => NavigationController().focusStationOnMap(_nearestStation!),
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(24),
                       child: Container(
                         height: 140, 
                         decoration: BoxDecoration(
                           color: lineColor, 
                           boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]
                         ),
                         child: Stack(
                           children: [
                             Positioned.fill(
                               child: IgnorePointer(
                                 child: FlutterMap(
                                   options: MapOptions(
                                     initialCenter: ll.LatLng(_nearestStation!['lat'], _nearestStation!['lng']),
                                     initialZoom: 14.5,
                                     interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                                   ),
                                   children: [
                                     TileLayer(
                                       urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png',
                                       subdomains: const ['a', 'b', 'c', 'd'],
                                       userAgentPackageName: 'com.taratrain',
                                       tileProvider: CachedTileProvider(),
                                       tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                                         colorFilter: const ColorFilter.matrix(<double>[
                                           0.2126, 0.7152, 0.0722, 0, 0,
                                           0.2126, 0.7152, 0.0722, 0, 0,
                                           0.2126, 0.7152, 0.0722, 0, 0,
                                           0,      0,      0,      1, 0,
                                         ]),
                                         child: tileWidget,
                                       ),
                                     ),
                                     MarkerLayer(
                                       markers: [
                                         Marker(
                                           point: ll.LatLng(_nearestStation!['lat'], _nearestStation!['lng']),
                                           width: 80,
                                           height: 80,
                                           child: Container(
                                             decoration: BoxDecoration(
                                               shape: BoxShape.circle,
                                               color: lineColor.withValues(alpha: 0.1),
                                             ),
                                             child: Center(
                                               child: Container(
                                                 width: 12,
                                                 height: 12,
                                                 decoration: BoxDecoration(
                                                   color: Colors.white,
                                                   shape: BoxShape.circle,
                                                   border: Border.all(color: lineColor, width: 2),
                                                   boxShadow: [BoxShadow(color: lineColor.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 5)],
                                                 ),
                                               ),
                                             ),
                                           ),
                                         ),
                                       ],
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                             Positioned.fill(
                               child: Container(
                                 decoration: BoxDecoration(
                                   gradient: LinearGradient(
                                     begin: Alignment.centerLeft,
                                     end: Alignment.centerRight,
                                     colors: [
                                       lineColor,
                                       lineColor.withValues(alpha: 0.85),
                                       lineColor.withValues(alpha: 0.5),
                                       lineColor.withValues(alpha: 0.15),
                                       Colors.transparent,
                                     ],
                                     stops: const [0.0, 0.4, 0.6, 0.85, 1.0],
                                   ),
                                 ),
                               ),
                             ),
                             // Subtle Noise for premium texture
                             Positioned.fill(
                               child: Opacity(
                                 opacity: 0.03,
                                 child: Container(
                                   decoration: const BoxDecoration(
                                     image: DecorationImage(
                                       image: AssetImage('assets/image/Stations/noise_texture.png'),
                                       repeat: ImageRepeat.repeat,
                                     ),
                                   ),
                                 ),
                               ),
                             ),
                             Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                               child: Row(
                                 children: [
                                   Container(
                                     width: 48,
                                     height: 48,
                                     padding: const EdgeInsets.all(8),
                                     decoration: BoxDecoration(
                                       color: Colors.white,
                                       borderRadius: BorderRadius.circular(16),
                                       boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12)],
                                     ),
                                     child: Image.asset(currentLine.logoAsset, fit: BoxFit.contain),
                                   ),
                                   const SizedBox(width: 16),
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                         Text(_nearestStation!['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                                         Text("${(_distance / 1000).toStringAsFixed(1)} km • ${currentLine.name} • ${_nearestStation!['city'] ?? "Metro Manila"}", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                       ],
                                     ),
                                   ),
                                   const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                                 ],
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                   ),
                   const SizedBox(height: 32),
                ],
              );
            }),
          ],

          // 4. Railway Categories
          const Text('Manila Light Rail Transit System', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 12),
          _buildTrainLineCard(trainLines[0]), // LRT-1
          _buildTrainLineCard(trainLines[1]), // LRT-2

          const SizedBox(height: 28),
          const Text('Manila Metro Rail Transit System', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 12),
          _buildTrainLineCard(trainLines[2]), // MRT-3
          _buildSoonLineCard(
            name: 'MRT Line 7', 
            logo: 'assets/image/MRT7.png', 
            color: const Color(0xFFEF5350),
            bgImage: 'assets/image/Stations/MRT7/MRT-7_trains_2021.png',
            status: 'UNDER CONSTRUCTION',
            year: '2027-2028',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StationListScreen(trainLine: trainLines[3]))),
          ),
          _buildSoonLineCard(
            name: 'Metro Manila Subway', 
            icon: Icons.subway, 
            color: const Color(0xFF1E3A8A), // Royal Blue
            status: 'TUNNELING IN PROGRESS',
            year: '2029',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StationListScreen(trainLine: trainLines[4]))),
          ),

          const SizedBox(height: 28),
          const Text('Philippine National Railways', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 12),
          _buildSoonLineCard(
            name: 'North-South Commuter Railway', 
            logo: 'assets/image/PNR_Logo.png', 
            color: const Color(0xFF800000), // Maroon
            bgImage: 'assets/image/Stations/NSCR/PNR_NSCR_train_2021.jpg',
            status: 'PARTIAL: DEC 2027',
            year: '2027-2032',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StationListScreen(trainLine: trainLines[5]))),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildTransitTicker() {
    return StreamBuilder<List<TransitAlert>>(
      stream: TransitAlertService().alertsStream,
      builder: (context, snapshot) {
        final now = DateTime.now();
        final List<TransitAlert> breakingAlerts = (snapshot.data ?? []).where((a) {
          final age = now.difference(a.timestamp);
          if (!a.isBreaking) return false;
          if (a.title.contains("Agila") && age.inMinutes > 15) return false;
          return age.inHours < 1;
        }).toList();

        if (breakingAlerts.isEmpty) {
          return FutureBuilder<List<ScrapedAlert>>(
            future: OfflineStorageService().getLatestAlerts(),
            builder: (context, offlineSnapshot) {
              final rawAlerts = (offlineSnapshot.data ?? []).where((a) {
                final age = now.difference(a.timestamp);
                if (a.title.contains("Agila") && age.inMinutes > 15) return false;
                final isIssue = a.message.contains("Provisional") || a.message.contains("Suspension") || a.message.contains("Issue");
                return isIssue && age.inHours < 1;
              }).toList();
              
              if (rawAlerts.isEmpty) return const SizedBox.shrink();
              
              return _tickerLayout(
                icon: Icons.cloud_off,
                label: "CACHED",
                color: Colors.grey,
                children: rawAlerts.map((a) {
                  final age = now.difference(a.timestamp);
                  final timeLabel = age.inMinutes < 60 ? "${age.inMinutes}m ago" : "${age.inHours}h ago";
                  return _tickerItem(a.title, a.message, timeLabel: timeLabel);
                }).toList(),
              );
            },
          );
        }

        return _tickerLayout(
          icon: Icons.flash_on,
          label: "LIVE",
          color: Colors.redAccent,
          children: breakingAlerts.map((a) => _tickerItem(a.title, a.message)).toList(),
        );
      },
    );
  }

  Widget _tickerLayout({required IconData icon, required String label, required Color color, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tickerItem(String title, String message, {String? timeLabel}) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        children: [
          const Text("🚨", style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
              Row(
                children: [
                   Text(message, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400, overflow: TextOverflow.ellipsis)),
                  if (timeLabel != null) ...[
                    const SizedBox(width: 8),
                    Text(timeLabel, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrainLineCard(TrainLine line) {
    final Color lineColor = Color(line.color);
    final String bgImage = line.name.contains('LRT-1') 
      ? "assets/image/Stations/LRT1/LRTA-2-4G.jpg"
      : (line.name.contains('LRT-2') 
        ? "assets/image/Stations/LRT2/LRT2-2-TREN.jpg"
        : "assets/image/Stations/MRT3/MRT3-2-TRAIN.jpg");

    final bool isMRT3 = line.name == 'MRT-3';
    final bool isDark = _isColorDark(lineColor) || isMRT3;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subColor = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StationListScreen(trainLine: line))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: lineColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              isMRT3 ? Colors.black.withValues(alpha: 0.25) : lineColor.withValues(alpha: 0.3), 
              BlendMode.srcOver
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  isMRT3 ? lineColor.withValues(alpha: 0.95) : lineColor.withValues(alpha: 0.9),
                  isMRT3 ? lineColor.withValues(alpha: 0.7) : Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 54, height: 54, padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isMRT3 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)] : null,
                  ),
                  child: Image.asset(line.logoAsset, fit: BoxFit.contain),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        line.name, 
                        style: TextStyle(
                          fontWeight: FontWeight.w900, 
                          fontSize: 20, 
                          color: textColor, 
                          letterSpacing: -0.5,
                          shadows: isMRT3 ? [const Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4)] : null,
                        )
                      ),
                      Text(
                        '${line.stations.length} Stations • ${line.scheduleSummary}', 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subColor)
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoonLineCard({required String name, String? logo, IconData? icon, required Color color, String? bgImage, required String status, required String year, VoidCallback? onTap}) {
    final bool isDark = _isColorDark(color);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subColor = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          color: color.withValues(alpha: 0.15),
          image: bgImage != null ? DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(color.withValues(alpha: 0.3), BlendMode.srcOver),
          ) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.4)],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 54, height: 54, padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: (logo != null && logo.isNotEmpty) 
                    ? Image.asset(logo, fit: BoxFit.contain, color: (logo.contains('PNR') || logo.contains('MRT7')) ? null : color) 
                    : Icon(icon ?? Icons.train, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor, letterSpacing: -0.5)),
                      Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subColor)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                  child: Text(year, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: textColor))
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isColorDark(Color color) {
    final double r = (color.r * 255.0);
    final double g = (color.g * 255.0);
    final double b = (color.b * 255.0);
    double luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance < 0.6;
  }
}
