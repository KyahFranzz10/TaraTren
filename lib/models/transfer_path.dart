import 'package:latlong2/latlong.dart';

class TransferPath {
  final String fromStationId;
  final String toStationId;
  final List<LatLng> points;
  final double distanceMeters;
  final int estMinutes;
  final List<String> instructions;

  TransferPath({
    required this.fromStationId,
    required this.toStationId,
    required this.points,
    required this.distanceMeters,
    required this.estMinutes,
    required this.instructions,
  });
}
