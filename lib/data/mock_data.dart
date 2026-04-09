import '../models/station.dart';
import 'metro_stations.dart';

final List<TrainLine> trainLines = [
  TrainLine(
    name: 'LRT-1',
    color: 0xFF4CAF50, // Green Line
    scheduleSummary: '4:30 AM - 10:45 PM',
    fullSchedule:
        'Dr. Santos (South): 4:30 AM (WD) | 5:00 AM (WE)\nFPJ (North): 4:30 AM (Daily)\nLast Train: 10:30 PM (South) | 10:45 PM (North)',
    fareInfo: [
      'Stored Value: PHP 16.00 (min) - PHP 52.00 (max)',
      'Single Journey: PHP 20.00 (min) - PHP 55.00 (max)',
      'Senior/Student (SV/SJ): 20% / 50% discount applies',
    ],
    logoAsset: 'assets/image/LRTA.png',
    coverAsset: 'assets/image/Stations/LRT1/LRTA-2-4G.jpg',
    stations: metroStations
        .where((s) => s['line'] == 'LRT1')
        .map((s) => Station.fromMap(s))
        .toList(),
  ),
  TrainLine(
    name: 'LRT-2',
    color: 0xFF9C27B0, // Purple Line
    scheduleSummary: '5:00 AM - 9:30 PM',
    fullSchedule:
        'Antipolo (East): 5:00 AM - 9:30 PM\nRecto (West): 5:00 AM - 9:00 PM',
    fareInfo: ['Standard fare rates apply.', 'Beep card and SJTs available.'],
    logoAsset: 'assets/image/LRTA.png',
    coverAsset: 'assets/image/Stations/LRT2/LRT2-2-TREN.jpg',
    stations: metroStations
        .where((s) => s['line'] == 'LRT2')
        .map((s) => Station.fromMap(s))
        .toList(),
  ),
  TrainLine(
    name: 'MRT-3',
    color: 0xFFFFEB3B, // Yellow Line
    scheduleSummary: '4:20 AM - 11:04 PM',
    fullSchedule:
        'North Ave: 4:20 AM - 10:25 PM (WD) | 9:25 PM (WE)\nTaft Ave: 4:55 AM - 11:04 PM (WD) | 10:04 PM (WE)',
    fareInfo: [
      'Fare: PHP 13.00 (min) - PHP 28.00 (max)',
      'PHP 1.00 discount per leg for Beep.'
    ],
    logoAsset: 'assets/image/MRT3.jpg',
    coverAsset: 'assets/image/Stations/MRT3/MRT3-2-TRAIN.jpg',
    stations: metroStations
        .where((s) => s['line'] == 'MRT3')
        .map((s) => Station.fromMap(s))
        .toList(),
  ),
  TrainLine(
    name: 'MRT-7',
    color: 0xFFF44336, // Red Line
    scheduleSummary: 'Expected 2025/2026',
    fullSchedule:
        'Line is currently under construction.\nProjected full operation: 2026.',
    fareInfo: ['Fare matrix to be announced by SMC/DOTR.'],
    logoAsset: 'assets/image/MRT7.png',
    coverAsset: 'assets/image/Stations/MRT7/MRT-7_trains_2021.png',
    stations: metroStations
        .where((s) => s['line'] == 'MRT-7')
        .map((s) => Station.fromMap(s))
        .toList(),
  ),
  TrainLine(
    name: 'Metro Manila Subway',
    color: 0xFF2196F3, // Blue Line
    scheduleSummary: 'Expected 2028',
    fullSchedule:
        'Metro Manila Subway Phase 1 is under construction.\nValenzuela to North Ave (Partial): 2026/2027.',
    fareInfo: ['Fare structure to follow DOTR standardized rates.'],
    logoAsset: '-',
    coverAsset: '-', // Temporary placeholder for Subway
    stations: metroStations
        .where((s) => s['line'] == 'Metro Manila Subway')
        .map((s) => Station.fromMap(s))
        .toList(),
  ),
  TrainLine(
    name: 'North-South Commuter Railway',
    color: 0xFFFF5722, // Orange Line
    scheduleSummary: 'Phase 1 Expected 2026',
    fullSchedule:
        'Malolos to Valenzuela partial operation: 2026.\nFull Tutuban to Clark: 2027/2028.',
    fareInfo: ['Regular/Commuter fares to be announced.'],
    logoAsset: 'assets/image/PNR_Logo.png',
    coverAsset: 'assets/image/Stations/NSCR/PNR_NSCR_train_2021.jpg',
    stations: metroStations
        .where((s) => s['line'] == 'NSCR')
        .map((s) => Station.fromMap(s))
        .toList(),
  ),
];
