import 'package:flutter/material.dart';
import '../services/route_planner_service.dart';
import '../services/settings_service.dart';
import '../services/navigation_controller.dart';
import '../data/metro_stations.dart';
import '../data/track_data.dart';
import '../services/saved_routes_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/geojson_service.dart';
import '../widgets/cached_tile_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen>
    with SingleTickerProviderStateMixin {
  final _service = RoutePlannerService();

  String? _fromStation;
  String? _toStation;
  List<PlannedRoute>? _results;
  int _selectedRouteIndex = 0;
  bool _searched = false;

  late final List<String> _allStations;

  // Pre-build a name→line lookup from the raw station data
  Map<String, String> _stationLineMap = {};
  Map<String, String> _stationCityMap = {};
  Map<String, LatLng> _stationCoordMap = {};
  Map<String, String> _stationCodeMap = {};

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _allStations = _service.allStationKeys;

    _stationLineMap = {};
    _stationCityMap = {};
    _stationCoordMap = {};

    for (final s in metroStations) {
      final name = s['name'] as String;
      final line = s['line'] as String;
      final key = '$name-$line';
      _stationLineMap[key] = line;
      _stationCityMap[key] = s['city'] ?? 'Unknown City';
      _stationCodeMap[key] = s['code'] ?? '??-00';
      _stationCoordMap[key] = LatLng(
        (s['lat'] as num).toDouble(),
        (s['lng'] as num).toDouble(),
      );
    }

    _loadGeoJson();

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
  }

  List<Polygon> _geoPolygons = [];
  List<Polyline> _geoPolylines = [];

  Future<void> _loadGeoJson() async {
    try {
      final data = await GeoJsonService.loadAllLines();
      if (mounted) {
        setState(() {
          _geoPolygons = data['polygons'] as List<Polygon>;
          _geoPolylines = data['polylines'] as List<Polyline>;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _search() {
    if (_fromStation == null || _toStation == null) return;
    final userType = SettingsService().userType;
    final results =
        _service.plan(_fromStation!, _toStation!, userType: userType);
    setState(() {
      _results = results;
      _selectedRouteIndex = 0;
      _searched = true;
    });
    _animCtrl.forward(from: 0);
  }

  void _swap() {
    setState(() {
      final tmp = _fromStation;
      _fromStation = _toStation;
      _toStation = tmp;
      _results = null;
      _searched = false;
    });
  }

  // ── Line color helpers ──────────────────────────────────────────────────────
  Color _lineColor(String line) {
    switch (line.toUpperCase()) {
      case 'LRT1':  return const Color(0xFF2E7D32);
      case 'LRT2':  return const Color(0xFF6A1B9A);
      case 'MRT3': return const Color(0xFFFBC02D); // Amber/Gold for visibility
      case 'WALK':  return const Color(0xFF546E7A);
      default:      return const Color(0xFF37474F);
    }
  }

  String _lineLabel(String line) {
    switch (line.toUpperCase()) {
      case 'LRT1': return 'LRT-1 Green Line';
      case 'LRT2': return 'LRT-2 Purple Line';
      case 'MRT3': return 'MRT-3 Yellow Line';
      case 'WALK': return 'Transfer Walk';
      default:     return line;
    }
  }


  Future<void> _handleSave(PlannedRoute route) async {
    if (AuthService().isGuest) {
      _showAccountRequiredDialog("Saved Routes", "Save your trip plans for immediate offline access and quick navigation.");
      return;
    }
    if (_fromStation == null || _toStation == null) return;
    
    try {
      await SavedRoutesService().saveRoute(_fromStation!, _toStation!, route);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Route saved for offline access!'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save route: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showAccountRequiredDialog(String feature, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1C2D3E),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.orange),
            const SizedBox(width: 10),
            Text('$feature Locked', style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign in to unlock your $feature.', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            child: const Text('Sign In Now'),
          ),
        ],
      )
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Route Planner'),
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildPickerCard(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSearchButton(),
            ),
            const SizedBox(height: 28),
            if (_searched) 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildResults(),
              ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1B3E).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("METRO MANILA", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text("PLAN YOUR JOURNEY", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 1),
          Text("Find efficient multi-line train routes", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
        ],
      ),
    );
  }

  // ── Picker Card ─────────────────────────────────────────────────────────────

  Widget _buildPickerCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _stationTile(
              label: 'STARTING AT',
              value: _fromStation,
              icon: Icons.radio_button_checked,
              iconColor: Colors.blue,
              context: context,
              onTap: () async {
                final picked = await _showStationPicker(title: 'Select Origin', exclude: _toStation);
                if (picked != null) {
                  setState(() {
                    _fromStation = picked;
                    _results = null;
                    _searched = false;
                  });
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Expanded(child: Divider(height: 1)),
                  GestureDetector(
                    onTap: _swap,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF0D1B3E), size: 20),
                    ),
                  ),
                  const Expanded(child: Divider(height: 1)),
                ],
              ),
            ),
            _stationTile(
              label: 'DESTINATION',
              value: _toStation,
              icon: Icons.location_on_rounded,
              iconColor: Colors.redAccent,
              context: context,
              onTap: () async {
                final picked = await _showStationPicker(title: 'Select Destination', exclude: _fromStation);
                if (picked != null) {
                  setState(() {
                    _toStation = picked;
                    _results = null;
                    _searched = false;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _stationTile({
    required String label,
    required String? value,
    required IconData icon,
    required Color iconColor,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(
                    value != null ? _cleanStationName(value) : 'Tap to select station',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: value != null ? FontWeight.bold : FontWeight.normal,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (value != null)
                    Text(
                      '${_lineLabel(_stationLineMap[value] ?? '')} • ${_stationCityMap[value] ?? ''}',
                      style: TextStyle(fontSize: 11, color: _lineColor(_stationLineMap[value] ?? '').withOpacity(0.9), fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Search Button ───────────────────────────────────────────────────────────

  Widget _buildSearchButton() {
    final ready = _fromStation != null && _toStation != null;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: ready ? _search : null,
        icon: const Icon(Icons.map_outlined),
        label: const Text('Find Best Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D1B3E),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: ready ? 4 : 0,
        ),
      ),
    );
  }

  // ── Results ─────────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (_results == null || _results!.isEmpty) {
      return FadeTransition(opacity: _fadeAnim, child: _buildErrorCard());
    }
    
    final currentRoute = _results![_selectedRouteIndex];
    if (currentRoute.legs.isEmpty) {
      return FadeTransition(
          opacity: _fadeAnim, child: _buildSameStationCard());
    }
    
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Route Options',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (_results!.isNotEmpty)
                IconButton(
                  onPressed: () => _handleSave(currentRoute),
                  icon: const Icon(Icons.bookmark_add_rounded, color: Color(0xFF4FC3F7)),
                  tooltip: 'Save Route',
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_results!.length > 1) ...[
            _buildRouteSelector(),
            const SizedBox(height: 20),
          ],
          
          if (currentRoute.legs.isNotEmpty) ...[
            Text('Route Map', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            _buildRouteMap(currentRoute),
          ],
          const SizedBox(height: 16),
          _buildSummaryStrip(currentRoute),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close results screen
                NavigationController().startNavigation(currentRoute);
              },
              icon: const Icon(Icons.navigation_rounded, color: Colors.white),
              label: const Text('Start Navigation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...currentRoute.legs.asMap().entries.map(
                (e) => _buildLegCard(
                    e.value, e.key, currentRoute.legs.length),
              ),
          const SizedBox(height: 12),
          _buildDisclaimer(),
        ],
      ),
    );
  }

  Widget _buildRouteSelector() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _results!.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, index) {
          final isSelected = _selectedRouteIndex == index;
          final route = _results![index];
          return GestureDetector(
            onTap: () => setState(() => _selectedRouteIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1565C0) : const Color(0xFF1C2D3E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.white30 : Colors.white12,
                ),
              ),
              child: Center(
                child: Text(
                  'Option ${index + 1} • ${route.totalMinutes}m',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRouteMap(PlannedRoute route) {
    final List<Polyline> polylines = [];
    final List<Marker> markers = [];

    // Calculate full path points
    for (final leg in route.legs) {
      final color = _lineColor(leg.line);
      List<LatLng> points = [];

      if (leg.type == LegType.ride) {
        List<LatLng> track = [];
        final normLine = leg.line.replaceAll('-', '').toUpperCase();
        if (normLine == 'LRT1') track = TrackData.lrt1Track;
        else if (normLine == 'LRT2') track = TrackData.lrt2Track;
        else if (normLine == 'MRT3') track = TrackData.mrt3Track;

        final startKey = '${leg.fromStation}-${leg.line}';
        final endKey = '${leg.toStation}-${leg.line}';
        final start = _stationCoordMap[startKey];
        final end = _stationCoordMap[endKey];
        
        if (start != null && end != null && track.isNotEmpty) {
          int sIdx = TrackData.findClosestIndex(track, start);
          int eIdx = TrackData.findClosestIndex(track, end);
          if (sIdx != -1 && eIdx != -1) {
            if (sIdx <= eIdx) {
              points = track.sublist(sIdx, eIdx + 1);
            } else {
              points = track.sublist(eIdx, sIdx + 1).reversed.toList();
            }
          }
        }
      } else {
        // Walk
        final route = TrackData.transferRoutes.firstWhere(
          (r) => (r.fromStation == leg.fromStation && r.toStation == leg.toStation) ||
                 (r.toStation == leg.fromStation && r.fromStation == leg.toStation),
          orElse: () => TransferRoute(id: '', fromLine: '', toLine: '', fromStation: '', toStation: '', distanceMeters: 0, isAirConditioned: false, walkDescription: '', path: []),
        );
        if (route.path.isNotEmpty) {
           points = route.fromStation == leg.fromStation ? route.path : route.path.reversed.toList();
        }
      }

      if (points.isNotEmpty) {
        polylines.add(Polyline(
          points: points,
          color: color,
          strokeWidth: 8, 
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
          isDotted: leg.type == LegType.walk,
        ));
      }
    }

    // Add markers for stations
    for (int i = 0; i < route.legs.length; i++) {
        final leg = route.legs[i];
        final key = '${leg.fromStation}-${leg.line}';
        final start = _stationCoordMap[key];
        if (start != null) {
          markers.add(Marker(
            point: start,
            width: 12, height: 12,
            child: Container(
              decoration: BoxDecoration(
                color: _lineColor(leg.line),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ));
        }
        if (i == route.legs.length - 1) {
          final end = _stationCoordMap['${leg.toStation}-${leg.line}'];
          if (end != null) {
            markers.add(Marker(
              point: end,
              width: 12, height: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: _lineColor(leg.line),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ));
          }
        }
    }

    // Fit map to bounds
    List<LatLng> allPoints = polylines.expand((p) => p.points).toList();
    if (allPoints.isEmpty) return const SizedBox.shrink();

    // Improved centering
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (var p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    return Container(
      height: 280,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12.5,
          ),
          children: [
            Container(color: const Color(0xFFF0F0F0)),
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.taratren',
              tileProvider: CachedTileProvider(),
            ),
            PolygonLayer(
              polygons: _geoPolygons.map((p) => Polygon(
                points: p.points,
                color: Colors.black.withOpacity(0.01),
                borderColor: Colors.black.withOpacity(0.02),
                borderStrokeWidth: 0.5,
              )).toList(),
            ),
            PolylineLayer(
              polylines: [
                ..._geoPolylines.map((p) => Polyline(
                  points: p.points,
                  color: Colors.grey.withOpacity(0.15),
                  strokeWidth: 1.5,
                )),
                ...polylines,
              ],
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStrip(PlannedRoute route) {
    final userType = SettingsService().userType;
    final ticketLabel = userType == 'beep'
        ? 'Beep (stored value)'
        : userType == 'white_beep'
            ? 'Discounted fare'
            : 'Single Journey';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1B3E).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Text(ticketLabel.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Text('₱${route.totalFare.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statItem(Icons.schedule, '${route.totalMinutes}m Trip'),
              const SizedBox(width: 30),
              _statItem(Icons.transfer_within_a_station, '${route.transfers} Transfer'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 16),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildLegCard(RouteLeg leg, int index, int total) {
    final isLast = index == total - 1;
    final color = leg.type == LegType.walk ? Colors.blueGrey : _lineColor(leg.line);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 3, color: color.withOpacity(0.15)),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leg.type == LegType.ride ? '${leg.line} Ride' : 'Walk / Transfer',
                      style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_cleanStationName(leg.fromStation)} → ${_cleanStationName(leg.toStation)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                      Text('${leg.stops} stops • ~${leg.estMinutes} mins', 
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                    if (leg.transferNote != null)
                       Padding(
                         padding: const EdgeInsets.only(top: 4),
                         child: Text(leg.transferNote!, style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                       ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              if (leg.type == LegType.ride)
                Icon(Icons.directions_transit, color: color.withOpacity(0.2), size: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text('No Route Found', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text(
            'There\'s no direct train connection between these stations. Try selecting stations on LRT-1, LRT-2, or MRT-3.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSameStationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Icon(Icons.location_on_rounded, color: Colors.blueAccent, size: 48),
          const SizedBox(height: 16),
          Text('You\'re already there!', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Origin and destination are the same station.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: const Text(
        'Travel times are estimates based on average train speed (~40 km/h). Fares reflect current promotional rates. Allow extra time during peak hours.',
        style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.5, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── Station Picker Bottom Sheet ─────────────────────────────────────────────

  Future<String?> _showStationPicker(
      {required String title, String? exclude}) async {
    String query = '';
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          final filtered = _allStations
              .where((s) =>
                  s != exclude &&
                  s.toLowerCase().contains(query.toLowerCase()))
              .toList();

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            decoration: BoxDecoration(
              color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Station', style: TextStyle(color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20)),
                      const SizedBox(height: 16),
                      TextField(
                        autofocus: true,
                        style: TextStyle(color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Search station...',
                          hintStyle: TextStyle(color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white38 : Colors.grey.shade400),
                          filled: true,
                          fillColor: Theme.of(ctx).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                        onChanged: (v) => setModal(() => query = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: _buildGroupedStationList(filtered, (key) => Navigator.pop(ctx, key)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  List<Widget> _buildGroupedStationList(List<String> stations, Function(String) onSelect) {
    final List<Widget> widgets = [];
    final List<String> lines = ['LRT1', 'LRT2', 'MRT3'];

    for (final line in lines) {
      final lineStations = stations.where((s) => _stationLineMap[s] == line).toList();
      if (lineStations.isEmpty) continue;

      // Sort by station code
      lineStations.sort((a, b) => (_stationCodeMap[a] ?? '').compareTo(_stationCodeMap[b] ?? ''));

      // Header
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                width: 4, height: 16,
                decoration: BoxDecoration(
                  color: _lineColor(line),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _lineLabel(line).toUpperCase(),
                style: TextStyle(
                  color: _lineColor(line),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );

      // Station items 
      widgets.addAll(
        lineStations.map((key) {
           final displayName = _cleanStationName(key);
           final city = _stationCityMap[key] ?? 'Metro Manila';
           final code = _stationCodeMap[key] ?? '??-00';
           
           return ListTile(
             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             leading: Container(
               width: 36, height: 36,
               decoration: BoxDecoration(color: _lineColor(line).withOpacity(0.1), shape: BoxShape.circle),
               child: Center(
                 child: Text(
                    code,
                    style: TextStyle(color: _lineColor(line), fontSize: 10, fontWeight: FontWeight.w900),
                  ),
               ),
             ),
             title: Text(displayName, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
             subtitle: Text(city, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
             onTap: () => onSelect(key),
           );
        }),
      );
    }
    return widgets;
  }

  String _cleanStationName(String key) {
    if (!key.contains('-')) return key;
    return key.substring(0, key.lastIndexOf('-'));
  }
}
