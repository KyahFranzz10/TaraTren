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
import 'login_screen.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  @override
  void initState() {
    _stationLine = trainLines.firstWhere(
      (l) {
        final String searchLine = widget.station.line.toUpperCase();
        final String lName = l.name.toUpperCase();
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
    _scrollController.addListener(_scrollListener);
    _checkFavoriteStatus();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final bool collapsed = _scrollController.offset > (250 - kToolbarHeight - MediaQuery.of(context).padding.top);
      if (collapsed != _isCollapsed) {
        setState(() {
          _isCollapsed = collapsed;
        });
      }
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkFavoriteStatus() {
    _statusSubscription = _auth.getFavorites().listen((favorites) {
      if (mounted) {
        final favoriteNames = favorites.map((f) => f['station_name'] as String).toList();
        setState(() {
          _isFavorite = favoriteNames.contains(widget.station.name);
        });
      }
    });
  }

  Future<void> _toggleFavorite() async {
    if (_auth.isGuest) {
      _showAccountRequiredDialog("Favorites", "Save your most used stations for quick access and real-time arrival shortcuts.");
      return;
    }
    await _auth.toggleFavorite(widget.station.name);
  }

  void _showAccountRequiredDialog(String feature, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.orange),
            const SizedBox(width: 10),
            Text('$feature Locked'),
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

  @override
  Widget build(BuildContext context) {
    final station = widget.station;
    final bool isMRT3 = station.line == 'MRT3';
    final Color lineColor = _getLineColor(station.line);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            stretch: true,
            backgroundColor: lineColor,
            leading: BackButton(color: (isMRT3 && _isCollapsed) ? Colors.black : Colors.white),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : ((isMRT3 && _isCollapsed) ? Colors.black : Colors.white),
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 20),
              title: StreamBuilder<Map<String, dynamic>?>(
                stream: _auth.getProfileStream(),
                builder: (context, snapshot) {
                  final profileData = snapshot.data ?? {};
                  final isPrimaryHome = profileData['fav_station'] == station.name;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final double top = constraints.biggest.height;
                      final bool isCollapsed = top <= (MediaQuery.of(context).padding.top + kToolbarHeight + 10);
                      final Color titleColor = (isMRT3 && isCollapsed) ? Colors.black : Colors.white;
                      final Color subtextColor = (isMRT3 && isCollapsed) ? Colors.black54 : Colors.white70;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
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
                              ),
                              if (isPrimaryHome)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.home, color: Colors.white, size: 10),
                                      SizedBox(width: 2),
                                      Text('HOME', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ),
                            ],
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
                  );
                },
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
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
                      Divider(height: 48, color: Theme.of(context).dividerColor.withOpacity(0.1)),
                      
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
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
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.construction_rounded, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Under Construction", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14)),
                      Text("This station is not yet operational and is part of a future transit extension.", style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        _buildInfoModule(
          title: "Nearby Landmarks",
          content: station.landmark,
          icon: Icons.location_on_rounded,
          color: Colors.blueGrey,
        ),

        if (station.isTransfer) _buildWalkingGuideButton(station),

        if (station.connectingRoutes != '-' && station.connectingRoutes.isNotEmpty)
          _buildConnectingRoutesModule(station.connectingRoutes),
      ],
    );
  }

  Widget _buildWalkingGuideButton(Station station) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final relevantPath = transferPaths.firstWhere(
        (p) => p.fromStationId == station.id || p.toStationId == station.id,
      );

      return Container(
        margin: const EdgeInsets.only(top: 24),
        child: InkWell(
          onTap: () {
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
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.transfer_within_a_station_rounded, color: Colors.indigo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Walking Transfer Guide", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
                      const Text("View step-by-step path to the connected station.", style: TextStyle(fontSize: 12, color: Colors.indigo)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.indigo.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  List<InlineSpan> _buildRouteTextSpans(String text) {
    if (!text.toLowerCase().contains(" via ")) {
      return [TextSpan(text: text)];
    }

    final List<InlineSpan> spans = [];
    final RegExp viaRegex = RegExp(r'\s+(via)\s+', caseSensitive: false);
    final Iterable<RegExpMatch> matches = viaRegex.allMatches(text);

    int lastIndex = 0;
    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.normal,
        ),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }
    return spans;
  }

  Widget _buildInfoModule({required String title, required String content, required IconData icon, required Color color}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : const Color(0xFF2D3142), height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectingRoutesModule(String routes) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04), blurRadius: 10, offset: const Offset(0, 4)),
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
            Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
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
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isQCBus ? Colors.blue.withValues(alpha: 0.1) : _getLineColor(widget.station.line).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: isQCBus 
                  ? ClipOval(
                      child: Image.asset(
                        'assets/image/QuezonCityBusService.png', 
                        width: 20,
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
                            
                            final bool isBus = title.toUpperCase().contains("BUS");
                            final bool isQC = title.toUpperCase().contains("QCITY");

                            if (isBus || isQC) {
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
                                if (rawInfo.isNotEmpty && !routeObj.name.toUpperCase().contains(rawInfo.toUpperCase())) {
                                  extraInfo = " ($rawInfo)";
                                }
                                display = "$idOnly | ${routeObj.name}$extraInfo";
                              } catch (_) {}
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
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                                          fontSize: 13,
                                          height: 1.2,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                Text("Crowd Insights", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.5)),
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
                      final bool isOffline = snapshot.data == -1.0 || (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData);
                      
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
              colors: [
                (isDark ? Colors.white : const Color(0xFF0D1B3E)).withValues(alpha: 0.02), 
                (isDark ? Colors.white : const Color(0xFF0D1B3E)).withValues(alpha: 0.08)
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: (isDark ? Colors.white : const Color(0xFF0D1B3E)).withValues(alpha: 0.1)),
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
              Divider(height: 32, color: Theme.of(context).dividerColor.withOpacity(0.1)),
              
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.tips_and_updates, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Optimized Travel Window", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                        const Text("Board between 11 AM - 3 PM for 40% less crowding.", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color barColor = (isDark ? Colors.white : const Color(0xFF0D1B3E)).withValues(alpha: 0.2);
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final userType = _settings.userType;
    final fare = _selectedDest != null ? FareService().getFareResult(widget.station, _selectedDest!, userType: userType) : {'sj': 0.0};
    final bool isDiscounted = fare['isDiscounted'] == 1;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_rounded, color: _getIconColor(widget.station.line), size: 20),
              const SizedBox(width: 10),
              Text("Fare Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Select destination to see estimated cost:", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Station>(
                isExpanded: true,
                value: _selectedDest,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                hint: const Text("Select Destination"),
                items: _stationLine.stations
                    .where((s) => s.id != widget.station.id && !s.isExtension)
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87))))
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
                color: isDiscounted ? Colors.blue.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDiscounted ? Colors.blue.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDiscounted ? "${userType.toUpperCase()} FARE" : "SINGLE JOURNEY FARE",
                        style: TextStyle(color: isDiscounted ? Colors.blue.shade300 : Colors.green.shade400, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                      const Text("Estimated Cost", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Text(
                    "PHP ${fare['sj']}",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
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
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)));
  }

  Widget _buildAccessibilityIcon(IconData icon, bool isAvailable, String label) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isAvailable ? _getIconColor(widget.station.line) : Colors.grey.withValues(alpha: 0.4),
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
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white60 : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingArrivals(Station station) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final isLRT2 = station.line.contains('LRT2');
    String northLabel = isLRT2 ? "Westbound" : "Northbound";
    String southLabel = isLRT2 ? "Eastbound" : "Southbound";

    return StreamBuilder<List<LiveTrainReport>>(
      stream: LiveTrainService().getLiveTrains(),
      builder: (context, snapshot) {
        final List<StationArrival> scheduled =
            GtfsSimulationService.getArrivalsForStation(station.id);
        final List<StationArrival> live =
            GtfsSimulationService.calculateLiveArrivals(
                station.id, snapshot.data ?? []);
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
                    Text("Upcoming Arrivals",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black)),
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
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1))),
                child: const Center(
                    child: Text("No upcoming trains scheduled at this time.",
                        style: TextStyle(color: Colors.grey, fontSize: 13))),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDirectionIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
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
                color: isSelected ? (isDark && station.line == 'MRT3' ? Colors.amber : activeColor) : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionSection(String label, List<StationArrival> arrivals, Station station) {
    final Color lineColor = _getLineColor(station.line);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03), blurRadius: 8, offset: const Offset(0, 2))],
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
                      Text(a.trainsetModel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black, overflow: TextOverflow.ellipsis)),
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
                    if (a.minutesUntil == 0)
                      _pulsingArrivingBadge()
                    else if (a.minutesUntil == -1)
                      const Text("DEPARTED", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey))
                    else ...[
                      Text("${a.minutesUntil}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                      const Text("MINS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ],
                ),
              ],
            ),
          )),
      ],
    );
  }

  Widget _pulsingArrivingBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: const Text(
              "ARRIVING",
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
            ),
          ),
        );
      },
      onEnd: () {}, // Keeps the loop going if handled by a parent or just plays once per build
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text("Why is this simulated?", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Currently, Metro Manila's train operators (LRT and MRT) do not provide a public real-time API for train locations.",
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              "Because of this, we use the official timetables to 'simulate' where trains should be, ensuring you always have a schedule even in areas with no data.",
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              "When real commuters are on board, you will see 'Live' markers which represent the actual real-time position of the train.",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.greenAccent : Colors.green),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it"))],
      ),
    );
  }

  Widget _buildSocialPulse(Station station) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_alt_rounded, color: _getIconColor(station.line), size: 24),
            const SizedBox(width: 12),
            Text("Social Pulse", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<SocialPulseInfo>(
          stream: _crowdService.getSocialStatusStream(station.id),
          builder: (context, snapshot) {
            final SocialPulseInfo? info = snapshot.data;
            final status = info?.status ?? 'Processing...';
            final Color color = _getStatusColor(status);
            final bool isActualLive = info?.isLive ?? false;
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isActualLive ? Icons.verified_user_rounded : Icons.psychology_rounded, color: color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Community says current crowd is: ${status.toUpperCase()}",
                          style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13),
                        ),
                      ),
                      if (isActualLive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isActualLive 
                      ? "Based on ${info?.reportCount} verified reports in the last 15 mins."
                      : "No recent reports. Displaying typical station trends.",
                    style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.bold),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () async {
        final result = await _crowdService.reportSocialStatus(stationId, status);
        if (!context.mounted) return;
        
        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Pulse updated: ${status.toUpperCase()}!"),
            backgroundColor: color.withValues(alpha: 0.9),
            duration: const Duration(seconds: 1),
          ));
        } else if (result == "offline_saved") {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Pulse saved locally. Syncing when signal improves..."),
            backgroundColor: Colors.blueGrey,
            duration: const Duration(seconds: 3),
          ));
        } else {
          final isForbidden = result.contains("403") || result.contains("forbidden") || result.contains("policy");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isForbidden 
                ? "Security Policy Blocked: Ensure your SQL policy is active." 
                : "Error: ${result.split(':').last.trim()}"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)), 
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02), blurRadius: 4)]
        ),
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
    if (line == 'MRT3') {
      return Theme.of(context).brightness == Brightness.dark ? Colors.amber : Colors.black;
    }
    return _getLineColor(line);
  }
}
