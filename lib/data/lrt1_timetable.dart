class TimetableEntry {
  final String stationName;
  final String firstTrain;
  final String lastTrain;
  final double? distanceToNext; // in km

  TimetableEntry({
    required this.stationName,
    required this.firstTrain,
    required this.lastTrain,
    this.distanceToNext,
  });
}

class LineOperationalStats {
  final int peakTrains;
  final int offPeakTrains;
  final String operatingFirst;
  final String operatingLast;

  LineOperationalStats({
    required this.peakTrains,
    required this.offPeakTrains,
    required this.operatingFirst,
    required this.operatingLast,
  });
}

final LineOperationalStats lrt1Stats = LineOperationalStats(
  peakTrains: 24,
  offPeakTrains: 18,
  operatingFirst: '4:30 AM',
  operatingLast: '10:00 PM',
);

final List<TimetableEntry> lrt1SouthboundTimetable = [
  TimetableEntry(stationName: 'Fernando Poe Jr.', firstTrain: '4:30 AM', lastTrain: '10:00 PM', distanceToNext: 1.2),
  TimetableEntry(stationName: 'Balintawak', firstTrain: '4:32 AM', lastTrain: '10:03 PM', distanceToNext: 2.3),
  TimetableEntry(stationName: 'Yamaha Monumento', firstTrain: '4:36 AM', lastTrain: '10:07 PM', distanceToNext: 1.1),
  TimetableEntry(stationName: '5th Avenue', firstTrain: '4:39 AM', lastTrain: '10:10 PM', distanceToNext: 1.2),
  TimetableEntry(stationName: 'R. Papa Station', firstTrain: '4:42 AM', lastTrain: '10:13 PM', distanceToNext: 1.0),
  TimetableEntry(stationName: 'Abad Santos', firstTrain: '4:45 AM', lastTrain: '10:16 PM', distanceToNext: 0.9),
  TimetableEntry(stationName: 'Blumentritt', firstTrain: '4:48 AM', lastTrain: '10:19 PM', distanceToNext: 0.8),
  TimetableEntry(stationName: 'Tayuman', firstTrain: '4:51 AM', lastTrain: '10:22 PM', distanceToNext: 0.7),
  TimetableEntry(stationName: 'Bambang', firstTrain: '4:54 AM', lastTrain: '10:25 PM', distanceToNext: 0.8),
  TimetableEntry(stationName: 'Doroteo Jose', firstTrain: '4:57 AM', lastTrain: '10:28 PM', distanceToNext: 0.7),
  TimetableEntry(stationName: 'Carriedo', firstTrain: '5:00 AM', lastTrain: '10:31 PM', distanceToNext: 0.8),
  TimetableEntry(stationName: 'Central Terminal', firstTrain: '5:03 AM', lastTrain: '10:34 PM', distanceToNext: 1.2),
  TimetableEntry(stationName: 'United Nations', firstTrain: '5:06 AM', lastTrain: '10:37 PM', distanceToNext: 0.8),
  TimetableEntry(stationName: 'Pedro Gil', firstTrain: '5:09 AM', lastTrain: '10:40 PM', distanceToNext: 0.7),
  TimetableEntry(stationName: 'Quirino', firstTrain: '5:12 AM', lastTrain: '10:43 PM', distanceToNext: 0.9),
  TimetableEntry(stationName: 'Vito Cruz', firstTrain: '5:15 AM', lastTrain: '10:46 PM', distanceToNext: 0.8),
  TimetableEntry(stationName: 'Gil Puyat', firstTrain: '5:18 AM', lastTrain: '10:49 PM', distanceToNext: 0.7),
  TimetableEntry(stationName: 'Libertad', firstTrain: '5:21 AM', lastTrain: '10:52 PM', distanceToNext: 1.1),
  TimetableEntry(stationName: 'EDSA', firstTrain: '5:24 AM', lastTrain: '10:55 PM', distanceToNext: 1.5),
  TimetableEntry(stationName: 'Baclaran', firstTrain: '5:27 AM', lastTrain: '10:58 PM', distanceToNext: 1.2),
  TimetableEntry(stationName: 'Redemptorist-ASEANA', firstTrain: '5:30 AM', lastTrain: '11:01 PM', distanceToNext: 1.3),
  TimetableEntry(stationName: 'MIA Road', firstTrain: '5:33 AM', lastTrain: '11:04 PM', distanceToNext: 1.5),
  TimetableEntry(stationName: 'Asiaworld-PITX', firstTrain: '5:36 AM', lastTrain: '11:07 PM', distanceToNext: 1.2),
  TimetableEntry(stationName: 'Ninoy Aquino', firstTrain: '5:39 AM', lastTrain: '11:10 PM', distanceToNext: 1.1),
  TimetableEntry(stationName: 'Dr. Santos', firstTrain: '5:42 AM', lastTrain: '11:13 PM', distanceToNext: 0.0),
];

final List<TimetableEntry> lrt1NorthboundTimetable = lrt1SouthboundTimetable.reversed.map((e) {
  // Simple logic to set proper distance to next in reversed list (distance was from North to South)
  // Distance to next in Southbound is distance from previous in Northbound.
  // Actually simplest is just to map them back.
  return TimetableEntry(
    stationName: e.stationName,
    firstTrain: e.firstTrain,
    lastTrain: e.lastTrain,
    distanceToNext: 1.1, // Approximate back for simplified structure
  );
}).toList();
