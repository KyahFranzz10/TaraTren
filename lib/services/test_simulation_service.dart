import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../data/metro_stations.dart';
import 'location_service.dart';

class TestSimulationService {
  static final TestSimulationService _instance = TestSimulationService._internal();
  factory TestSimulationService() => _instance;
  TestSimulationService._internal();

  Timer? _timer;
  bool isSimulating = false;

  void stopSimulation() {
    _timer?.cancel();
    isSimulating = false;
  }

  Future<void> startStationToStationSimulation(String lineName, {int speedMultiplier = 5}) async {
    stopSimulation();
    isSimulating = true;

    final lineStations = metroStations.where((s) => s['line'] == lineName && s['isExtension'] != true).toList();
    lineStations.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

    if (lineStations.length < 2) return;

    int currentIdx = 0;
    int nextIdx = 1;
    double progress = 0.0;
    
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!isSimulating) {
        timer.cancel();
        return;
      }

      final stA = lineStations[currentIdx];
      final stB = lineStations[nextIdx];
      
      double latA = stA['lat'];
      double lngA = stA['lng'];
      double latB = stB['lat'];
      double lngB = stB['lng'];

      double currentLat = latA + (latB - latA) * progress;
      double currentLng = lngA + (lngB - lngA) * progress;
      
      final position = Position(
        latitude: currentLat,
        longitude: currentLng,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 20.0,
        heading: 0.0,
        speed: (13.8 * speedMultiplier), // m/s representation
        speedAccuracy: 1.0,
        altitudeAccuracy: 1.0,
        headingAccuracy: 1.0,
      );

      LocationService().processPosition(position);
      
      double totalDist = Geolocator.distanceBetween(latA, lngA, latB, lngB);
      if (totalDist == 0) totalDist = 1;
      
      progress += (13.8 * speedMultiplier) / totalDist;

      if (progress >= 1.0) {
        progress = 0.0;
        currentIdx = nextIdx;
        nextIdx++;
        
        if (nextIdx >= lineStations.length) {
          stopSimulation();
        }
      }
    });
  }
}
