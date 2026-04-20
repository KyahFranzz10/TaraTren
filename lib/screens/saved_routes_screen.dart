
import 'package:flutter/material.dart';
import '../services/saved_routes_service.dart';
import '../services/route_planner_service.dart';
import 'package:intl/intl.dart';
import '../services/navigation_controller.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/geojson_service.dart';
import '../widgets/cached_tile_provider.dart';
import '../data/metro_stations.dart';
import '../data/track_data.dart';

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({super.key});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  final SavedRoutesService _service = SavedRoutesService();
  List<SavedRoute>? _savedRoutes;
  String? _errorMessage;
  final Map<String, LatLng> _stationCoordMap = {};

  @override
  void initState() {
    super.initState();
    _initStations();
    _loadRoutes();
    _loadGeoJson();
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

  void _initStations() {
    for (var s in metroStations) {
      final name = s['name'] as String;
      _stationCoordMap[name] = LatLng(
        (s['lat'] as num).toDouble(),
        (s['lng'] as num).toDouble(),
      );
    }
  }

  Future<void> _loadRoutes() async {
    try {
      final routes = await _service.getAllRoutes();
      if (mounted) setState(() {
        _savedRoutes = routes;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Failed to load routes: $e');
    }
  }

  Future<void> _deleteRoute(int id) async {
    try {
      await _service.deleteRoute(id);
      _loadRoutes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Routes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
      ),
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
          : _savedRoutes == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _summaryHeader(_savedRoutes?.length ?? 0),
                    Expanded(
                      child: _savedRoutes!.isEmpty
                          ? _buildEmptyState()
                          : _buildList(),
                    ),
                  ],
                ),
    );
  }

  Widget _summaryHeader(int count) {
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
        children: [
          const Text('Your Frequent Paths', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('$count Routes', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statItem(Icons.bookmark, 'Organized'),
              const SizedBox(width: 24),
              _statItem(Icons.speed, 'Quick Access'),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_rounded, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('No saved routes yet', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Plan a route and bookmark it to see it here!', 
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      itemCount: _savedRoutes!.length,
      itemBuilder: (context, index) {
        final saved = _savedRoutes![index];
        final date = DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(saved.date));
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_transit, color: Colors.indigo),
            ),
            title: Text(
              '${saved.fromStation} → ${saved.toStation}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _legacyBadge('${saved.route.totalMinutes}m', Colors.blue),
                    const SizedBox(width: 8),
                    _legacyBadge('₱${saved.route.totalFare.toStringAsFixed(0)}', Colors.green),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
              onPressed: () => _deleteRoute(saved.id!),
            ),
            onTap: () => _showRouteDetails(saved),
          ),
        );
      },
    );
  }

  Widget _legacyBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _showRouteDetails(SavedRoute saved) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('${saved.fromStation} to ${saved.toStation}', 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildResultMap(saved.route),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  Navigator.pop(context); // Exit Saved Routes screen
                  NavigationController().startNavigation(saved.route);
                },
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('Start Live Navigation', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSummaryRow(saved.route),
            const SizedBox(height: 24),
            ...saved.route.legs.asMap().entries.map((e) => _buildMiniLeg(e.value, e.key, saved.route.legs.length)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(PlannedRoute r) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _summaryItem(Icons.schedule, '${r.totalMinutes}m'),
        _summaryItem(Icons.payments, '₱${r.totalFare.toStringAsFixed(0)}'),
        _summaryItem(Icons.transfer_within_a_station, '${r.transfers} transfer'),
      ],
    );
  }

  Widget _summaryItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMiniLeg(RouteLeg leg, int index, int total) {
    final isLast = index == total - 1;
    final color = leg.type == LegType.walk ? Colors.white38 : _getLineColor(leg.line);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: color.withOpacity(0.2)),
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
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  '${leg.fromStation} → ${leg.toStation}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                if (leg.stops > 0)
                  Text('${leg.stops} stops • ~${leg.estMinutes}m', 
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
                if (leg.transferNote != null)
                   Text(leg.transferNote!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLineColor(String line) {
    final norm = line.replaceAll('-', '').toUpperCase();
    switch (norm) {
      case 'LRT1': return const Color(0xFF2E7D32);
      case 'LRT2': return const Color(0xFF6A1B9A);
      case 'MRT3': return const Color(0xFFFFEB3B); // Pure Vibrant Yellow
      default: return Colors.blueGrey;
    }
  }

  Widget _buildResultMap(PlannedRoute route) {
    if (_stationCoordMap.isEmpty) return Container(color: const Color(0xFF1E293B));

    final List<Polyline> polylines = [];
    final List<Marker> markers = [];

    // Calculate full path points using TrackData
    for (final leg in route.legs) {
      final color = _getLineColor(leg.line);
      List<LatLng> points = [];

      if (leg.type == LegType.ride) {
        List<LatLng> track = [];
        final normLine = leg.line.replaceAll('-', '').toUpperCase();
        if (normLine == 'LRT1') track = TrackData.lrt1Track;
        else if (normLine == 'LRT2') track = TrackData.lrt2Track;
        else if (normLine == 'MRT3') track = TrackData.mrt3Track;

        final start = _stationCoordMap[leg.fromStation];
        final end = _stationCoordMap[leg.toStation];

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
        // Walk / Transfer
        final transfer = TrackData.transferRoutes.firstWhere(
          (r) => (r.fromStation == leg.fromStation && r.toStation == leg.toStation) ||
                 (r.toStation == leg.fromStation && r.fromStation == leg.toStation),
          orElse: () => TransferRoute(id: '', fromLine: '', toLine: '', fromStation: '', toStation: '', distanceMeters: 0, isAirConditioned: false, walkDescription: '', path: []),
        );
        if (transfer.path.isNotEmpty) {
           points = transfer.fromStation == leg.fromStation ? transfer.path : transfer.path.reversed.toList();
        } else {
          // Fallback to straight line
          final start = _stationCoordMap[leg.fromStation];
          final end = _stationCoordMap[leg.toStation];
          if (start != null && end != null) points = [start, end];
        }
      }

      if (points.isNotEmpty) {
        polylines.add(Polyline(
          points: points,
          color: color,
          strokeWidth: 6,
          isDotted: leg.type == LegType.walk,
        ));
      }
    }

    // Add markers for stations
    for (int i = 0; i < route.legs.length; i++) {
        final leg = route.legs[i];
        final start = _stationCoordMap[leg.fromStation];
        if (start != null) {
          markers.add(Marker(
            point: start,
            width: 12, height: 12,
            child: Container(
              decoration: BoxDecoration(
                color: _getLineColor(leg.line),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ));
        }
        if (i == route.legs.length - 1) {
          final end = _stationCoordMap[leg.toStation];
          if (end != null) {
            markers.add(Marker(
              point: end,
              width: 12, height: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: _getLineColor(leg.line),
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
    if (allPoints.isEmpty) return Container(color: const Color(0xFF1E293B));

    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (var p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12.5,
      ),
      children: [
        Container(color: const Color(0xFFF0F0F0)),
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.taratren.app',
          tileProvider: CachedTileProvider(),
        ),
        PolygonLayer(
          polygons: _geoPolygons.map((p) => Polygon(
            points: p.points,
            color: Colors.white.withOpacity(0.03),
            borderColor: Colors.white.withOpacity(0.05),
            borderStrokeWidth: 1,
          )).toList(),
        ),
        PolylineLayer(
          polylines: [
            ..._geoPolylines.map((p) => Polyline(
              points: p.points,
              color: Colors.white.withOpacity(0.08), // Highly muted neutral background
              strokeWidth: 2.0, // Thin background lines
            )),
            ...polylines,
          ],
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
