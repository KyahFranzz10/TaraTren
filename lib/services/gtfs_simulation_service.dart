import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../services/live_train_service.dart';
import '../models/station.dart';
import '../data/mock_data.dart';
import '../data/metro_stations.dart';
import '../data/track_data.dart';
import 'service_status_service.dart';

class VirtualTrain {
  final String lineName;
  final LatLng position;
  final bool isNorthbound;
  final String trainsetModel;
  final String generation;
  final String cooling;

  VirtualTrain({
    required this.lineName, 
    required this.position, 
    required this.isNorthbound, 
    required this.trainsetModel,
    required this.generation,
    required this.cooling,
  });
}

class StationArrival {
  final String stationId;
  final String trainsetModel;
  final int minutesUntil;
  final bool isNorthbound;
  final String generation;
  final String cooling;
  final bool isLive;

  StationArrival({
    required this.stationId,
    required this.trainsetModel,
    required this.minutesUntil,
    required this.isNorthbound,
    required this.generation,
    required this.cooling,
    this.isLive = false,
  });
}

class GtfsSimulationService {
  static List<VirtualTrain> getActiveTrains() {
    if (isOperationSuspended()) return [];

    final List<VirtualTrain> activeTrains = [];
    final now = DateTime.now();
    final double currentTime = now.hour * 60 + now.minute + now.second / 60.0;
    
    final bool peak = _isPeakHour(now);
    
    for (var line in trainLines) {
      // 1. Hide future/under-construction lines entirely from the map
      final bool isFutureLine = ['MRT-7', 'Metro Manila Subway', 'North-South Commuter Railway', 'MRT-4', 'MMS', 'NSCR'].contains(line.name);
      if (isFutureLine) continue;

      // 2. Filter out non-operational (extension) stations from active lines (e.g. LRT-1 Cavite Extension)
      final List<Station> operationalStations = line.stations.where((s) => !s.isExtension).toList();
      if (operationalStations.isEmpty) continue;

      // Real-time Service Check
      final alert = ServiceStatusService().getAlertForLine(line.name);
      if (alert.status == TrainServiceStatus.suspended) continue;

      // Filter stations if service is limited (Provisional Service)
      final List<ServiceSegment>? segments = (alert.status == TrainServiceStatus.limited) ? alert.activeSegments : null;
      
      if (segments != null && segments.isNotEmpty) {
        for (var segment in segments) {
          int startIdx = operationalStations.indexWhere((s) => s.id == segment.startStationId);
          int endIdx = operationalStations.indexWhere((s) => s.id == segment.endStationId);
          if (startIdx != -1 && endIdx != -1) {
            int s = startIdx < endIdx ? startIdx : endIdx;
            int e = startIdx < endIdx ? endIdx : startIdx;
            var subStations = operationalStations.sublist(s, e + 1);
            _generateTrainsForStations(activeTrains, line.name, subStations, currentTime, peak);
          }
        }
      } else {
        _generateTrainsForStations(activeTrains, line.name, operationalStations, currentTime, peak);
      }
    }
    return activeTrains;
  }

  static void _generateTrainsForStations(
    List<VirtualTrain> activeTrains,
    String lineName,
    List<Station> stations,
    double currentTime,
    bool peak,
  ) {
    // Optimized headways to reach target train counts provided by USER:
    // LRT-1: ~20-30 peak, ~15-20 non-peak
    // LRT-2: ~9-10 peak, ~5-8 non-peak
    // MRT-3: ~18-21 peak, ~15-18 non-peak
    double headway;
    if (lineName.contains('LRT-1')) {
      headway = peak ? 3.8 : 6.0;
    } else if (lineName.contains('LRT-2')) {
      headway = peak ? 7.5 : 13.0;
    } else if (lineName.contains('MRT-3')) {
      headway = peak ? 3.5 : 4.5;
    } else {
      headway = peak ? 5.5 : 12.0;
    }

    final double speedFactor = peak ? 1.0 : 0.85; 
    const double baseTravelTime = 2.4; 
    final double travelTimeBetweenStations = baseTravelTime / speedFactor;
    final double totalTravelTime = (stations.length - 1) * travelTimeBetweenStations;

    // Dispatch window
    for (double dispatchTime = 270; dispatchTime < 1410; dispatchTime += headway) {
      _addTrainIfInTransit(activeTrains, lineName, stations, dispatchTime, currentTime, totalTravelTime, travelTimeBetweenStations, true);
      _addTrainIfInTransit(activeTrains, lineName, stations, dispatchTime, currentTime, totalTravelTime, travelTimeBetweenStations, false);
    }
  }

  static bool _isPeakHour(DateTime time) {
    if (time.weekday > 5) return false;
    final h = time.hour;
    return (h >= 7 && h < 9) || (h >= 17 && h < 19);
  }

  static void _addTrainIfInTransit(
    List<VirtualTrain> activeTrains, 
    String lineName,
    List<Station> stationsData, 
    double dispatchTime, 
    double currentTime, 
    double totalTravelTime,
    double travelTimeBetweenStations,
    bool isSouthbound
  ) {
    double progressTime = currentTime - dispatchTime;
    // Define turn-around time based on line characteristics
    final double turnAroundTime = lineName.contains('LRT-1') ? 1.5 : 8.0; 
    
    if (progressTime >= 0 && progressTime <= (totalTravelTime + turnAroundTime)) {
      final double jitter = (dispatchTime.hashCode % 40) / 60.0; 
      progressTime = (progressTime - jitter).clamp(0, totalTravelTime + turnAroundTime);

      final stations = isSouthbound ? stationsData : stationsData.reversed.toList();
      double lat, lng;

      if (progressTime <= totalTravelTime) {
        // Normal transit relative to total travel time
        double percent = progressTime / totalTravelTime;
        int totalSegments = stations.length - 1;
        double segmentIndexReal = percent * totalSegments;
        int startIndex = segmentIndexReal.floor();
        int endIndex = (startIndex + 1).clamp(0, stations.length - 1);
        
        double segmentPercent = segmentIndexReal - startIndex;
        
        LatLng startPos = LatLng(stations[startIndex].lat, stations[startIndex].lng);
        LatLng endPos = LatLng(stations[endIndex].lat, stations[endIndex].lng);
        
        final pos = TrackData.interpolateAlongTrack(lineName, startPos, endPos, segmentPercent);
        lat = pos.latitude;
        lng = pos.longitude;
      } else {
        // Turnback Sequence / At Terminus (Waiting for turn-around)
        final double turnbackProgress = progressTime - totalTravelTime;
        final bool isMrt3Taft = lineName.contains('MRT-3') && stations.last.id == 'mrt3-taft';
        
        if (isMrt3Taft) {
          // MRT-3 Taft Avenue: Stay at station (driver change only)
          lat = stations.last.lat;
          lng = stations.last.lng;
        } else {
          // Other lines: Move to turnback track if data exists
          final double moveDuration = turnAroundTime * 0.4;
          if (turnbackProgress < moveDuration) {
            final double movePercent = turnbackProgress / moveDuration;
            final pos = TrackData.getTurnbackPosition(lineName, stations.last, movePercent);
            lat = pos.latitude;
            lng = pos.longitude;
          } else {
            // Stay at turnback point
            final pos = TrackData.getTurnbackPosition(lineName, stations.last, 1.0);
            lat = pos.latitude;
            lng = pos.longitude;
          }
        }
      }
      
      final info = _getTrainInfo(lineName, dispatchTime);

      activeTrains.add(VirtualTrain(
        lineName: lineName,
        position: LatLng(lat, lng),
        isNorthbound: !isSouthbound,
        trainsetModel: info['model']!,
        generation: info['gen']!,
        cooling: info['cooling']!,
      ));
    }
  }

  static Map<String, String> _getTrainInfo(String lineName, double dispatchTime) {
    int seed = dispatchTime.toInt();
    String model = 'Standard LRV';
    String gen = 'Standard';
    String cooling = seed % 3 == 0 ? 'Comfortable' : 'Power Saving';

    if (lineName.contains('LRT-1')) {
      final models = ['3G - Kinki Sharyo', '4G - Alstom'];
      model = models[seed % models.length];
      gen = model.substring(0, 2);
      cooling = 'Strong';
    } else if (lineName.contains('LRT-2')) {
      model = 'Hyundai Rotem Class 2000';
      gen = '2000 Class';
      cooling = 'Strong (Automatic)';
    } else if (lineName.contains('MRT-3')) {
      final bool isFourCar = seed % 3 == 0;
      model = (seed % 4 == 0 ? 'Dalian 3100 Class' : 'ČKD Tatra 3000 Class') + (isFourCar ? ' (4-Car)' : ' (3-Car)');
      gen = model.contains('Dalian') ? 'Modern China-made' : 'Original Czech LRV';
      cooling = model.contains('Dalian') ? 'High (Quiet)' : 'Standard';
    }

    return {'model': model, 'gen': gen, 'cooling': cooling};
  }

  static List<StationArrival> getArrivalsForStation(String stationId) {
    if (isOperationSuspended()) return [];
    
    final arrivals = <StationArrival>[];
    
    // Check line specific status
    final station = metroStations.firstWhere((s) => s['id'] == stationId);
    final lineName = station['line'] as String;
    final alert = ServiceStatusService().getAlertForLine(lineName);
    if (alert.status == TrainServiceStatus.suspended) return [];

    final now = DateTime.now();
    final double currentTime = now.hour * 60 + now.minute + now.second / 60.0;
    
    final bool peak = _isPeakHour(now);
    final double headway = peak ? 5.5 : 12.0;
    final double travelTimeBetweenStations = peak ? 2.8 : 2.1;

    TrainLine? targetLine;
    for (var line in trainLines) {
      if (line.stations.any((s) => s.id == stationId)) {
        targetLine = line;
        break;
      }
    }

    if (targetLine == null) return [];

    // Do not simulate arrivals for future lines or extension stations
    final bool isFutureLine = ['MRT-7', 'Metro Manila Subway', 'North-South Commuter Railway', 'MRT-4', 'MMS', 'NSCR'].contains(targetLine.name);
    if (isFutureLine) return [];

    // Filter out non-operational (extension) stations
    final List<Station> operationalStations = targetLine.stations.where((s) => !s.isExtension).toList();
    
    // Provisional Service Check (Filter Stations)
    List<Station>? activeStationsRange;
    int localStationIdx = -1;

    if (alert.status == TrainServiceStatus.limited && alert.activeSegments != null && alert.activeSegments!.isNotEmpty) {
      for (var segment in alert.activeSegments!) {
        int start = operationalStations.indexWhere((s) => s.id == segment.startStationId);
        int end = operationalStations.indexWhere((s) => s.id == segment.endStationId);
        if (start != -1 && end != -1) {
          int s = start < end ? start : end;
          int e = start < end ? end : start;
          var sub = operationalStations.sublist(s, e + 1);
          int idx = sub.indexWhere((s) => s.id == stationId);
          if (idx != -1) {
            activeStationsRange = sub;
            localStationIdx = idx;
            break;
          }
        }
      }
      if (activeStationsRange == null) return []; // Not in any operational segment
    } else {
      activeStationsRange = operationalStations;
      localStationIdx = activeStationsRange.indexWhere((s) => s.id == stationId);
    }

    if (localStationIdx == -1) return []; // Station is an extension or not in this line's operational list

    final totalStations = activeStationsRange.length;
    final double totalTravelTime = (totalStations - 1) * travelTimeBetweenStations;

    for (double dispatchTime = 270; dispatchTime < 1410; dispatchTime += headway) {
      arrivals.addAll(_calculateArrival(targetLine.name, stationId, localStationIdx, dispatchTime, currentTime, totalTravelTime, travelTimeBetweenStations, true));
      arrivals.addAll(_calculateArrival(targetLine.name, stationId, totalStations - 1 - localStationIdx, dispatchTime, currentTime, totalTravelTime, travelTimeBetweenStations, false));
    }

    arrivals.sort((a, b) => a.minutesUntil.compareTo(b.minutesUntil));
    // Return up to 6 arrivals (likely 3 per direction)
    return arrivals.take(6).toList();
  }

  static List<StationArrival> _calculateArrival(
    String lineName, 
    String stationId, 
    int stationIndex, 
    double dispatchTime, 
    double currentTime, 
    double totalTravelTime,
    double travelTimeBetweenStations,
    bool isSouthbound
  ) {
    double progressTime = currentTime - dispatchTime;
    
    if (progressTime >= 0 && progressTime <= totalTravelTime) {
      double arrivalTimeAtStation = stationIndex * travelTimeBetweenStations;
      double remainingTime = arrivalTimeAtStation - progressTime;

      if (remainingTime > 0) {
        final info = _getTrainInfo(lineName, dispatchTime);
        return [StationArrival(
          stationId: stationId,
          trainsetModel: info['model']!,
          minutesUntil: remainingTime.ceil(),
          isNorthbound: !isSouthbound,
          generation: info['gen']!,
          cooling: info['cooling']!,
        )];
      }
    }
    return [];
  }

  static bool isOperationSuspended() {
    final now = DateTime.now();
    
    // Holy Week 2026 Maintenance Schedule (Maundy Thursday to Easter Sunday)
    // April 2 to April 5, 2026
    if (now.year == 2026 && now.month == 4) {
      if (now.day >= 2 && now.day <= 5) {
        return true;
      }
    }
    
    return false;
  }

  static List<StationArrival> calculateLiveArrivals(
      String stationId, List<LiveTrainReport> reports) {
    if (isOperationSuspended()) return [];

    final List<StationArrival> arrivals = [];
    final Map<String, dynamic> station =
        metroStations.firstWhere((s) => s['id'] == stationId);
    final String line = station['line'];

    for (var report in reports) {
      // Only same line and valid heading
      if (report.lineName != line || report.heading == null) continue;

      double dist = Geolocator.distanceBetween(
          report.position.latitude,
          report.position.longitude,
          station['lat'] as double,
          station['lng'] as double);

      // Bearing check: Is this train moving towards this station?
      double bearing = _calculateBearing(report.position.latitude,
          report.position.longitude, station['lat'], station['lng']);
      double angleDiff = (report.heading! - bearing).abs();
      if (angleDiff > 180) angleDiff = 360 - angleDiff;

      // Within 8km and generally heading towards the station
      if (angleDiff < 90 && dist < 8000 && dist > 100) {
        // Est speed 35km/h including stops
        int mins = (dist / (35 * 1000 / 60)).round();
        if (mins == 0) mins = 1;

        bool isNorth = report.direction?.toLowerCase().contains('north') ?? true;

        arrivals.add(StationArrival(
          stationId: stationId,
          trainsetModel: "LIVE: ${report.trainsetId.split('-').last}",
          minutesUntil: mins,
          isNorthbound: isNorth,
          generation: "Real-time Tracker",
          cooling: "Verified",
          isLive: true,
        ));
      }
    }
    return arrivals;
  }

  static double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    double lat1Rad = lat1 * pi / 180;
    double lon1Rad = lon1 * pi / 180;
    double lat2Rad = lat2 * pi / 180;
    double lon2Rad = lon2 * pi / 180;
    double dLon = lon2Rad - lon1Rad;
    double y = sin(dLon) * cos(lat2Rad);
    double x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
    double bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }
}
