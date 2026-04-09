// mms_line.dart — Metro Manila Subway (MMS) Line Data
// Route: East Valenzuela → NAIA Terminal 3
// Status: Partial: 2028-2029; Full: 2030+
// Total: 17 stations

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'future_line_models.dart';
import '../future_track_data.dart';

final FutureLine mmsLine = FutureLine(
  name: 'Metro Manila Subway',
  color: 0xFF1E3A8A,
  status: 'Partial: 2028-2029; Full: 2030+',
  icon: Icons.subway,
  trackPoints: FutureTrackData.mmsTrack,
  stations: [
    FutureStation(code: 'MMS-01', name: 'East Valenzuela',       position: const LatLng(14.708395, 121.013761), city: 'Valenzuela'),
    FutureStation(code: 'MMS-02', name: 'Quirino Highway',       position: const LatLng(14.689373, 121.028577), city: 'Quezon City'),
    FutureStation(code: 'MMS-03', name: 'Tandang Sora',          position: const LatLng(14.674729, 121.032187), city: 'Quezon City'),
    FutureStation(code: 'MMS-04', name: 'North Avenue',          position: const LatLng(14.657655, 121.03627),  city: 'Quezon City', nearby: 'SM North, Trinoma', connections: 'MRT-3, MRT-7, LRT-1'),
    FutureStation(code: 'MMS-05', name: 'Quezon Avenue',         position: const LatLng(14.645604, 121.037482), city: 'Quezon City', connections: 'MRT-3'),
    FutureStation(code: 'MMS-06', name: 'East Avenue',           position: const LatLng(14.636687, 121.051408), city: 'Quezon City'),
    FutureStation(code: 'MMS-07', name: 'Anonas',                position: const LatLng(14.627271, 121.063886), city: 'Quezon City', connections: 'LRT-2'),
    FutureStation(code: 'MMS-08', name: 'Camp Aguinaldo',        position: const LatLng(14.612717, 121.069615), city: 'Quezon City'),
    FutureStation(code: 'MMS-09', name: 'Ortigas',               position: const LatLng(14.585432, 121.064143), city: 'Pasig', nearby: 'Meralco Ave / Ortigas Ave', connections: 'MRT-4'),
    FutureStation(code: 'MMS-10', name: 'Shaw Boulevard',        position: const LatLng(14.576294, 121.062309), city: 'Pasig'),
    FutureStation(code: 'MMS-11', name: 'Kalayaan Avenue',       position: const LatLng(14.557998, 121.055673), city: 'Makati'),
    FutureStation(code: 'MMS-12', name: 'Bonifacio Global City', position: const LatLng(14.549451, 121.054616), city: 'Taguig'),
    FutureStation(code: 'MMS-13', name: 'Lawton Avenue',         position: const LatLng(14.536667, 121.040304), city: 'Taguig'),
    FutureStation(code: 'MMS-14', name: 'Senate-DepEd',          position: const LatLng(14.528816, 121.023502), city: 'Pasay'),
    FutureStation(code: 'MMS-15', name: 'FTI',                   position: const LatLng(14.506413, 121.035562), city: 'Taguig', connections: 'NSCR'),
    FutureStation(code: 'MMS-16', name: 'Bicutan',               position: const LatLng(14.488162, 121.045475), city: 'Paranaque', connections: 'NSCR'),
    FutureStation(code: 'MMS-17', name: 'NAIA Terminal 3',       position: const LatLng(14.520403, 121.014984), city: 'Pasay City'),
  ],
);
