import 'package:flutter/material.dart';
import 'dart:async';
import '../models/station.dart';
import '../services/auth_service.dart';
import '../data/mock_data.dart';
import '../data/bus_data.dart';
import '../services/settings_service.dart';
import '../services/fare_service.dart';
import '../services/crowd_insight_service.dart';
import '../services/gtfs_simulation_service.dart';
import '../services/live_train_service.dart';
import '../data/transfer_paths.dart';
import 'walking_path_screen.dart';

class StationDetailScreen extends StatefulWidget {
  final Station station;
  const StationDetailScreen({super.key, required this.station});

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  final AuthService _auth = AuthService();
  final SettingsService _settings = SettingsService();
  final CrowdInsightService _crowdService = CrowdInsightService();
  bool _isFavorite = false;
  StreamSubscription? _statusSubscription;
  Station? _selectedDest;
  late TrainLine _stationLine;
  int _selectedDirectionIndex = 0; // 0: North/West, 1: South/East

  @override
  void initState() {
    _stationLine = trainLines.firstWhere(
      (l) {
        final String searchLine = widget.station.line.toUpperCase();
        final String lName = l.name.toUpperCase();
        // Exact match or contains or normalized (no hyphens) match
        return lName == searchLine || 
               lName.replaceAll('-', '') == searchLine.replaceAll('-', '') ||
               (searchLine == 'MMS' && lName.contains('SUBWAY'));
      },
      orElse: () => trainLines[0],
    );
    _selectedDest = _stationLine.stations.lastWhere(
      (s) => s.id != widget.station.id && !s.isExtension,
      orElse: () => _stationLine.stations.firstWhere(
        (s) => !s.isExtension,
        orElse: () => _stationLine.stations.last,
      ),
    );
    super.initState();
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  void _checkFavoriteStatus() {
    _statusSubscription = _auth.getFavorites().listen((snapshot) {
      if (mounted) {
        final docs = snapshot.docs.map((d) => d.id).toList();
        setState(() {
          _isFavorite = docs.contains(widget.station.name);
        });
      }
    });
  }

  Future<void> _toggleFavorite() async {
    await _auth.toggleFavorite(widget.station.name);
  }

  @override
  Widget build(BuildContext context) {
    final station = widget.station;
    final bool isMRT3 = station.line == 'MRT3';
    final Color lineColor = _getLineColor(station.line);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            stretch: true,
            backgroundColor: lineColor,
            leading: const BackButton(),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : (isMRT3 ? Colors.black : Colors.white),
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 20),
              title: LayoutBuilder(
                builder: (context, constraints) {
                  final double top = constraints.biggest.height;
                  final bool isCollapsed = top <= (MediaQuery.of(context).padding.top + kToolbarHeight + 10);
                  // For MRT-3, text is white on image (expanded), black on yellow bar (collapsed)
                  final Color titleColor = (isMRT3 && isCollapsed) ? Colors.black : Colors.white;
                  final Color subtextColor = (isMRT3 && isCollapsed) ? Colors.black54 : Colors.white70;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          shadows: (titleColor == Colors.white) 
                              ? [const Shadow(color: Colors.black54, blurRadius: 10)] 
                              : [],
                        ),
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_stationLine.name} Station'.toUpperCase(),
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  );
                },
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Station Image (Primary Focal Point)
                  station.imageUrl.startsWith('assets')
                      ? Image.asset(
                          station.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(color: lineColor.withValues(alpha: 0.5)),
                        )
                      : Image.network(
                          station.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(color: lineColor.withValues(alpha: 0.5)),
                        ),
                  // Dark Gradient for legibility
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black45, Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildTopInfo(station),
                      const Divider(height: 48),
                      
                      if (!station.isExtension) ...[
                        _buildFareMatrix(),
                        const SizedBox(height: 48),
                        _buildPeakHourInsights(),
                        const SizedBox(height: 32),
                        _buildSocialPulse(station),
                        const SizedBox(height: 48),
                        _buildUpcomingArrivals(station),
                        const SizedBox(height: 48),
                      ] else ...[
                        const SizedBox(height: 48),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopInfo(Station station) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getLineColor(station.line).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.train, size: 24, color: _getIconColor(station.line)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.stationCode,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      '${station.line} Service',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
                    _buildChip(station.structureType),
          ],
        ),
        if (!station.isExtension) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              _buildAccessibilityIcon(Icons.elevator_rounded, station.hasElevator, "Elevator"),
              const SizedBox(width: 12),
              _buildAccessibilityIcon(Icons.escalator_rounded, station.hasEscalator, "Escalator"),
              const SizedBox(width: 12),
              _buildAccessibilityIcon(Icons.accessible_forward_rounded, station.isAccessible, "PWD/Senior"),
            ],
          ),
          const SizedBox(height: 24),
        ],
        
        if (station.isExtension) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.construction_rounded, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Under Construction", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14)),
                      Text("This station is not yet operational and is part of a future transit extension.", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Landmarks section
        _buildInfoModule(
          title: "Nearby Landmarks",
          content: station.landmark,
          icon: Icons.location_on_rounded,
          color: Colors.blueGrey,
        ),

        // Walking path if transfer
        if (station.isTransfer) _buildWalkingGuideButton(station),

        // Connecting Routes section
        if (station.connectingRoutes != '-' && station.connectingRoutes.isNotEmpty)
          _buildConnectingRoutesModule(station.connectingRoutes),
      ],
    );
  }

  Widget _buildWalkingGuideButton(Station station) {
    try {
      final relevantPath = transferPaths.firstWhere(
        (p) => p.fromStationId == station.id || p.toStationId == station.id,
      );

      return Container(
        margin: const EdgeInsets.only(top: 24),
        child: InkWell(
          onTap: () {
            // Find the destination station object for naming
            String toStId = relevantPath.fromStationId == station.id ? relevantPath.toStationId : relevantPath.fromStationId;
            String toStName = "Connected Line";
            for (var line in trainLines) {
              final s = line.stations.where((st) => st.id == toStId).toList();
              if (s.isNotEmpty) {
                toStName = s.first.name;
                break;
              }
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WalkingPathScreen(
                  path: relevantPath,
                  fromName: station.name,
                  toName: toStName,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.transfer_within_a_station_rounded, color: Colors.indigo),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Walking Transfer Guide", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("View step-by-step path to the connected station.", style: TextStyle(fontSize: 12, color: Colors.indigo)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.indigo.shade300),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink(); // No path defined for this transfer
    }
  }

  List<InlineSpan> _buildRouteTextSpans(String text) {
    if (!text.toLowerCase().contains(" via ")) {
      return [TextSpan(text: text)];
    }

    final List<InlineSpan> spans = [];
    // Case-insensitive regex to find " via "
    final RegExp viaRegex = RegExp(r'\s+(via)\s+', caseSensitive: false);
    final Iterable<RegExpMatch> matches = viaRegex.allMatches(text);

    int lastIndex = 0;
    for (final match in matches) {
      // Add the text before " via "
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      // Add " via " in italics and normal weight
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.normal,
        ),
      ));

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }

  Widget _buildInfoModule({required String title, required String content, required IconData icon, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                content,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2D3142), height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectingRoutesModule(String routes) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Icon(Icons.directions_bus_rounded, color: _getIconColor(widget.station.line), size: 24),
          title: Text(
            "Connecting Routes",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getIconColor(widget.station.line)),
          ),
          subtitle: const Text("View transfers, bus & jeepney routes", style: TextStyle(fontSize: 12, color: Colors.grey)),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),
            _parseAndBuildRoutes(routes),
          ],
        ),
      ),
    );
  }

  Widget _parseAndBuildRoutes(String routes) {
    if (routes == '-' || routes.isEmpty || routes == 'No connecting routes available.') return const SizedBox.shrink();

    final lines = routes.split('\n').where((s) => s.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        String cleanLine = line.replaceFirst('•', '').trim();
        IconData icon = Icons.alt_route_rounded;
        
        if (cleanLine.startsWith("Transfer of Train Line")) {
          icon = Icons.transfer_within_a_station_rounded;
        } else if (cleanLine.startsWith("Bus Routes")) {
          icon = Icons.directions_bus_rounded;
        } else if (cleanLine.startsWith("Jeep") || cleanLine.startsWith("Jeep/e-Jeep")) {
          icon = Icons.airport_shuttle_rounded;
        } else if (cleanLine.startsWith("Ferry Service")) {
          icon = Icons.directions_boat_rounded;
        } else if (cleanLine.startsWith("Airport Transfer")) {
          icon = Icons.local_airport_rounded;
        }

        String title = cleanLine;
        String? details;
        int colonIdx = cleanLine.indexOf(':');
        if (colonIdx != -1) {
          title = cleanLine.substring(0, colonIdx).trim();
          details = cleanLine.substring(colonIdx + 1).trim();
        }

        bool isQCBus = cleanLine.toUpperCase().contains("QCITY BUS") || cleanLine.toUpperCase().contains("QUEZON CITY BUS");
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(4), // Slightly tighter padding for the image "icon"
                decoration: BoxDecoration(
                  color: isQCBus ? Colors.blue.shade100 : _getLineColor(widget.station.line).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: isQCBus 
                  ? ClipOval(
                      child: Image.asset(
                        'assets/image/QuezonCityBusService.png', 
                        width: 20, // Smaller size to fit icon scale
                        height: 20, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.directions_bus_filled, size: 16, color: Colors.blue.shade700),
                      ),
                    )
                  : Icon(icon, size: 16, color: _getIconColor(widget.station.line)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: _getIconColor(widget.station.line).withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (details != null && details.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: details.split(',').map((d) {
                            String item = d.trim();
                            String display = item;
                            
                            // Check if this is a bus/QCity route to enhance the display
                            final bool isBus = title.toUpperCase().contains("BUS");
                            final bool isQC = title.toUpperCase().contains("QCITY");

                            if (isBus || isQC) {
                              // Extract ID (handling things like "Route 1" or "42 (Info)")
                              String idOnly = item.replaceAll(RegExp(r'Route\s+'), '');
                              String extraInfo = "";
                              String rawInfo = "";
                              if (idOnly.contains('(')) {
                                final parts = idOnly.split('(');
                                idOnly = parts[0].trim();
                                rawInfo = parts[1].replaceAll(')', '').trim();
                              }

                              try {
                                final lookupId = isQC ? "QC-$idOnly" : idOnly;
                                final routeObj = busRoutes.firstWhere(
                                  (r) => r.routeId == lookupId,
                                  orElse: () => busRoutes.firstWhere((r) => r.routeId == idOnly)
                                );
                                
                                // Only show extraInfo if it's NOT already in the route name
                                if (rawInfo.isNotEmpty && !routeObj.name.toUpperCase().contains(rawInfo.toUpperCase())) {
                                  extraInfo = " ($rawInfo)";
                                }
                                
                                display = "$idOnly | ${routeObj.name}$extraInfo";
                              } catch (_) {
                                // Keep original if not found in registry
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(color: _getLineColor(widget.station.line).withValues(alpha: 0.5), shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Color(0xFF1F2937),
                                          fontSize: 13,
                                          height: 1.2,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter', // Ensuring consistent font
                                        ),
                                        children: _buildRouteTextSpans(display),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPeakHourInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.query_stats_rounded, color: _getIconColor(widget.station.line), size: 28),
                const SizedBox(width: 12),
                const Text("Crowd Insights", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: -0.5)),
              ],
            ),
            StreamBuilder<double>(
              stream: _crowdService.getLiveCrowdDensity(widget.station.id),
              builder: (context, snapshot) {
                final density = (snapshot.data ?? 0.0) * 100;
                final isHeavy = density > 75;
                final isModerate = density > 40 && density <= 75;
                
                Color statusColor = Colors.greenAccent.shade700;
                String statusLabel = "LIGHT";
                if (isHeavy) {
                  statusColor = Colors.redAccent;
                  statusLabel = "HEAVY";
                } else if (isModerate) {
                  statusColor = Colors.orangeAccent;
                  statusLabel = "MODERATE";
                }

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOutSine,
                    builder: (context, scale, child) {
                      final bool isOffline = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
                      
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              isOffline ? Colors.grey : statusColor, 
                              isOffline ? Colors.blueGrey : statusColor.withValues(alpha: 0.7)
                            ]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: (isOffline ? Colors.grey : statusColor).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isOffline ? Icons.cloud_off : Icons.sensors, size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                isOffline ? "OFFLINE: CACHED" : "LIVE: $statusLabel", 
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    onEnd: () {}, 
                );
              }
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF0D1B3E).withValues(alpha: 0.02), const Color(0xFF0D1B3E).withValues(alpha: 0.08)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF0D1B3E).withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 100,
                child: Builder(
                  builder: (context) {
                    final data = _crowdService.getHistoricalHourlyInsights(widget.station.id);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _bar(data[0], "6am"),
                        _bar(data[2], "8am", isPeak: true),
                        _bar(data[4], "11am", isBest: true),
                        _bar(data[6], "2pm", isBest: true),
                        _bar(data[8], "5pm", isPeak: true),
                        _bar(data[9], "8pm"),
                        _bar(data[11], "10pm"),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 32),
              
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.tips_and_updates, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Optimized Travel Window", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                        Text("Board between 11 AM - 3 PM for 40% less crowding.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bar(double height, String label, {bool isPeak = false, bool isBest = false}) {
    Color barColor = const Color(0xFF0D1B3E).withValues(alpha: 0.2);
    if (isPeak) barColor = Colors.redAccent.withValues(alpha: 0.7);
    if (isBest) barColor = Colors.greenAccent.shade700.withValues(alpha: 0.7);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 14,
          height: 60 * height,
          decoration: BoxDecoration(
            color: barColor, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            boxShadow: isPeak ? [BoxShadow(color: Colors.red.withValues(alpha: 0.1), blurRadius: 4)] : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFareMatrix() {
    final userType = _settings.userType;
    final fare = _selectedDest != null ? FareService().getFareResult(widget.station, _selectedDest!, userType: userType) : {'sj': 0.0};
    final bool isDiscounted = fare['isDiscounted'] == 1;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_rounded, color: _getIconColor(widget.station.line), size: 20),
              const SizedBox(width: 10),
              const Text("Fare Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Select destination to see estimated cost:", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Station>(
                isExpanded: true,
                value: _selectedDest,
                hint: const Text("Select Destination"),
                items: _stationLine.stations
                    .where((s) => s.id != widget.station.id && !s.isExtension)
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (val) => setState(() => _selectedDest = val),
              ),
            ),
          ),
          if (_selectedDest != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDiscounted ? Colors.blue.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDiscounted ? Colors.blue.shade100 : Colors.green.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDiscounted ? "${userType.toUpperCase()} FARE" : "SINGLE JOURNEY FARE",
                        style: TextStyle(color: isDiscounted ? Colors.blue.shade700 : Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                      const Text("Estimated Cost", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Text(
                    "PHP ${fare['sj']}",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20)), child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)));
  }

  Widget _buildAccessibilityIcon(IconData icon, bool isAvailable, String label) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isAvailable ? _getLineColor(widget.station.line).withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: isAvailable ? _getLineColor(widget.station.line).withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.1)),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isAvailable ? _getIconColor(widget.station.line) : Colors.grey.shade400,
              ),
            ),
            if (!isAvailable)
              const Icon(
                Icons.close_rounded,
                size: 28,
                color: Colors.redAccent,
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingArrivals(Station station) {
    final isLRT2 = station.line.contains('LRT2');
    String northLabel = isLRT2 ? "Westbound" : "Northbound";
    String southLabel = isLRT2 ? "Eastbound" : "Southbound";

    return StreamBuilder<List<LiveTrainReport>>(
      stream: LiveTrainService().getLiveTrains(),
      builder: (context, snapshot) {
        // 1. Get Scheduled Arrivals
        final List<StationArrival> scheduled =
            GtfsSimulationService.getArrivalsForStation(station.id);

        // 2. Get Live Crowdsourced Arrivals
        final List<StationArrival> live =
            GtfsSimulationService.calculateLiveArrivals(
                station.id, snapshot.data ?? []);

        // 3. Merge: Prioritize Live over Scheduled if ETAs are close
        final List<StationArrival> combined = [...live];
        for (var sch in scheduled) {
          bool isRedundant = live.any((l) =>
              l.isNorthbound == sch.isNorthbound &&
              (l.minutesUntil - sch.minutesUntil).abs() <= 3);
          if (!isRedundant) {
            combined.add(sch);
          }
        }

        combined.sort((a, b) => a.minutesUntil.compareTo(b.minutesUntil));

        final northbound = combined.where((a) => a.isNorthbound).toList();
        final southbound = combined.where((a) => !a.isNorthbound).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        color: _getIconColor(station.line), size: 24),
                    const SizedBox(width: 12),
                    const Text("Upcoming Arrivals",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showTrackerInfo(context),
                      child: const Icon(Icons.help_outline,
                          size: 16, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (combined.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200)),
                child: const Center(
                    child: Text("No upcoming trains scheduled at this time.",
                        style: TextStyle(color: Colors.grey, fontSize: 13))),
              )
            else ...[
              // Toggle Segmented Control
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildToggleItem(0, northLabel, station),
                    _buildToggleItem(1, southLabel, station),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildDirectionSection(
                _selectedDirectionIndex == 0 ? northLabel : southLabel,
                _selectedDirectionIndex == 0 ? northbound : southbound,
                station,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildToggleItem(int index, String label, Station station) {
    bool isSelected = _selectedDirectionIndex == index;
    Color activeColor = _getIconColor(station.line);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDirectionIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected 
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionSection(String label, List<StationArrival> arrivals, Station station) {
    final Color lineColor = _getLineColor(station.line);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: lineColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _getIconColor(station.line), letterSpacing: 1.0),
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text("${arrivals.length} trains", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        if (arrivals.isEmpty)
          const Text("No more trains scheduled in this direction.", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))
        else
          ...arrivals.map((a) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: (a.isLive ? Colors.red : lineColor)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                      a.isLive ? Icons.sensors_rounded : Icons.train_rounded,
                      color: a.isLive ? Colors.redAccent : lineColor,
                      size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.trainsetModel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, overflow: TextOverflow.ellipsis)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (a.isLive) ...[
                            _smallBadge("LIVE TRACK", Colors.redAccent),
                            const SizedBox(width: 6),
                          ],
                          _smallBadge(a.generation, Colors.blueGrey),
                          const SizedBox(width: 6),
                          _smallBadge(a.cooling, Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${a.minutesUntil}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),
                    const Text("MINS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          )),
      ],
    );
  }

  Widget _smallBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }

  void _showTrackerInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Why is this simulated?"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Currently, Metro Manila's train operators (LRT and MRT) do not provide a public real-time API for train locations.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              "Because of this, we use the official timetables to 'simulate' where trains should be, ensuring you always have a schedule even in areas with no data.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              "When real commuters are on board, you will see 'Live' markers which represent the actual real-time position of the train.",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it"))],
      ),
    );
  }

  Widget _buildSocialPulse(Station station) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_alt_rounded, color: _getIconColor(station.line), size: 24),
            const SizedBox(width: 12),
            const Text("Social Pulse", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<String>(
          stream: _crowdService.getSocialStatusStream(station.id),
          builder: (context, snapshot) {
            final status = snapshot.data ?? 'No recent reports';
            final Color color = _getStatusColor(status);
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.forum_outlined, color: color, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Community says current crowd is: ${status.toUpperCase()}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text("Report current station status:", style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statusButton(station.id, "light", Icons.sentiment_satisfied_alt_rounded, Colors.green),
            _statusButton(station.id, "moderate", Icons.sentiment_neutral_rounded, Colors.orange),
            _statusButton(station.id, "heavy", Icons.sentiment_very_dissatisfied_rounded, Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _statusButton(String stationId, String status, IconData icon, Color color) {
    return InkWell(
      onTap: () async {
        final success = await _crowdService.reportSocialStatus(stationId, status);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Reported as $status. Thank you for helping commuters!"),
              backgroundColor: color.withValues(alpha: 0.9),
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Failed to report status. Please check your connection."),
              backgroundColor: Colors.redAccent,
            ));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)]),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'light': return Colors.green;
      case 'moderate': return Colors.orange;
      case 'heavy': return Colors.red;
      default: return Colors.blueGrey;
    }
  }

  Color _getLineColor(String line) {
    if (line == 'LRT1') return const Color(0xFF4CAF50);
    if (line == 'LRT2') return const Color(0xFF9C27B0);
    if (line == 'MRT3') return const Color(0xFFFFEB3B);
    if (line == 'MRT-7') return const Color(0xFFEF5350);
    if (line == 'MMS' || line.contains('Subway')) return const Color(0xFF1E3A8A);
    if (line == 'NSCR') return const Color(0xFF800000);
    if (line == 'MRT-4') return const Color(0xFF009688);
    return Colors.indigo;
  }

  Color _getIconColor(String line) {
    if (line == 'MRT3') return Colors.black; // Better accessibility on yellow
    return _getLineColor(line);
  }
}
