import 'package:supabase_flutter/supabase_flutter.dart';

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
      'from_station': fromStation,
      'to_station': toStation,
      'line_name': line,
      'fare': fare,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TripLog.fromMap(Map<String, dynamic> map) {
    return TripLog(
      id: map['id'].toString(),
      fromStation: map['from_station'] ?? '',
      toStation: map['to_station'] ?? '',
      line: map['line_name'] ?? '',
      fare: (map['fare'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class TripLogService {
  final _supabase = Supabase.instance.client;

  Stream<List<TripLog>> getTripLogs() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('timestamp', ascending: false)
        .map((data) => data.map((json) => TripLog.fromMap(json)).toList());
  }

  Future<void> logTrip({
    required String from,
    required String to,
    required String line,
    required double fare,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('trips').insert({
      'user_id': user.id,
      'from_station': from,
      'to_station': to,
      'line_name': line,
      'fare': fare,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> clearLogs() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('trips')
        .delete()
        .eq('user_id', user.id);
  }
}
