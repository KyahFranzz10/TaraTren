import 'dart:async';
import 'package:latlong2/latlong.dart';
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
    
    _timer = Timer.periodic(Duration(milliseconds: (2000 / speedMultiplier).round()), (timer) {
      if (!isSimulating) {
        timer.cancel();
        return;
      }

      final currentStation = lineStations[currentIdx];
      
      // Snap to tracks for realistic simulation that passes elevation/proximity filters
      final LatLng pos = LatLng(currentStation['lat'], currentStation['lng']);
      
      final position = Position(
        latitude: pos.latitude,
        longitude: pos.longitude,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 20.0, // High enough to pass elevation filters if any
        heading: 0.0,
        speed: 15.0 * speedMultiplier,
        speedAccuracy: 1.0,
        altitudeAccuracy: 1.0,
        headingAccuracy: 1.0,
      );

      LocationService().processPosition(position);
      
      currentIdx = (currentIdx + 1) % lineStations.length;
    });
  }
}
