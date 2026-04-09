// mrt7_line.dart — MRT-7 Line Data
// Route: North Triangle Common Station → San Jose Del Monte, Bulacan
// Status: N. Ave to Sacred Heart: 2027; Tala & SJDM: 2028
// Total: 14 stations

import 'package:latlong2/latlong.dart';
import 'future_line_models.dart';
import '../future_track_data.dart';

final FutureLine mrt7Line = FutureLine(
  name: 'MRT-7',
  color: 0xFFEF5350,
  status: 'N. Ave to Sacred Heart: 2027; Tala & SJDM: 2028',
  logoAsset: 'assets/image/MRT7.png',
  bgImage: 'assets/image/Stations/MRT7/MRT-7_trains_2021.png',
  trackPoints: FutureTrackData.mrt7Track,
  stations: [
    FutureStation(code: 'S01/RL-01', name: 'North Triangle Common Station', position: const LatLng(14.655032, 121.032428), city: 'Quezon City', nearby: 'EDSA, North Ave', connections: 'LRT-1, MRT-3, MMS', imageUrl: 'assets/image/Stations/MRT7/North_Triangle_Station.jpg'),
    FutureStation(code: 'S02/RL-02', name: 'Quezon Memorial Circle',       position: const LatLng(14.652260, 121.047934), city: 'Quezon City', nearby: 'Quezon Memorial Circle', imageUrl: 'assets/image/Stations/MRT7/Quezon_Memorial_Circle_Station.jpg'),
    FutureStation(code: 'S03/RL-03', name: 'University Avenue',            position: const LatLng(14.654900, 121.054644), city: 'Quezon City', nearby: 'UP-Diliman', imageUrl: 'assets/image/Stations/MRT7/University_Avenue_Station.jpg'),
    FutureStation(code: 'S04/RL-04', name: 'Tandang Sora',                 position: const LatLng(14.663307, 121.067422), city: 'Quezon City', imageUrl: 'assets/image/Stations/MRT7/Tandang_Sora_Station.jpg'),
    FutureStation(code: 'S05/RL-05', name: 'Don Antonio',                  position: const LatLng(14.677013, 121.082665), city: 'Quezon City', imageUrl: 'assets/image/Stations/MRT7/Don_Antonio_Station.jpg'),
    FutureStation(code: 'S06/RL-06', name: 'Batasan',                      position: const LatLng(14.685044, 121.086247), city: 'Quezon City', imageUrl: 'assets/image/Stations/MRT7/Batasan_Station.jpg'),
    FutureStation(code: 'S07/RL-07', name: 'Manggahan',                    position: const LatLng(14.697483, 121.087351), city: 'Quezon City', imageUrl: 'assets/image/Stations/MRT7/Manggahan_Station.jpg'),
    FutureStation(code: 'S08/RL-08', name: 'Doña Carmen',                  position: const LatLng(14.705121, 121.078517), city: 'Quezon City', imageUrl: 'assets/image/Stations/MRT7/Dona_Carmen_Station.jpg'),
    FutureStation(code: 'S09/RL-09', name: 'Regalado Avenue',              position: const LatLng(14.706500, 121.068085), city: 'Quezon City', imageUrl: 'assets/image/Stations/MRT7/Regalado_Avenue_Station.jpg'),
    FutureStation(code: 'S10/RL-10', name: 'Mindanao Avenue',              position: const LatLng(14.732706, 121.061297), city: 'Quezon City', imageUrl: 'assets/image/Stations/MRT7/Mindanao_Avenue_Station.jpg'),
    FutureStation(code: 'S11/RL-11', name: 'Quirino',                      position: const LatLng(14.735423, 121.066673), city: 'Quezon City', imageUrl: 'assets/image/Stations/MRT7/Quirino_Station.jpg'),
    FutureStation(code: 'S12/RL-12', name: 'Sacred Heart',                 position: const LatLng(14.750457, 121.084018), city: 'Quezon City', imageUrl: 'assets/image/Stations/MRT7/Sacred_Heart_Station.jpg'),
    FutureStation(code: 'S13/RL-13', name: 'Tala',                         position: const LatLng(14.766054, 121.084906), city: 'Caloocan'),
    FutureStation(code: 'S14/RL-14', name: 'San Jose Del Monte',           position: const LatLng(14.784026, 121.075169), city: 'SJDM, Bulacan', nearby: 'SM SJDM, Grotto Church'),
  ],
);
