import 'package:latlong2/latlong.dart';
import '../models/transfer_path.dart';

final List<TransferPath> transferPaths = [
  TransferPath(
    fromStationId: 'lrt1-doroteo-jose',
    toStationId: 'lrt2-recto',
    distanceMeters: 280,
    estMinutes: 6,
    points: [
      const LatLng(14.6054, 120.9819), // D. Jose Station
      const LatLng(14.6048, 120.9822), // Connection bridge entrance
      const LatLng(14.6042, 120.9828), // Bridge midpoint
      const LatLng(14.6033, 120.9835), // Recto Station
    ],
    instructions: [
      "Exit the train at Doroteo Jose Station.",
      "Follow the signs for 'Transfer to LRT-2 Recto'.",
      "Walk across the elevated pedestrian bridge above Recto Avenue.",
      "Continue through the Isetann Recto entrance hall.",
      "Arrive at LRT-2 Recto Station concourse."
    ],
  ),
  TransferPath(
    fromStationId: 'lrt1-edsa',
    toStationId: 'mrt3-taft-ave',
    distanceMeters: 150,
    estMinutes: 4,
    points: [
      const LatLng(14.5389, 121.0006), // EDSA Station
      const LatLng(14.5380, 121.0010), // Connection Bridge
      const LatLng(14.5376, 121.0012), // Taft Ave entrance
    ],
    instructions: [
      "Exit LRT-1 EDSA Station.",
      "Look for the elevated walkway pointing to MRT-3.",
      "Walk along the bridge (Metropoint Mall side).",
      "Enter the MRT-3 Taft Avenue Station via the upper level."
    ],
  ),
];
