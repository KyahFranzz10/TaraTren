import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../data/metro_stations.dart';
import '../data/track_data.dart';
import '../models/station.dart';
import 'station_detail_screen.dart';
import '../services/live_train_service.dart';
import '../services/system_overlay_service.dart';
import '../services/gtfs_simulation_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/navigation_controller.dart';
import '../services/geojson_service.dart';
import '../widgets/cached_tile_provider.dart';
import '../services/route_planner_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LiveTrainService _liveService = LiveTrainService();
  final AuthService _auth = AuthService();
  Position? _currentPosition;
  StreamSubscription? _liveSubscription;
  Timer? _trainTimer;
  List<LiveTrainReport> _liveReports = [];
  bool _followUser = true;
  bool _mapReady = false; 
  bool _showLabels = true;
  bool _isSatellite = false;
  List<VirtualTrain> _scheduledTrains = [];
  Timer? _simulationTimer;

  // GeoJSON data
  List<Polygon> _geoPolygons = [];
  List<Polyline> _geoPolylines = [];
  bool _isLoadingGeoJson = true;

  // Active Route Navigation
  PlannedRoute? _activeRoute;
  final Map<String, LatLng> _stationCoordMap = {};

  @override
  void initState() {
    super.initState();
    LocationService().currentPosition.addListener(_onLocationUpdate);
    _onLocationUpdate();
    
    // Listen for station focus events from other screens
    NavigationController().focusedStation.addListener(_handleFocusedStation);
    
    _trainTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _reportPresenceIfOnBoard();
    });
    
    _liveSubscription = _liveService.getLiveTrainsRTDB().listen((reports) {
      if (mounted) {
        setState(() {
          _liveReports = reports;
        });
      }
    });

    // Check if there's an initial focused station
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleFocusedStation();
    });

    // Periodically update simulated train positions
    _updateSimulatedTrains();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
       _updateSimulatedTrains();
    });

    _loadGeoJsonData();
    _initStationCoords();
    
    NavigationController().activeRoute.addListener(_handleActiveRoute);
  }

  void _initStationCoords() {
    for (var s in metroStations) {
      if (s['isExtension'] != true) {
        _stationCoordMap[s['name']] = LatLng(
          (s['lat'] as num).toDouble(),
          (s['lng'] as num).toDouble(),
        );
      }
    }
  }

  void _handleActiveRoute() {
    if (mounted) {
      setState(() {
        _activeRoute = NavigationController().activeRoute.value;
        if (_activeRoute != null) {
          _followUser = false; // Prevent GPS from snapping away from the route
        }
      });
      if (_activeRoute != null) {
        _fitRouteBounds(_activeRoute!);
      }
    }
  }

  void _fitRouteBounds(PlannedRoute route) {
    final List<LatLng> points = [];
    for (var leg in route.legs) {
      final s = _stationCoordMap[leg.fromStation];
      final e = _stationCoordMap[leg.toStation];
      if (s != null) points.add(s);
      if (e != null) points.add(e);
    }
    if (points.isNotEmpty && _mapReady) {
       // Just move to center for now, or use fitBounds if supported by your flutter_map version
       double avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
       double avgLng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
       _mapController.move(LatLng(avgLat, avgLng), 14.0);
    }
  }

  Future<void> _loadGeoJsonData() async {
    try {
      final geoData = await GeoJsonService.loadAllLines();
      if (mounted) {
        setState(() {
          _geoPolygons = geoData['polygons'] as List<Polygon>;
          _geoPolylines = geoData['polylines'] as List<Polyline>;
          _isLoadingGeoJson = false;
        });
      }
    } catch (e) {
      debugPrint("MapScreen: GeoJSON load error: $e");
      if (mounted) {
        setState(() {
          _isLoadingGeoJson = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Warning: Failed to load mapping data. Some features may be hidden."),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _updateSimulatedTrains() {
    if (mounted) {
      setState(() {
        _scheduledTrains = GtfsSimulationService.getActiveTrains();
      });
    }
  }

  void _handleFocusedStation() {
    final station = NavigationController().focusedStation.value;
    if (station != null && mounted && _mapReady) {
      final lat = station['lat'] as double;
      final lng = station['lng'] as double;
      final color = getLineColor(station['line']);
      
      _mapController.move(LatLng(lat, lng), 15.0);
      _showStationModal(station, color);
      
      // Clear the focus so it doesn't trigger again on subsequent rebuilds
      NavigationController().focusedStation.value = null;
    }
  }

  @override
  void dispose() {
    LocationService().currentPosition.removeListener(_onLocationUpdate);
    NavigationController().focusedStation.removeListener(_handleFocusedStation);
    NavigationController().activeRoute.removeListener(_handleActiveRoute);
    _trainTimer?.cancel();
    _liveSubscription?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _onLocationUpdate() {
    if (mounted) {
      final newPos = LocationService().currentPosition.value;
      setState(() {
        _currentPosition = newPos;
      });
      
      // Automatically follow user if enabled
      if (_followUser && newPos != null && _mapReady) {
        _mapController.move(LatLng(newPos.latitude, newPos.longitude), _mapController.camera.zoom);
      }
    }
  }

  // Automatic "I'm on board" reporter using track proximity
  Future<void> _reportPresenceIfOnBoard() async {
    if (_currentPosition == null) return;
    
    final userPos = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final user = _auth.currentUser;
    if (user == null) return;

    // Precise station detection using GeoJSON polygons
    bool isAtStation = false;
    String? stationLine;
    for (var station in metroStations) {
      if (station['isExtension'] == true) continue;
      final poly = GeoJsonService.getStationPolygon(station['name']);
      if (poly != null && GeoJsonService.isPointInPolygon(userPos, poly)) {
        isAtStation = true;
        stationLine = station['line'];
        break;
      }
    }

    // Report if moving or if at a station (useful for terminal stations)
    if (_currentPosition!.speed < 4.0 && !isAtStation) return; 

    final String? activeTrack = isAtStation ? stationLine : _getTrackLineForMap(userPos);
    if (activeTrack != null) {
      final String trainId = "T-${activeTrack}-${user.id.substring(0, 5)}";
      await _liveService.reportLocation(trainId, activeTrack, userPos, user.id);
    }
  }

  String? _getTrackLineForMap(LatLng userPos) {
    // Check walkways first
    final snappedT = TrackData.snapToTransfer(userPos.latitude, userPos.longitude);
    if (snappedT != null && Geolocator.distanceBetween(userPos.latitude, userPos.longitude, snappedT.latitude, snappedT.longitude) <= 30.0) {
      return "Transfer";
    }

    String? currentLine;
    double minTrackDist = 100.0;
    final lines = ['LRT1', 'LRT2', 'MRT3'];
    for (var line in lines) {
      final points = getLinePoints(line);
      for (var p in points) {
        double d = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, p.latitude, p.longitude);
        if (d < minTrackDist) {
          minTrackDist = d;
          currentLine = line;
        }
      }
    }
    return currentLine;
  }

  void _centerOnUser() {
    if (_currentPosition != null) {
      setState(() => _followUser = true);
      _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15.0);
    }
  }

  List<LatLng> getLinePoints(String lineName) {
    // Return GeoJSON-based tracks for operational lines
    switch (lineName.toUpperCase()) {
      case 'LRT1': return TrackData.lrt1Track;
      case 'LRT2': return TrackData.lrt2Track;
      case 'MRT3': return TrackData.mrt3Track;
    }

    // fallback for extensions or unknown lines (legacy behavior)
    final stations = metroStations
        .where((s) => s['line'] == lineName && s['isExtension'] != true)
        .toList()
      ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

    if (stations.isEmpty) return [];

    List<LatLng> allPoints = [];
    for (int i = 0; i < stations.length; i++) {
      allPoints.add(LatLng(stations[i]['lat'] as double, stations[i]['lng'] as double));
      
      if (i < stations.length - 1) {
        final fromId = stations[i]['id'].toString().toLowerCase();
        final toId = stations[i + 1]['id'].toString().toLowerCase();
        allPoints.addAll(_getWaypoints(fromId, toId));
      }
    }
    return allPoints;
  }

  List<LatLng> _getWaypoints(String fromId, String toId) {
    final pair = fromId.compareTo(toId) < 0 ? '$fromId-$toId' : '$toId-$fromId';
    final List<LatLng> pts;

    switch (pair) {
      case 'lrt1-balintawak-lrt1-monumento':
        pts = [
          const LatLng(14.65710, 121.00000),
          const LatLng(14.65715, 120.99500),
          const LatLng(14.65725, 120.99200),
          const LatLng(14.65745, 120.98850),
          const LatLng(14.65710, 120.98680),
          const LatLng(14.65650, 120.98500),
          const LatLng(14.65550, 120.98400),
        ];
        break;
      case 'lrt1-monumento-lrt1-5th-ave':
        pts = [const LatLng(14.65150, 120.98370)];
        break;
      case 'lrt1-edsa-lrt1-baclaran':
        pts = [const LatLng(14.53650, 120.99850)];
        break;
      case 'lrt1-ninoy-aquino-lrt1-dr-santos':
        pts = [
          const LatLng(14.4960, 120.9935),
          const LatLng(14.4940, 120.9928),
          const LatLng(14.4918, 120.9918),
          const LatLng(14.4895, 120.9908),
          const LatLng(14.4875, 120.9900),
        ];
        break;
      case 'lrt2-legarda-lrt2-recto':
        pts = [const LatLng(14.60250, 120.98800)];
        break;
      case 'mrt3-north-mrt3-quezon':
        pts = [const LatLng(14.65050, 121.03450)];
        break;
      case 'mrt3-magallanes-mrt3-taft':
        pts = [const LatLng(14.54000, 121.00180)];
        break;
      default:
        return [];
    }

    return fromId.compareTo(toId) < 0 ? pts : pts.reversed.toList();
  }


  Color getLineColor(String line) {
    switch (line.replaceAll('-', '').toUpperCase()) {
      case 'LRT1': return Colors.green;
      case 'LRT2': return Colors.purple;
      case 'MRT3': return const Color(0xFFFFD700);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If GeoJSON is loaded, we skip manual tracks to avoid overlap
    final bool hasGeoData = _geoPolylines.isNotEmpty;

    return Stack(
      children: [
        if (_isLoadingGeoJson)
           const Positioned(
             top: 10,
             right: 70,
             child: SizedBox(
               width: 15,
               height: 15,
               child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
             ),
           ),
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(14.5995, 120.9842),
            initialZoom: 12.0,
            onMapReady: () {
              setState(() => _mapReady = true);
              _onLocationUpdate(); // Move to current position once ready
            },
            onPositionChanged: (position, hasGesture) {
              if (hasGesture && _followUser) {
                setState(() => _followUser = false);
              }
            },
          ),
          children: [
            Container(color: const Color(0xFFF0F0F0)),
            TileLayer(
              urlTemplate: _isSatellite
                  ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              subdomains: _isSatellite ? const [] : const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.taratrain',
              tileProvider: CachedTileProvider(),
            ),
            PolygonLayer(
              polygons: _geoPolygons,
            ),
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution(
                  _isSatellite
                      ? 'Esri, Maxar, Earthstar Geographics'
                      : '© OpenStreetMap/CARTO',
                  onTap: () {}, // Optional: Add a link if needed
                ),
              ],
            ),
            PolylineLayer(
              polylines: [
                ..._geoPolylines,
                if (!hasGeoData) ...[
                  Polyline(points: getLinePoints('LRT1'), color: getLineColor('LRT1').withOpacity(0.6), strokeWidth: 5.0),
                  Polyline(points: getLinePoints('LRT2'), color: getLineColor('LRT2').withOpacity(0.6), strokeWidth: 5.0),
                  Polyline(points: getLinePoints('MRT3'), color: getLineColor('MRT3').withOpacity(0.6), strokeWidth: 5.0),
                ],
                if (_activeRoute != null) ..._buildActiveRoutePolylines(),
              ],
            ),
            MarkerLayer(
              markers: [
                ...metroStations.where((s) => s['isExtension'] != true).map((stationMap) {
                  // ... logic ...
                  // (Using existing logic here, just adding the active route markers below)
                  final line = stationMap['line'];
                  final markerColor = getLineColor(line);
                  return Marker(
                    point: LatLng(stationMap['lat'] as double, stationMap['lng'] as double),
                    width: _showLabels ? 100 : 20,
                    height: _showLabels ? 40 : 20,
                    child: AnimatedStationMarker(
                      child: GestureDetector(
                        onTap: () => _showStationModal(stationMap, markerColor),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_showLabels)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: markerColor, width: 0.5),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                ),
                                child: Text(
                                  stationMap['name'] as String,
                                  style: TextStyle(
                                    color: (line.toString().toUpperCase() == 'MRT3') ? Colors.black87 : markerColor, 
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const SizedBox(height: 1),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: markerColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 1)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                ..._buildCombinedTrainMarkers(),
                if (_activeRoute != null) ..._buildActiveRouteMarkers(),
                if (_currentPosition != null)
// ... (rest of markers)
                  Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple effect
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), shape: BoxShape.circle)),
                        // Heading indicator
                        Transform.rotate(
                          angle: _currentPosition!.heading * (3.14159 / 180),
                          child: Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.topCenter,
                            child: Icon(Icons.navigation, color: Colors.blue.withOpacity(0.8), size: 16),
                          ),
                        ),
                        // User dot
                        Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)])),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        // Active Route Overlay UI
        if (_activeRoute != null)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B3E).withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation_rounded, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LIVE NAVIGATION', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(
                          'To ${_activeRoute!.legs.last.toStation}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      NavigationController().activeRoute.value = null;
                    },
                  ),
                ],
              ),
            ),
          ),
        // Categorized Map Controls
        Positioned(
          right: 16,
          top: 100, // Positioned below any top overlays
          child: Column(
            children: [
              // --- VIEW GROUP ---
              _buildControlGroup([
                _mapControlButton(
                  icon: _isSatellite ? Icons.map : Icons.satellite_alt,
                  color: _isSatellite ? Colors.indigo : Colors.blueGrey.shade700,
                  isActive: _isSatellite,
                  onPressed: () => setState(() => _isSatellite = !_isSatellite),
                  tooltip: 'Satellite View',
                ),
                _mapControlButton(
                  icon: _showLabels ? Icons.label : Icons.label_off,
                  color: Colors.indigo,
                  isActive: _showLabels,
                  onPressed: () => setState(() => _showLabels = !_showLabels),
                  tooltip: 'Show Labels',
                ),
              ]),
              const SizedBox(height: 16),
              // --- SYSTEM GROUP ---
              _buildControlGroup([
                _mapControlButton(
                  icon: Icons.picture_in_picture_alt,
                  color: Colors.orange.shade700,
                  onPressed: () async {
                    final lService = LocationService();
                    LocationService().manuallyOpenedIsland.value = true;
                    await SystemOverlayService().show(
                      nextStation: lService.nextStationName.value ?? 'Search...',
                      line: lService.onboardLine.value ?? 'LRT1',
                      speed: (lService.currentSpeed.value?.toInt() ?? 0),
                      isArrivalAlert: lService.islandStatusLabel.value?.contains("Arriving") ?? false,
                      bodyText: lService.islandBodyText.value,
                      prevStation: lService.prevStationName.value ?? '--',
                      currentStation: lService.currentStationOnboard.value ?? 'Awaiting Signal',
                      statusLabel: lService.islandStatusLabel.value ?? 'STANDBY',
                      distance: lService.distanceToNext.value ?? 0.0,
                      pace: 'Scan',
                      isSouthbound: lService.currentDirection.value == 'SOUTHBOUND',
                    );
                  },
                  tooltip: 'Dynamic Island',
                ),
                _mapControlButton(
                  icon: Icons.help_outline,
                  color: Colors.blueGrey,
                  onPressed: () => _showSimulationInfo(),
                  tooltip: 'Map Info',
                ),
              ]),
            ],
          ),
        ),
        
        // Navigation Controls Group (Bottom Right)
        Positioned(
          right: 16,
          bottom: 24,
          child: _buildControlGroup([
            _mapControlButton(
              icon: Icons.my_location,
              color: Colors.blue,
              isActive: _followUser,
              onPressed: _centerOnUser,
              tooltip: 'Center on Me',
            ),
            _mapControlButton(
              icon: Icons.refresh,
              color: Colors.green,
              onPressed: () => setState(() {}),
              tooltip: 'Refresh Map',
            ),
          ]),
        ),
        Positioned(
          left: 10,
          top: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendItem('LRT-1', Colors.green),
                _legendItem('LRT-2', Colors.purple),
                _legendItem('MRT-3', Colors.yellow),
              ],
            ),
          ),
        ),
        if (GtfsSimulationService.isOperationSuspended())
          Positioned(
            top: 20,
            left: 60,
            right: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Holy Week Maintenance: Simulated Service Suspended',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _legendItem(String name, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  List<Marker> _buildCombinedTrainMarkers() {
    final List<Marker> markers = [];
    
    // Live Crowdsourced Trains
    for (var report in _liveReports) {
      markers.add(_createTrainMarker(
        pos: report.position, 
        line: report.lineName, 
        model: report.trainsetId, 
        isLive: true, 
        directionInfo: "Crowdsourced Live"
      ));
    }

    // Scheduled Trains (Filter out if close to a live train to avoid clutter)
    for (var train in _scheduledTrains) {
      bool tooCloseToLive = _liveReports.any((lr) => 
        lr.lineName == train.lineName && 
        Geolocator.distanceBetween(lr.position.latitude, lr.position.longitude, train.position.latitude, train.position.longitude) < 800
      );
      
      if (!tooCloseToLive) {
        markers.add(_createTrainMarker(
          pos: train.position, 
          line: train.lineName, 
          model: train.trainsetModel, 
          isLive: false, 
          directionInfo: train.isNorthbound ? "Northbound Schedule" : "Southbound Schedule"
        ));
      }
    }

    return markers;
  }

  Marker _createTrainMarker({required LatLng pos, required String line, required String model, required bool isLive, required String directionInfo}) {
    return Marker(
      point: pos,
      width: isLive ? 80 : 50,
      height: isLive ? 80 : 50,
      child: Tooltip(
        message: "${line}: ${model}\nStatus: ${isLive ? 'VERIFIED REAL-TIME' : 'En route (Scheduled)'}\n($directionInfo)",
        triggerMode: TooltipTriggerMode.tap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLive) const PulseMarker(),
            Container(
              width: 35, 
              height: 35, 
              decoration: BoxDecoration(
                color: Colors.white, 
                shape: BoxShape.circle, 
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)], 
                border: Border.all(color: getLineColor(line), width: isLive ? 4 : 2)
              ), 
              child: Icon(
                isLive ? Icons.sensors_rounded : (line == 'Transfer' ? Icons.directions_walk : Icons.train), 
                color: isLive ? Colors.redAccent : getLineColor(line), 
                size: 20
              )
            ),
            if (isLive)
              Positioned(
                top: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)]),
                  child: const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Polyline> _buildActiveRoutePolylines() {
    final List<Polyline> list = [];
    if (_activeRoute == null) return list;

    for (var leg in _activeRoute!.legs) {
      final color = getLineColor(leg.line);
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
        
        // Fallback to straight line if track matching failed
        if (points.isEmpty && start != null && end != null) {
          points = [start, end];
        }
      } else {
        // Walk / Transfer
        final trRoute = TrackData.transferRoutes.firstWhere(
          (r) => (r.fromStation == leg.fromStation && r.toStation == leg.toStation) ||
                 (r.toStation == leg.fromStation && r.fromStation == leg.toStation),
          orElse: () => TransferRoute(id: '', fromLine: '', toLine: '', fromStation: '', toStation: '', distanceMeters: 0, isAirConditioned: false, walkDescription: '', path: []),
        );
        if (trRoute.path.isNotEmpty) {
           points = trRoute.fromStation == leg.fromStation ? trRoute.path : trRoute.path.reversed.toList();
        } else {
          final s = _stationCoordMap[leg.fromStation];
          final e = _stationCoordMap[leg.toStation];
          if (s != null && e != null) points = [s, e];
        }
      }

      if (points.isNotEmpty) {
        list.add(Polyline(
          points: points,
          color: leg.type == LegType.ride ? color : Colors.blue.withOpacity(0.5),
          strokeWidth: leg.type == LegType.ride ? 7.0 : 4.0,
          isDotted: leg.type == LegType.walk,
        ));
      }
    }
    return list;
  }

  List<Marker> _buildActiveRouteMarkers() {
    final List<Marker> list = [];
    for (var leg in _activeRoute!.legs) {
      final s = _stationCoordMap[leg.fromStation];
      if (s != null) {
        list.add(Marker(
          point: s,
          width: 30, height: 30,
          child: Container(
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
            child: Icon(leg.type == LegType.ride ? Icons.train : Icons.directions_walk, size: 16, color: Colors.black87),
          ),
        ));
      }
    }
    // Final destination marker
    final last = _stationCoordMap[_activeRoute!.legs.last.toStation];
    if (last != null) {
      list.add(Marker(
        point: last,
        width: 40, height: 40,
        child: const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
      ));
    }
    return list;
  }

  void _showSimulationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text("Train Visualization"),
          ],
        ),
        content: const Text(
          "The train positions seen on this map are currently based on official schedules and real-time movement simulations.\n\nWhen actual Taratren users are onboard, you will see 'LIVE' pulse markers representing verified real-time positions.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("GOT IT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showStationModal(Map<String, dynamic> stationMap, Color markerColor) {
    final String city = stationMap['city'] ?? "";
    final String province = stationMap['province'] ?? "Metro Manila";
    final String locationText = city.isNotEmpty ? "$city, $province" : province;
    final bool isTransfer = stationMap['isTransfer'] ?? false;
    final String imageUrl = stationMap['imageUrl'] ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 380,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Branded Background
            if (imageUrl.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: imageUrl.startsWith('assets')
                      ? Image.asset(
                          imageUrl, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                        )
                      : Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container()),
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [markerColor.withOpacity(0.05), markerColor.withOpacity(0.2)],
                  ),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Center indicator handle
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 24),
                  
                  // [Logo + Line]
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: markerColor.withOpacity(0.3), width: 1)),
                        child: ClipOval(
                          child: Image.asset(
                            stationMap['line'] == 'MRT3' ? 'assets/image/MRT3.jpg' : 'assets/image/LRTA.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          stationMap['line'],
                          style: TextStyle(fontWeight: FontWeight.w800, color: (stationMap['line'] == 'MRT3') ? Colors.black : markerColor, fontSize: 13, letterSpacing: 0.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // [Station Name + Code]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          stationMap['name'],
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1F2937), letterSpacing: -1.0, height: 1.1),
                        ),
                      ),
                      if (stationMap['code'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: markerColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: markerColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            stationMap['code'],
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w900, 
                              color: (stationMap['line'] == 'MRT3') ? Colors.black : markerColor, 
                              letterSpacing: 1.0
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  // [City]
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationText.toUpperCase(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // [Transfer?]
                  if (isTransfer)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.indigo.withOpacity(0.2))),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.transfer_within_a_station, size: 14, color: Colors.indigo),
                          SizedBox(width: 6),
                          Text("TRANSFER HUB", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.indigo)),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 26), // Spacer for consistency

                  const Spacer(),
                  
                  // [Button]
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Builder(
                      builder: (context) {
                        final double luminance = (0.299 * markerColor.r * 255 + 0.587 * markerColor.g * 255 + 0.114 * markerColor.b * 255) / 255;
                        final bool isDark = luminance < 0.6;
                        final Color textColor = isDark ? Colors.white : const Color(0xFF1F2937);

                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: markerColor,
                            foregroundColor: textColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StationDetailScreen(station: Station.fromMap(stationMap)),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('View Full Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18, color: textColor),
                            ],
                          ),
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          final child = entry.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              if (idx < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.black.withOpacity(0.05),
                  indent: 8,
                  endIndent: 8,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _mapControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    String? tooltip,
    bool isActive = false,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isActive ? color : color.withOpacity(0.5),
          size: 20,
        ),
      ),
    );
  }
}

class PulseMarker extends StatefulWidget {
  const PulseMarker({super.key});

  @override
  State<PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<PulseMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.4).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red.withOpacity(0.4), width: 2),
          boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)],
        ),
      ),
    );
  }
}

class AnimatedStationMarker extends StatefulWidget {
  final Widget child;
  const AnimatedStationMarker({super.key, required this.child});

  @override
  State<AnimatedStationMarker> createState() => _AnimatedStationMarkerState();
}

class _AnimatedStationMarkerState extends State<AnimatedStationMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}
