import 'package:latlong2/latlong.dart';
import '../models/transfer_path.dart';

final List<TransferPath> transferPaths = [
  TransferPath(
    fromStationId: 'lrt1-doroteo-jose',
    toStationId: 'lrt2-recto',
    distanceMeters: 310,
    estMinutes: 5,
    points: [
      const LatLng(14.605216, 120.982282), // D. Jose Entrance
      const LatLng(14.605200, 120.982684),
      const LatLng(14.605076, 120.982862), // Bridge Pivot
      const LatLng(14.604785, 120.982808),
      const LatLng(14.604198, 120.982690),
      const LatLng(14.603897, 120.982620),
      const LatLng(14.603923, 120.982486), // Recto Entrance
    ],
    instructions: [
      "Exit the train at Doroteo Jose Station.",
      "Follow the signs for 'Transfer to LRT-2 Recto'.",
      "Walk through the elevated walkway above Recto Avenue.",
      "Arrive at the LRT-2 Recto Station concourse (near ticketing level)."
    ],
  ),
  TransferPath(
    fromStationId: 'lrt1-edsa',
    toStationId: 'mrt3-taft',
    distanceMeters: 140,
    estMinutes: 3,
    points: [
      const LatLng(14.538485, 121.000789), // EDSA Walkway Start
      const LatLng(14.538126, 121.000843),
      const LatLng(14.537914, 121.000865),
      const LatLng(14.537805, 121.000945),
      const LatLng(14.537763, 121.001058),
      const LatLng(14.537779, 121.001181), // Taft Ave Entrance
    ],
    instructions: [
      "Exit LRT-1 EDSA Station.",
      "Take the elevated walkway connecting to Metropoint Mall.",
      "Continue across the bridge towards Taft Avenue.",
      "Enter the MRT-3 Taft Avenue Station gateway."
    ],
  ),
  TransferPath(
    fromStationId: 'lrt2-cubao',
    toStationId: 'mrt3-cubao',
    distanceMeters: 450,
    estMinutes: 8,
    points: [
      const LatLng(14.622564, 121.052855), // LRT-2 Cubao Exit
      const LatLng(14.621925, 121.053168),
      const LatLng(14.621697, 121.052728), // Farmers Market Entrance
      const LatLng(14.620960, 121.052642),
      const LatLng(14.620197, 121.052379),
      const LatLng(14.619722, 121.052593),
      const LatLng(14.619558, 121.052336), 
      const LatLng(14.619283, 121.051784),
      const LatLng(14.619078, 121.051413), // MRT-3 Cubao Entrance
    ],
    instructions: [
      "Exit LRT-2 Araneta Center-Cubao Station.",
      "Follow 'Transfer' signs towards Farmers Market Mall.",
      "Walk through the air-conditioned mall walkway.",
      "Exit the mall towards the MRT-3 Station north entrance.",
      "Arrive at MRT-3 Araneta Center-Cubao Station."
    ],
  ),
];
