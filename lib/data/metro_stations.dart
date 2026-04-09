// metro_stations.dart — Master barrel file
// Combines all operational train line station data into a single list.
// To edit a specific line's stations, open the corresponding file:
//   • LRT-1 (Green Line)  → lib/data/stations/lrt1_stations.dart
//   • LRT-2 (Purple Line) → lib/data/stations/lrt2_stations.dart
//   • MRT-3 (Yellow Line) → lib/data/stations/mrt3_stations.dart

import 'stations/lrt1_stations.dart';
import 'stations/lrt2_stations.dart';
import 'stations/mrt3_stations.dart';
import 'stations/mrt7_stations.dart';
import 'stations/mms_stations.dart';
import 'stations/nscr_stations.dart';
import 'stations/lrt4_stations.dart';

export 'stations/lrt1_stations.dart';
export 'stations/lrt2_stations.dart';
export 'stations/mrt3_stations.dart';
export 'stations/mrt7_stations.dart';
export 'stations/mms_stations.dart';
export 'stations/nscr_stations.dart';
export 'stations/lrt4_stations.dart';

final List<Map<String, dynamic>> metroStations = [
  ...lrt1Stations,
  ...lrt2Stations,
  ...mrt3Stations,
  ...mrt7Stations,
  ...mmsStations,
  ...nscrStations,
  ...lrt4Stations,
];