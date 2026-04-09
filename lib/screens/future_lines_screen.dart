import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/future_train_lines.dart';
import '../data/metro_stations.dart';
import '../data/track_data.dart';
import '../data/future_track_data.dart';
import '../widgets/cached_tile_provider.dart';
import '../models/station.dart';
import 'station_detail_screen.dart';

class FutureLinesScreen extends StatefulWidget {
  const FutureLinesScreen({super.key});

  @override
  State<FutureLinesScreen> createState() => _FutureLinesScreenState();
}

class _FutureLinesScreenState extends State<FutureLinesScreen> {
  bool _showLabels = true;
  bool _legendMinimized = false;
  bool _isSatellite = false;
  String? _selectedLineName;
  String? _interactedStationName; // Tracking the currently active map expansion

  bool _isHighlighted(String lineName) {
    if (_selectedLineName == null) return true;
    return _selectedLineName == lineName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Future Manila Rail Network'),
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSatellite ? Icons.map : Icons.satellite_alt),
            onPressed: () => setState(() => _isSatellite = !_isSatellite),
            tooltip: 'Toggle Satellite Map',
          ),
          IconButton(
            icon: Icon(_showLabels ? Icons.label : Icons.label_off),
            onPressed: () => setState(() => _showLabels = !_showLabels),
            tooltip: 'Toggle Station Labels',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(14.5995, 121.0342),
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: _isSatellite ? const [] : const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.taratrain',
                tileProvider: CachedTileProvider(),
              ),
              PolylineLayer(
                polylines: [
                  ..._getExistingLinePolylines('LRT1', _isHighlighted('LRT1') ? Colors.green : Colors.green.withValues(alpha: 0.1)),
                  ..._getExistingLinePolylines('LRT2', _isHighlighted('LRT2') ? Colors.purple : Colors.purple.withValues(alpha: 0.1)),
                  ..._getExistingLinePolylines('MRT3', _isHighlighted('MRT3') ? const Color(0xFFFFD700) : const Color(0xFFFFD700).withValues(alpha: 0.1)),
                  ...futureLines.map((line) {
                    final bool isSelected = _isHighlighted(line.name);
                    return Polyline(
                      points: line.points,
                      color: Color(line.color).withValues(alpha: isSelected ? 1.0 : 0.1),
                      strokeWidth: isSelected ? 6.0 : 3.0,
                      isDotted: true,
                    );
                  }),
                ],
              ),
              MarkerLayer(
                markers: _buildGroupedMarkers(),
              ),
            ],
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rail Network Legend', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1F2937))),
                          Text('Operational & Future Extensions', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      IconButton(
                        icon: Icon(_legendMinimized ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF3F51B5)),
                        onPressed: () => setState(() => _legendMinimized = !_legendMinimized),
                      ),
                    ],
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: _legendMinimized ? 0 : 350,
                    child: ClipRRect(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _operationalLegendItem('LRT-1', Colors.green, 'LRT1'),
                                  const SizedBox(width: 8),
                                  _operationalLegendItem('LRT-2', Colors.purple, 'LRT2'),
                                  const SizedBox(width: 8),
                                  _operationalLegendItem('MRT-3', const Color(0xFFFFD700), 'MRT3'),
                                  const SizedBox(width: 16),
                                  _dashedLegendItem(),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1),
                            ),
                            Column(
                              children: futureLines.asMap().entries.map((entry) {
                                final index = entry.key;
                                final line = entry.value;
                                final isSelected = _selectedLineName == line.name;

                                return TweenAnimationBuilder<double>(
                                  duration: Duration(milliseconds: 400 + (index * 100)),
                                  curve: Curves.easeOutBack,
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 30 * (1.0 - value)),
                                      child: Opacity(
                                        opacity: value,
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: InkWell(
                                            onTap: () => setState(() => _selectedLineName = (isSelected ? null : line.name)),
                                            borderRadius: BorderRadius.circular(16),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              height: 70,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: isSelected ? Color(line.color).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  )
                                                ],
                                                border: Border.all(
                                                  color: isSelected ? Color(line.color) : Colors.grey.shade100,
                                                  width: isSelected ? 2 : 1,
                                                ),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: Stack(
                                                children: [
                                                  // Background Image
                                                  if (line.bgImage != null)
                                                    Positioned.fill(
                                                      child: Opacity(
                                                        opacity: isSelected ? 0.4 : 0.25,
                                                        child: Image.asset(line.bgImage!, fit: BoxFit.cover),
                                                      ),
                                                    ),
                                                  // Gradient Overlay
                                                  Positioned.fill(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment.centerLeft,
                                                          end: Alignment.centerRight,
                                                          colors: [
                                                            Colors.white.withValues(alpha: 0.9),
                                                            Colors.white.withValues(alpha: 0.6),
                                                            Colors.transparent,
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Content
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                                    child: Row(
                                                      children: [
                                                        _buildLineLogoWrapper(line),
                                                        const SizedBox(width: 16),
                                                        Expanded(
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                line.name,
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.w900,
                                                                  fontSize: 16,
                                                                  color: isSelected ? Color(line.color) : const Color(0xFF1F2937),
                                                                  letterSpacing: 0.5,
                                                                ),
                                                              ),
                                                              Text(
                                                                line.status,
                                                                style: TextStyle(fontSize: 10, color: isSelected ? Colors.black87 : Colors.grey.shade600, fontWeight: FontWeight.bold),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        if (isSelected)
                                                          Icon(Icons.check_circle, color: Color(line.color), size: 24),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedLegendItem() {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (i) => Container(width: 4, height: 2, color: Colors.grey.shade400)),
          ),
        ),
        const SizedBox(width: 8),
        Text('Dashed = Extension', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
      ],
    );
  }

  List<Marker> _buildGroupedMarkers() {
    final List<Map<String, dynamic>> flatList = [];
    
    // Filter and Process Operational
    for (var s in metroStations) {
      if (_selectedLineName == null || _isHighlighted(s['line'])) {
        flatList.add({
          'type': 'operational',
          'data': s,
          'name': s['name'] as String,
          'line': s['line'],
          'color': _getLineColor(s['line']),
          'pos': LatLng(s['lat'], s['lng']),
          'isExtension': s['isExtension'] == true,
        });
      }
    }
    
    // Filter and Process Future
    for (var line in futureLines) {
      if (_selectedLineName == null || _selectedLineName == line.name) {
        for (var s in line.stations) {
          // Check if already added via metroStations (deduplicate)
          final String sName = s.name.trim().toLowerCase();
          final String lName = line.name.trim().toLowerCase();
          
          if (flatList.any((existing) {
            final String eName = existing['name'].toString().trim().toLowerCase();
            final String eLine = existing['line'].toString().trim().toLowerCase();
            return eName == sName && eLine == lName;
          })) {
            continue;
          }
          
          flatList.add({
            'type': 'future',
            'data': s,
            'name': s.name.split(' (')[0].trim(),
            'line': line.name,
            'color': Color(line.color),
            'pos': s.position,
            'line_obj': line,
            'isExtension': true,
          });
        }
      }
    }

    final Map<String, List<List<Map<String, dynamic>>>> clusters = {};
    const double latThresh = 0.005; // ~500m
    const double lngThresh = 0.005;

    for (var point in flatList) {
      final name = point['name'] as String;
      final pos = point['pos'] as LatLng;
      
      bool addedToCluster = false;
      if (clusters.containsKey(name)) {
        for (var cluster in clusters[name]!) {
          final avgLat = cluster.map((e) => (e['pos'] as LatLng).latitude).reduce((a, b) => a + b) / cluster.length;
          final avgLng = cluster.map((e) => (e['pos'] as LatLng).longitude).reduce((a, b) => a + b) / cluster.length;
          
          if ((pos.latitude - avgLat).abs() < latThresh && (pos.longitude - avgLng).abs() < lngThresh) {
            cluster.add(point);
            addedToCluster = true;
            break;
          }
        }
      } else {
        clusters[name] = [];
      }
      
      if (!addedToCluster) {
        clusters[name]!.add([point]);
      }
    }

    final List<Marker> regularMarkers = [];
    final List<Marker> expandedMarkers = [];
    for (var entry in clusters.entries) {
      final name = entry.key;
      for (var cluster in entry.value) {
        final avgPos = LatLng(
          cluster.map((e) => (e['pos'] as LatLng).latitude).reduce((a, b) => a + b) / cluster.length,
          cluster.map((e) => (e['pos'] as LatLng).longitude).reduce((a, b) => a + b) / cluster.length,
        );
        
        final String interactionKey = "${name}_${avgPos.latitude.toStringAsFixed(4)}";
        final isExpanded = _interactedStationName == interactionKey;

        final marker = Marker(
          point: avgPos,
          width: isExpanded ? 400 : (_showLabels ? 140 : 30),
          height: isExpanded ? 150 : 50,
          child: _buildStationMarkerWidget(interactionKey, name, cluster, isExpanded),
        );

        if (isExpanded) {
          expandedMarkers.add(marker);
        } else {
          regularMarkers.add(marker);
        }
      }
    }
    
    return [...regularMarkers, ...expandedMarkers];
  }

  Widget _buildStationMarkerWidget(String interactionKey, String name, List<Map<String, dynamic>> stations, bool isExpanded) {
    final primaryStation = stations.first;
    final primaryLine = primaryStation['line'];
    final bool highlighted = _isHighlighted(primaryLine);
    final Color primaryColor = primaryStation['color'];

    return GestureDetector(
      onTap: () {
        if (stations.length > 1) {
          setState(() {
            _interactedStationName = (_interactedStationName == interactionKey) ? null : interactionKey;
          });
        } else {
          // Show mini preview modal with View Details button
          final s = stations.first;
          _showStationMiniPreview(s);
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isExpanded
            ? Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Builder(
                      builder: (context) {
                        // Geographically Aware Layout for Common Station
                        Map<String, dynamic>? lrt1, mrt3, mrt7;
                        for (var s in stations) {
                          final line = s['line'].toString().toUpperCase().replaceAll('-', '').replaceAll(' ', '');
                          if (line.contains('LRT1')) lrt1 = s;
                          else if (line.contains('MRT3')) mrt3 = s;
                          else if (line.contains('MRT7')) mrt7 = s;
                        }

                        // Geographic Priority: Left = LRT1, Right = MRT7, Bottom = MRT3
                        // Fallback logic for general stations
                        final left = lrt1 ?? stations[0];
                        
                        // FOR COMMON STATION: Explicitly map Right to MRT7 and Bottom to MRT3
                        final isCommon = name.toUpperCase().contains('COMMON');
                        final right = (isCommon && mrt7 != null) ? mrt7 : (stations.length > 1 ? (stations[1] == left ? (stations.length > 2 ? stations[2] : null) : stations[1]) : null);
                        final bottom = (isCommon && mrt3 != null) ? mrt3 : (stations.length > 2 ? stations[2] : null);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildExpansionBox(left['line'], left['color'], left),
                                Container(width: 8, height: 1.5, color: left['color']),
                                _buildMultiColorBorderNameBox(name, stations, primaryColor),
                                if (right != null) ...[
                                  Container(width: 8, height: 1.5, color: right['color']),
                                  _buildExpansionBox(right['line'], right['color'], right),
                                ],
                              ],
                            ),
                            if (bottom != null) ...[
                              Container(width: 1.5, height: 8, color: bottom['color']),
                              _buildExpansionBox(bottom['line'], bottom['color'], bottom),
                            ],
                          ],
                        );
                      }
                    ),
                  ),
                ),
              )
            : AnimatedStationMarker(
                child: Opacity(
                  opacity: highlighted ? 1.0 : 0.3,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_showLabels)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: primaryColor, width: 1.0),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                          ),
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: (stations.length > 1 || (primaryStation['isExtension'] == true)) ? Colors.white : primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (stations.length > 1 || (primaryStation['isExtension'] == true)) ? primaryColor : Colors.white, 
                            width: 2
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMultiColorBorderNameBox(String name, List<Map<String, dynamic>> stations, Color primaryColor) {
     final List<Color> colors = stations.map((s) => s['color'] as Color).toList();
     
     Gradient gradient;
     if (colors.length == 1) {
       gradient = LinearGradient(colors: [colors[0], colors[0]]);
     } else if (colors.length == 2) {
       gradient = LinearGradient(
         colors: [colors[0], colors[1]],
         stops: const [0.5, 0.5],
         begin: Alignment.centerLeft,
         end: Alignment.centerRight,
       );
     } else {
       gradient = LinearGradient(
         colors: [colors[0], colors[0], colors[1], colors[1], colors[2], colors[2]],
         stops: const [0, 0.33, 0.33, 0.66, 0.66, 1.0],
         begin: Alignment.centerLeft,
         end: Alignment.centerRight,
       );
     }

     return Container(
       padding: const EdgeInsets.all(2.0), // Slightly more compact
       decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: gradient,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
       ),
       child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // More compact
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(8),
         ),
         child: Text(
           name.toUpperCase(),
           style: const TextStyle(
             fontWeight: FontWeight.w900, 
             fontSize: 11, // Smaller font to prevent overflow
             color: Colors.black,
             letterSpacing: 0.2
           ),
         ),
       ),
     );
  }

  bool hasInterchangePoint(List<Map<String, dynamic>> stations) {
    return stations.length > 1;
  }

  Widget _buildExpansionBox(String lineName, Color color, Map<String, dynamic> stationRecord) {
    final bool isMRT3 = lineName.toUpperCase().contains('MRT3');
    // Clean up line name: remove (North Avenue), "Line" suffix, etc.
    final String cleanName = lineName.toUpperCase().split(' (')[0].replaceAll('LINE', '').trim();

    return GestureDetector(
      onTap: () => _showStationMiniPreview(stationRecord),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Compact padding
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Text(
          cleanName,
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 10, 
            color: isMRT3 ? Colors.black : Colors.white, 
            letterSpacing: 0.1
          ),
        ),
      ),
    );
  }

  void _showStationMiniPreview(Map<String, dynamic> stationRecord) {
    try {
      Station? stationObj;
      String lineName = "";
      int lineColorValue = 0xFF3F51B5;

      if (stationRecord['type'] == 'operational') {
        stationObj = Station.fromMap(stationRecord['data']);
        lineName = stationRecord['line'];
        lineColorValue = _getLineColor(lineName).toARGB32();
      } else {
        final FutureStation futureStation = stationRecord['data'];
        final FutureLine lineObj = stationRecord['line_obj'];
        lineName = lineObj.name;
        lineColorValue = lineObj.color;
        
        final String searchName = futureStation.name.split(' (')[0].trim().toUpperCase();
        final Map<String, dynamic> match = metroStations.firstWhere(
          (s) => (s['name'] as String).toUpperCase() == searchName || 
                 (s['name'] as String).toUpperCase().contains(searchName),
          orElse: () => {},
        );

        if (match.isNotEmpty) {
          stationObj = Station.fromMap(match);
        } else {
          stationObj = Station(
            id: 'future-${futureStation.name.toLowerCase().replaceAll(' ', '-')}',
            name: futureStation.name,
            line: lineName,
            order: 99,
            lat: futureStation.position.latitude,
            lng: futureStation.position.longitude,
            isTransfer: futureStation.connections != null,
            isTerminus: false,
            isExtension: true,
            opensOnLeft: true,
            connections: futureStation.connections?.split(', ') ?? [],
            connectingRoutes: futureStation.connections ?? "Future line station.",
            landmark: futureStation.nearby ?? "Planned development area.",
            imageUrl: futureStation.imageUrl ?? "",
            structureType: "Future Station",
            city: futureStation.city,
          );
        }
      }
      
      final Color markerColor = Color(lineColorValue);
      final String city = stationObj.city;
      final String locationText = city.isNotEmpty ? city : "Metro Manila";
      final String imageUrl = stationObj.imageUrl;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: 380,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
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
                      colors: [markerColor.withValues(alpha: 0.05), markerColor.withValues(alpha: 0.2)],
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
                    Center(
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 24),
                    
                    // [Logo + Line]
                    Row(
                      children: [
                        _buildStationLogo(lineName, markerColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lineName,
                            style: TextStyle(fontWeight: FontWeight.w800, color: (lineName == 'MRT3') ? Colors.black : markerColor, fontSize: 13, letterSpacing: 0.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (stationObj!.isExtension)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: const Text("FUTURE", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                            stationObj.name.split(' (')[0],
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1F2937), letterSpacing: -1.0, height: 1.1),
                          ),
                        ),
                        if (stationObj.stationCode.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: markerColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: markerColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              stationObj.stationCode,
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.w900, 
                                color: (lineName == 'MRT3') ? Colors.black : markerColor, 
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
                    
                    // [Transfer Hub Badge]
                    if (stationObj.isTransfer)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.indigo.withValues(alpha: 0.2))),
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
                       const SizedBox(height: 26),

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
                              _navigateToStationDetail(stationObj!);
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
    } catch (e) {
      debugPrint("Error opening station mini preview: $e");
    }
  }

  Widget _buildStationLogo(String lineName, Color markerColor) {
    String asset = 'assets/image/LRTA.png';
    if (lineName == 'MRT3') asset = 'assets/image/MRT3.jpg';
    if (lineName == 'MRT-7') asset = 'assets/image/MRT7.png';
    if (lineName == 'NSCR') asset = 'assets/image/PNR_Logo.png';
    
    bool useAsset = (lineName != 'MMS' && !lineName.contains('Subway') && lineName != 'MRT-4');

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: markerColor.withValues(alpha: 0.3), width: 1)),
      child: useAsset
          ? ClipOval(child: Image.asset(asset, width: 24, height: 24, fit: BoxFit.cover))
          : Icon(Icons.subway_rounded, size: 20, color: markerColor),
    );
  }

  void _navigateToStationDetail(Station stationObj) {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StationDetailScreen(station: stationObj)),
      );
    }
  }



  Widget _operationalLegendItem(String name, Color color, String lineCode) {
    final isSelected = _selectedLineName == lineCode;
    String? bgImg;
    if (lineCode == 'LRT1') bgImg = 'assets/image/Stations/LRT1/LRTA-2-4G.jpg';
    if (lineCode == 'LRT2') bgImg = 'assets/image/Stations/LRT2/LRT2-2-TREN.jpg';
    if (lineCode == 'MRT3') bgImg = 'assets/image/Stations/MRT3/MRT3-2-TRAIN.jpg';

    return InkWell(
      onTap: () => setState(() => _selectedLineName = (isSelected ? null : lineCode)),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 2 : 1),
          boxShadow: [if (isSelected) BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (bgImg != null)
              Positioned.fill(
                child: Opacity(
                  opacity: isSelected ? 0.3 : 0.15,
                  child: Image.asset(bgImg, fit: BoxFit.cover),
                ),
              ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(
                    name, 
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 12, 
                      color: isSelected ? color : const Color(0xFF1F2937),
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLineColor(String lineName) {
    final name = lineName.toUpperCase();
    if (name.contains('LRT1')) return Colors.green;
    if (name.contains('LRT2')) return Colors.purple;
    if (name.contains('MRT3')) return const Color(0xFFFFD700);
    if (name.contains('MRT7') || name.contains('MRT-7')) return const Color(0xFFEF5350);
    if (name.contains('SUBWAY') || name.contains('MMS')) return const Color(0xFF1E3A8A);
    if (name.contains('NSCR')) return const Color(0xFF800000);
    if (name.contains('MRT-4')) return const Color(0xFF009688);
    return Colors.blueGrey;
  }

  Widget _buildLineLogoWrapper(FutureLine line, {double size = 24}) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Color(line.color).withValues(alpha: 0.3), width: 1),
      ),
      child: line.logoAsset != null
          ? ClipOval(child: Image.asset(line.logoAsset!, width: size, height: size, fit: BoxFit.cover))
          : Icon(line.icon ?? Icons.subway_rounded, size: size * 0.8, color: Color(line.color)),
    );
  }

  List<Polyline> _getExistingLinePolylines(String lineName, Color color) {
    List<Polyline> polylines = [];
    switch (lineName.toUpperCase()) {
      case 'LRT1':
        polylines.add(Polyline(
            points: FutureTrackData.lrt1ExtensionTrack.reversed.toList(),
            color: color,
            strokeWidth: 3.0,
            isDotted: true));
        polylines.add(Polyline(
            points: TrackData.lrt1Track,
            color: color,
            strokeWidth: 3.0,
            isDotted: false));
        polylines.add(Polyline(
            points: [TrackData.lrt1Track.last, const LatLng(14.654578, 121.030964)],
            color: color,
            strokeWidth: 3.0,
            isDotted: true));
        break;
      case 'LRT2':
        polylines.add(Polyline(
            points: FutureTrackData.lrt2WestTrack.reversed.toList(),
            color: color,
            strokeWidth: 3.0,
            isDotted: true));
        polylines.add(Polyline(
            points: TrackData.lrt2Track,
            color: color,
            strokeWidth: 3.0,
            isDotted: false));
        break;
      case 'MRT3':
        polylines.add(Polyline(
            points: TrackData.mrt3Track,
            color: color,
            strokeWidth: 3.0,
            isDotted: false));
        polylines.add(Polyline(
            points: [TrackData.mrt3Track.last, const LatLng(14.654243, 121.030875)],
            color: color,
            strokeWidth: 3.0,
            isDotted: true));
        break;
      default:
        final stations = metroStations.where((s) => s['line'] == lineName).toList()
          ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
        final List<LatLng> points =
            stations.map((s) => LatLng(s['lat'] as double, s['lng'] as double)).toList();
        polylines.add(Polyline(points: points, color: color, strokeWidth: 3.0));
    }
    return polylines;
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
