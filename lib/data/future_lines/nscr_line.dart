// nscr_line.dart — North-South Commuter Railway (NSCR) Line Data
// Route: New Clark City, Tarlac → Calamba, Laguna
// Status: Partial: Dec 2027; Full: Jan 2032
// Total: 37 stations

import 'package:latlong2/latlong.dart';
import 'future_line_models.dart';
import '../future_track_data.dart';

final FutureLine nscrLine = FutureLine(
  name: 'NSCR',
  color: 0xFF800000,
  status: 'Partial: Dec 2027; Full: Jan 2032',
  logoAsset: 'assets/image/PNR_Logo.png',
  bgImage: 'assets/image/Stations/NSCR/PNR_NSCR_train_2021.jpg',
  trackPoints: FutureTrackData.nscrTrack,
  stations: [
    // ── North Segment: Tarlac/Pampanga ──────────────────────────────────────
    FutureStation(code: 'NSCR-01', name: 'New Clark City',      position: const LatLng(15.352521, 120.527444), city: 'Capas, Tarlac'),
    FutureStation(code: 'NSCR-02', name: 'Clark International Airport', position: const LatLng(15.198827, 120.556626), city: 'Clark, Pampanga'),
    FutureStation(code: 'NSCR-03', name: 'Angeles',             position: const LatLng(15.134107, 120.600593), city: 'Angeles City'),
    FutureStation(code: 'NSCR-04', name: 'San Fernando',        position: const LatLng(15.026805, 120.68681),  city: 'San Fernando, Pampanga'),
    // ── Bulacan Segment ─────────────────────────────────────────────────────
    FutureStation(code: 'NSCR-05', name: 'Apalit',              position: const LatLng(14.959203, 120.727934), city: 'Apalit, Pampanga'),
    FutureStation(code: 'NSCR-06', name: 'Calumpit',            position: const LatLng(14.902737, 120.770259), city: 'Calumpit, Bulacan'),
    FutureStation(code: 'NSCR-07', name: 'Malolos',             position: const LatLng(14.855039, 120.813431), city: 'Malolos, Bulacan'),
    FutureStation(code: 'NSCR-08', name: 'Guiguinto',           position: const LatLng(14.835085, 120.867505), city: 'Guiguinto, Bulacan'),
    FutureStation(code: 'NSCR-09', name: 'Balagtas',            position: const LatLng(14.824672, 120.906816), city: 'Balagtas, Bulacan'),
    FutureStation(code: 'NSCR-10', name: 'Bocaue',              position: const LatLng(14.798949, 120.932264), city: 'Bocaue, Bulacan'),
    FutureStation(code: 'NSCR-11', name: 'Tabing Ilog',         position: const LatLng(14.764384, 120.949345), city: 'Marilao, Bulacan'),
    FutureStation(code: 'NSCR-12', name: 'Marilao',             position: const LatLng(14.754528, 120.954452), city: 'Marilao, Bulacan'),
    FutureStation(code: 'NSCR-13', name: 'Meycauayan',          position: const LatLng(14.739649, 120.960567), city: 'Meycauayan, Bulacan'),
    // ── Metro Manila Segment ─────────────────────────────────────────────────
    FutureStation(code: 'NSCR-14', name: 'Valenzuela',          position: const LatLng(14.715203, 120.96135),  city: 'Valenzuela City'),
    FutureStation(code: 'NSCR-15', name: 'Malabon',             position: const LatLng(14.670785, 120.972519), city: 'Malabon City'),
    FutureStation(code: 'NSCR-16', name: 'Caloocan',            position: const LatLng(14.644753, 120.976135), city: 'Caloocan City'),
    FutureStation(code: 'NSCR-17', name: 'Solis',               position: const LatLng(14.626898, 120.975544), city: 'Tondo, Manila'),
    FutureStation(code: 'NSCR-18', name: 'Tutuban',             position: const LatLng(14.611367, 120.973055), city: 'Binondo, Manila'),
    FutureStation(code: 'NSCR-19', name: 'Blumentritt',         position: const LatLng(14.622507, 120.983677), city: 'Sta Cruz, Manila'),
    FutureStation(code: 'NSCR-20', name: 'España',              position: const LatLng(14.612159, 120.99675),  city: 'Sampaloc, Manila'),
    FutureStation(code: 'NSCR-21', name: 'Santa Mesa',          position: const LatLng(14.600601, 121.010266), city: 'Sta Mesa, Manila'),
    FutureStation(code: 'NSCR-22', name: 'Paco',                position: const LatLng(14.581496, 121.001326), city: 'Paco, Manila'),
    FutureStation(code: 'NSCR-23', name: 'Buendia',             position: const LatLng(14.560251, 121.006422), city: 'Makati City'),
    FutureStation(code: 'NSCR-24', name: 'EDSA',                position: const LatLng(14.542192, 121.016271), city: 'Pasay City'),
    FutureStation(code: 'NSCR-25', name: 'Senate-DepEd',        position: const LatLng(14.528764, 121.023459), city: 'Pasay City'),
    FutureStation(code: 'NSCR-26', name: 'FTI',                 position: const LatLng(14.506387, 121.035524), city: 'Taguig City'),
    FutureStation(code: 'NSCR-27', name: 'Bicutan',             position: const LatLng(14.488027, 121.045432), city: 'Paranaque City'),
    FutureStation(code: 'NSCR-28', name: 'Sucat',               position: const LatLng(14.452312, 121.052004), city: 'Paranaque City'),
    // ── South Segment: Laguna ────────────────────────────────────────────────
    FutureStation(code: 'NSCR-29', name: 'Alabang',             position: const LatLng(14.41739,  121.047664), city: 'Muntinlupa City'),
    FutureStation(code: 'NSCR-30', name: 'Muntinlupa',          position: const LatLng(14.389499, 121.047535), city: 'Muntinlupa City'),
    FutureStation(code: 'NSCR-31', name: 'San Pedro',           position: const LatLng(14.361563, 121.055346), city: 'San Pedro, Laguna'),
    FutureStation(code: 'NSCR-32', name: 'Pacita',              position: const LatLng(14.346929, 121.063542), city: 'San Pedro, Laguna'),
    FutureStation(code: 'NSCR-33', name: 'Biñan',               position: const LatLng(14.331378, 121.081159), city: 'Biñan, Laguna'),
    FutureStation(code: 'NSCR-34', name: 'Santa Rosa',          position: const LatLng(14.31275,  121.102295), city: 'Santa Rosa, Laguna'),
    FutureStation(code: 'NSCR-35', name: 'Cabuyao',             position: const LatLng(14.278722, 121.126735), city: 'Cabuyao, Laguna'),
    FutureStation(code: 'NSCR-36', name: 'Banlic',              position: const LatLng(14.232188, 121.145597), city: 'Calamba, Laguna'),
    FutureStation(code: 'NSCR-37', name: 'Calamba',             position: const LatLng(14.195184, 121.160939),  city: 'Calamba, Laguna'),
  ],
);
