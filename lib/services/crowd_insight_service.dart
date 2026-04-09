import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../data/metro_stations.dart';

class CrowdInsightService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // 1. Report our current location to help others (Privacy-First: Just tell station we are at)
  Future<void> updateCurrentStationPresence(Position pos, String? userId) async {
    if (userId == null) return;
    
    // Find nearest station within 500m
    Map<String, dynamic>? currentStation;
    double minDistance = 500.0;
    
    for (var station in metroStations) {
      double d = Geolocator.distanceBetween(pos.latitude, pos.longitude, station['lat'], station['lng']);
      if (d < minDistance) {
        minDistance = d;
        currentStation = station;
      }
    }
    
    if (currentStation != null) {
      await _db.collection('crowd_presence').doc(userId).set({
        'stationId': currentStation['id'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 2. Get Real-Time Crowd Density for a station (Active devices in last 10 mins)
  Stream<double> getLiveCrowdDensity(String stationId) {
    try {
      final tenMinsAgo = DateTime.now().subtract(const Duration(minutes: 10));
      
      return _db.collection('crowd_presence')
          .where('stationId', isEqualTo: stationId)
          .where('updatedAt', isGreaterThan: Timestamp.fromDate(tenMinsAgo))
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              // Simulated dynamic density based on time if no real users are active
              final hour = DateTime.now().hour;
              if (hour >= 7 && hour <= 9) return 0.85; // Simulated morning peak
              if (hour >= 17 && hour <= 19) return 0.92; // Simulated evening peak
              return 0.15; // Base density
            }
            int userCount = snapshot.docs.length;
            // Increased sensitivity: 12 reports = full density (more realistic for app adoption)
            double density = userCount / 12.0; 
            return density.clamp(0.0, 1.0);
          });
    } catch (e) {
      return Stream.value(0.25); // Fallback mock value
    }
  }

  // 3. Social Pulse: Allow users to report current crowd status manually
  Future<bool> reportSocialStatus(String stationId, String status) async {
    try {
      await _db.collection('social_crowd_reports').add({
        'stationId': stationId,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint("Error reporting social status: $e");
      return false;
    }
  }

  // 4. Get active social reports for last 15 mins
  Stream<String> getSocialStatusStream(String stationId) {
    try {
      final fifteenMinsAgo = DateTime.now().subtract(const Duration(minutes: 15));
      return _db.collection('social_crowd_reports')
          .where('stationId', isEqualTo: stationId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(fifteenMinsAgo))
          // Removed orderBy to avoid missing composite index errors (sort in memory instead)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
               final hour = DateTime.now().hour;
               // Standard Rush Hours
               if (hour >= 7 && hour <= 9 || hour >= 17 && hour <= 19) return 'heavy';
               // Late Night / Evening Rushes (Student/BPO hubs often busy around 9-11 PM)
               if (hour >= 21 && hour <= 23) return 'moderate';
               return 'light';
            }

            // Sort in memory by timestamp descending 
            final docs = snapshot.docs.toList();
            docs.sort((a, b) {
               Timestamp t1 = a.get('timestamp') as Timestamp? ?? Timestamp.now();
               Timestamp t2 = b.get('timestamp') as Timestamp? ?? Timestamp.now();
               return t2.compareTo(t1);
            });
            
            final counts = <String, int>{};
            for (var doc in snapshot.docs) {
              final status = doc.get('status') as String;
              counts[status] = (counts[status] ?? 0) + 1;
            }
            
            return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
          });
    } catch (e) {
      return Stream.value('moderate'); // Fallback
    }
  }

  // 5. Mock Historical Data for Peak Hour Charts based on time of day
  List<double> getHistoricalHourlyInsights(String stationId) {
    // Return mock values based on the Philippine rush-hour standards
    return [0.2, 0.45, 0.95, 0.6, 0.55, 0.4, 0.35, 0.45, 0.9, 0.75, 0.4, 0.2];
  }
}
