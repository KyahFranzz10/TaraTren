import 'package:supabase_flutter/supabase_flutter.dart';
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
      'trainset_id': trainsetId,
      'line_name': lineName,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'updated_at': updatedAt.toIso8601String(),
      'reported_by': reportedBy,
      'direction': direction,
      'heading': heading,
    };
  }

  factory LiveTrainReport.fromMap(Map<String, dynamic> map) {
    return LiveTrainReport(
      trainsetId: map['trainset_id'] ?? '',
      lineName: map['line_name'] ?? '',
      position: LatLng(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      ),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      reportedBy: map['reported_by'] ?? 'Anonymous',
      direction: map['direction'],
      heading: (map['heading'] as num?)?.toDouble(),
    );
  }
}

class LiveTrainService {
  final _supabase = Supabase.instance.client;
  
  final String _table = 'live_trains';

  // Report a train's live location (Crowdsourcing)
  Future<void> reportLocation(String trainsetId, String lineName, LatLng pos, String userId, {String? direction, double? heading}) async {
    await _supabase.from(_table).upsert({
      'trainset_id': trainsetId,
      'line_name': lineName,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'updated_at': DateTime.now().toIso8601String(),
      'reported_by': userId,
      'direction': direction,
      'heading': heading,
    });
  }

  // Supabase high-performance updates via Realtime Broadcast can also be implemented, 
  // but for now we'll stick to Table upserts with Realtime enabled on the table.
  Future<void> reportLocationRTDB({
    required String trainsetId,
    required String lineName,
    required LatLng pos,
    required String userId,
    String? direction,
    double? heading,
  }) async {
    await reportLocation(trainsetId, lineName, pos, userId, direction: direction, heading: heading);
  }

  // Stream of all live trains using Supabase Realtime
  Stream<List<LiveTrainReport>> getLiveTrains() {
    // We use a stream of the table for real-time updates
    return _supabase.from(_table)
        .stream(primaryKey: ['trainset_id'])
        .map((data) {
          return data.map((json) {
            final report = LiveTrainReport.fromMap(json);
            // Client-side filtering for stale reports
            if (report.updatedAt.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
              return null;
            }
            return report;
          }).whereType<LiveTrainReport>().toList();
        });
  }

  // High-performance stream (RTDB equivalent)
  Stream<List<LiveTrainReport>> getLiveTrainsRTDB() {
    return getLiveTrains();
  }
}
