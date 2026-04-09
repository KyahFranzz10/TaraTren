import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';

class LiveTrainReport {
  final String trainsetId;
  final String lineName;
  final LatLng position;
  final DateTime updatedAt;
  final String reportedBy;

  final String? direction;
  final double? heading;

  LiveTrainReport({
    required this.trainsetId,
    required this.lineName,
    required this.position,
    required this.updatedAt,
    required this.reportedBy,
    this.direction,
    this.heading,
  });

  Map<String, dynamic> toMap() {
    return {
      'trainsetId': trainsetId,
      'lineName': lineName,
      'lat': position.latitude,
      'lng': position.longitude,
      'updatedAt': updatedAt.toIso8601String(),
      'reportedBy': reportedBy,
      'direction': direction,
      'heading': heading,
    };
  }
}

class LiveTrainService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseDatabase get _database => FirebaseDatabase.instance;
  
  final String _collection = 'live_trains';
  final String _dbPath = 'live_trains';

  // Report a train's live location (Crowdsourcing) to Firestore
  Future<void> reportLocation(String trainsetId, String lineName, LatLng pos, String userId, {String? direction, double? heading}) async {
    await _firestore.collection(_collection).doc(trainsetId).set({
      'trainsetId': trainsetId,
      'lineName': lineName,
      'lat': pos.latitude,
      'lng': pos.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
      'reportedBy': userId,
      'direction': direction,
      'heading': heading,
    });
  }

  // Report to Realtime Database for lower latency (Crowdsourcing)
  Future<void> reportLocationRTDB({
    required String trainsetId,
    required String lineName,
    required LatLng pos,
    required String userId,
    String? direction,
    double? heading,
  }) async {
    await _database.ref('$_dbPath/$trainsetId').set({
      'trainsetId': trainsetId,
      'lineName': lineName,
      'lat': pos.latitude,
      'lng': pos.longitude,
      'updatedAt': ServerValue.timestamp,
      'reportedBy': userId,
      'direction': direction,
      'heading': heading,
    });
  }

  // Stream of all live trains from Realtime Database for high-performance updates
  Stream<List<LiveTrainReport>> getLiveTrainsRTDB() {
    return _database.ref(_dbPath).onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final now = DateTime.now().millisecondsSinceEpoch;
      const int expiryMs = 5 * 60 * 1000; // 5 minutes

      return data.entries.map((entry) {
        final val = Map<String, dynamic>.from(entry.value);
        final int timestamp = val['updatedAt'] ?? 0;
        
        // Filter out stale reports
        if (now - timestamp > expiryMs) return null;

        return LiveTrainReport(
          trainsetId: val['trainsetId'] ?? entry.key,
          lineName: val['lineName'],
          position: LatLng(val['lat'], val['lng']),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
          reportedBy: val['reportedBy'] ?? 'Anonymous',
          direction: val['direction'],
          heading: (val['heading'] as num?)?.toDouble(),
        );
      }).whereType<LiveTrainReport>().toList();
    });
  }

  // Stream of all live trains reported in the last 5 minutes from Firestore
  Stream<List<LiveTrainReport>> getLiveTrains() {
    // Current time minus 5 minutes
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    
    return _firestore.collection(_collection)
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return LiveTrainReport(
              trainsetId: data['trainsetId'],
              lineName: data['lineName'],
              position: LatLng(data['lat'], data['lng']),
              updatedAt: (data['updatedAt'] as Timestamp).toDate(),
              reportedBy: data['reportedBy'],
              direction: data['direction'],
              heading: (data['heading'] as num?)?.toDouble(),
            );
          }).toList();
        });
  }
}
