import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripLog {
  final String id;
  final String fromStation;
  final String toStation;
  final String line;
  final double fare;
  final DateTime timestamp;

  TripLog({
    required this.id,
    required this.fromStation,
    required this.toStation,
    required this.line,
    required this.fare,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromStation': fromStation,
      'toStation': toStation,
      'line': line,
      'fare': fare,
      'timestamp': timestamp,
    };
  }

  factory TripLog.fromMap(String id, Map<String, dynamic> map) {
    return TripLog(
      id: id,
      fromStation: map['fromStation'],
      toStation: map['toStation'],
      line: map['line'],
      fare: map['fare'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

class TripLogService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<TripLog>> getTripLogs() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('trips')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TripLog.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> logTrip({
    required String from,
    required String to,
    required String line,
    required double fare,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('trips')
        .add({
      'fromStation': from,
      'toStation': to,
      'line': line,
      'fare': fare,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearLogs() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('trips')
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
