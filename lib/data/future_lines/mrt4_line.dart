import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'future_line_models.dart';
import '../future_track_data.dart';

final FutureLine mrt4Line = FutureLine(
  name: 'MRT-4',
  color: 0xFF009688, // Teal
  status: 'Pre-construction (Approved)',
  icon: Icons.train_rounded,
  trackPoints: FutureTrackData.mrt4Track,
  stations: [
    FutureStation(code: 'MRT4-01', name: 'EDSA',             position: const LatLng(14.591127, 121.060973), city: 'Quezon City', nearby: 'EDSA / Robinsons Galleria', connections: 'MRT-3'),
    FutureStation(code: 'MRT4-02', name: 'Meralco',          position: const LatLng(14.588806, 121.06571),  city: 'Pasig', nearby: 'Meralco Ave / Ortigas Ave', connections: 'MMS'),
    FutureStation(code: 'MRT4-03', name: 'Tiendesitas',       position: const LatLng(14.589541, 121.077442), city: 'Pasig', nearby: 'Tiendesitas'),
    FutureStation(code: 'MRT4-04', name: 'Rosario',          position: const LatLng(14.590519, 121.084405), city: 'Pasig', connections: 'Pasig Ferry'),
    FutureStation(code: 'MRT4-05', name: 'St. Joseph',        position: const LatLng(14.589616, 121.098132), city: 'Cainta'),
    FutureStation(code: 'MRT4-06', name: 'Cainta Junction',   position: const LatLng(14.586595, 121.114826), city: 'Cainta'),
    FutureStation(code: 'MRT4-07', name: 'San Juan',          position: const LatLng(14.582171, 121.128902), city: 'Taytay'),
    FutureStation(code: 'MRT4-08', name: 'Tikling',           position: const LatLng(14.577831, 121.142764), city: 'Taytay'),
    FutureStation(code: 'MRT4-09', name: 'Manila East Road', position: const LatLng(14.571206, 121.144137), city: 'Taytay'),
    FutureStation(code: 'MRT4-10', name: 'Taytay',            position: const LatLng(14.565687, 121.140473), city: 'Taytay'),
  ],
);
