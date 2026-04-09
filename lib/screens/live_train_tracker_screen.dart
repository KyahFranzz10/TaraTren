import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/station.dart';
import '../data/mock_data.dart';
import '../services/live_train_service.dart';
import '../services/gtfs_simulation_service.dart';
import '../services/service_status_service.dart';
import '../services/agila_scraping_service.dart';

class LiveTrainTrackerScreen extends StatefulWidget {
  final String? initialLine;
  const LiveTrainTrackerScreen({super.key, this.initialLine});

  @override
  State<LiveTrainTrackerScreen> createState() => _LiveTrainTrackerScreenState();
}

class _LiveTrainTrackerScreenState extends State<LiveTrainTrackerScreen> with SingleTickerProviderStateMixin {
  late String _selectedLine;
  final LiveTrainService _liveService = LiveTrainService();
  final ServiceStatusService _statusService = ServiceStatusService();
  final RealTimeTransitService _realTimeService = RealTimeTransitService();
  
  List<LiveTrainReport> _liveReports = [];
  List<VirtualTrain> _scheduledTrains = [];
  StreamSubscription? _liveSubscription;
  Timer? _timer;
  bool _showEstimates = true;

  @override
  void initState() {
    super.initState();
    _selectedLine = widget.initialLine ?? 'LRT-1';
    _realTimeService.startFetching();
    _realTimeService.addListener(_updateTrains);
    
    _liveSubscription = _liveService.getLiveTrains().listen((reports) {
      if (mounted) {
        setState(() {
          _liveReports = reports;
        });
      }
    });

    _updateTrains();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _updateTrains();
    });
  }

  @override
  void dispose() {
    _realTimeService.removeListener(_updateTrains);
    _liveSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _updateTrains() {
    if (mounted) {
      setState(() {
        _scheduledTrains = GtfsSimulationService.getActiveTrains();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final operationalLines = trainLines.where((l) => ['LRT-1', 'LRT-2', 'MRT-3'].contains(l.name)).toList();
    final currentLine = trainLines.firstWhere((l) => l.name == _selectedLine);
    
    // Filter trains for selected line
    final lineLiveTrains = _liveReports.where((r) => r.lineName.replaceAll('-', '').toUpperCase() == _selectedLine.replaceAll('-', '').toUpperCase()).toList();
    final lineScheduledTrains = _scheduledTrains.where((t) => t.lineName == _selectedLine).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Real-Time Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Line Selector
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B3E),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: operationalLines.length,
              itemBuilder: (context, index) {
                final line = operationalLines[index];
                final isSelected = line.name == _selectedLine;
                return GestureDetector(
                  onTap: () => setState(() => _selectedLine = line.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(line.color) : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? Colors.transparent : Colors.white24),
                    ),
                    child: Center(
                      child: Text(
                        line.name,
                        style: TextStyle(
                          color: isSelected ? (line.name == 'MRT-3' ? Colors.black : Colors.white) : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Header Status
          _buildStatusHeader(currentLine),

          // Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.blueGrey),
                const SizedBox(width: 8),
                const Text("Show Movement Forecast", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const Spacer(),
                Switch.adaptive(
                  value: _showEstimates,
                  activeColor: Colors.blue,
                  onChanged: (v) => setState(() => _showEstimates = v),
                ),
              ],
            ),
          ),

          // Live Visualization
          Expanded(
            child: _buildTrainLineVisualization(currentLine, lineLiveTrains, _showEstimates ? lineScheduledTrains : []),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(TrainLine line) {
    final alert = _statusService.getAlertForLine(line.name);
    final isActive = alert.status == TrainServiceStatus.normal || alert.status == TrainServiceStatus.limited;
    final realTimeStats = _realTimeService.stats[line.name];
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 2)],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.status == TrainServiceStatus.normal ? "NORMAL OPERATIONS" : (alert.status == TrainServiceStatus.limited ? "LIMITED SERVICE" : "SERVICE SUSPENDED"),
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isActive ? Colors.green.shade700 : Colors.red.shade700),
                  ),
                  Text(
                    "Source: ${realTimeStats?.source ?? 'Official Status Feed'}",
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Text(
                      "${realTimeStats?.runningTrains ?? 'N/A'} TRAINS",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blue),
                    ),
                    const Text("IN SERVICE", style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  ],
                ),
              ),
            ],
          ),
          if (realTimeStats != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withValues(alpha: 0.1))),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, size: 14, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Live Deployment: ${realTimeStats.runningTrains} trainsets are currently operational on ${line.name}.", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrainLineVisualization(TrainLine line, List<LiveTrainReport> liveTrains, List<VirtualTrain> scheduledTrains) {
    final stations = line.stations;
    final Color lineColor = Color(line.color);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Stack(
        children: [
          // Rail Line (Center Path)
          Positioned(
            left: 24,
            top: 20,
            bottom: 20,
            child: Container(
              width: 8,
              decoration: BoxDecoration(
                color: lineColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Stations and Trains
          Column(
            children: List.generate(stations.length, (index) {
              final station = stations[index];
              final bool isTerminal = index == 0 || index == stations.length - 1;
              
              // Find trains "at" or "near" this station segment
              final List<Widget> trainsNear = _getTrainsForStationSegment(index, stations, liveTrains, scheduledTrains, lineColor);

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Station Dot
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 56,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(left: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: lineColor, width: 3),
                                boxShadow: [BoxShadow(color: lineColor.withValues(alpha: 0.2), blurRadius: 4)],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Station Name
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                station.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isTerminal ? FontWeight.w900 : FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              if (station.isTransfer)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                  child: const Text("TRANSFER HUB", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.indigo)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Segment between stations (Where trains moving)
                  if (index < stations.length - 1)
                     Container(
                       margin: const EdgeInsets.only(left: 56),
                       child: Column(
                         children: trainsNear,
                       ),
                     ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  List<Widget> _getTrainsForStationSegment(int stationIndex, List<Station> stations, List<LiveTrainReport> liveTrains, List<VirtualTrain> scheduledTrains, Color lineColor) {
    final List<Widget> markers = [];
    final currentStation = stations[stationIndex];
    if (stationIndex >= stations.length - 1) return markers;
    final nextStation = stations[stationIndex + 1];

    // Combine trains
    final allTrains = <_TrainMapItem>[];
    for (var lt in liveTrains) {
      allTrains.add(_TrainMapItem(pos: lt.position, id: lt.trainsetId, isLive: true, line: lt.lineName));
    }
    for (var st in scheduledTrains) {
      // Check if not too close to live
      bool skip = liveTrains.any((lt) => Geolocator.distanceBetween(lt.position.latitude, lt.position.longitude, st.position.latitude, st.position.longitude) < 400);
      if (!skip) {
        allTrains.add(_TrainMapItem(pos: st.position, id: st.trainsetModel, isLive: false, isNorthbound: st.isNorthbound, line: st.lineName));
      }
    }

    for (var train in allTrains) {
      // Logic: A train is in this segment if it's geographically between current and next station
      // Simplification: Calculate distance to current and next station
      double distToCurrent = Geolocator.distanceBetween(train.pos.latitude, train.pos.longitude, currentStation.lat, currentStation.lng);
      double distToNext = Geolocator.distanceBetween(train.pos.latitude, train.pos.longitude, nextStation.lat, nextStation.lng);
      double stationDist = Geolocator.distanceBetween(currentStation.lat, currentStation.lng, nextStation.lat, nextStation.lng);

      // Relaxed "in segment" check
      if (distToCurrent + distToNext < stationDist * 1.3 && distToCurrent < stationDist && distToNext < stationDist) {
        markers.add(_buildTrainInfoCard(train, lineColor, distToNext));
      }
    }

    return markers;
  }

  Widget _buildTrainInfoCard(_TrainMapItem train, Color lineColor, double distToNext) {
    final int speed = 45 + (train.id.hashCode % 15);
    final int eta = (distToNext / (speed * 1000 / 60)).ceil();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: train.isLive 
              ? Colors.red.withValues(alpha: 0.15) 
              : Colors.black.withValues(alpha: 0.05), 
            blurRadius: train.isLive ? 15 : 10, 
            offset: const Offset(0, 2)
          )
        ],
        border: Border.all(
          color: train.isLive ? Colors.red.withValues(alpha: 0.5) : Colors.transparent,
          width: train.isLive ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          _buildTrainIcon(train, lineColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      train.id.length > 15 ? "${train.id.substring(0, 12)}..." : train.id,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (train.isLive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                        child: const Text("LIVE BEACON", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ],
                ),
                Text(
                  "${train.isNorthbound == true ? 'Northbound' : 'Southbound'} • $speed km/h",
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500),
                ),
                if (train.isLive)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "Verified by TaraTren Commuter",
                      style: TextStyle(fontSize: 8, color: Colors.red.shade400, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "ETA",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade300),
              ),
              Text(
                "$eta min",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: lineColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrainIcon(_TrainMapItem train, Color lineColor) {
    if (!train.isLive) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: lineColor.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(Icons.train, color: lineColor, size: 20),
      );
    }
    
    return Stack(
      alignment: Alignment.center,
      children: [
        _GhostPulse(color: Colors.red),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          child: const Icon(Icons.sensors, color: Colors.white, size: 18),
        ),
      ],
    );
  }
}

class _GhostPulse extends StatefulWidget {
  final Color color;
  const _GhostPulse({required this.color});

  @override
  State<_GhostPulse> createState() => _GhostPulseState();
}

class _GhostPulseState extends State<_GhostPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.color.withValues(alpha: 1.0 - _controller.value), width: 2),
          ),
        );
      },
    );
  }
}

class _TrainMapItem {
  final LatLng pos;
  final String id;
  final bool isLive;
  final bool? isNorthbound;
  final String line;

  _TrainMapItem({required this.pos, required this.id, required this.isLive, this.isNorthbound, required this.line});
}
