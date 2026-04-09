class Station {
  final String id;
  final String name;
  final String line;
  final int order;
  final double lat;
  final double lng;
  final bool isTransfer;
  final bool isTerminus;
  final bool isExtension; // New: identifies future stations
  final bool opensOnLeft; // New: which side the doors open
  final List<String> connections;
  final String connectingRoutes; // New: Detailed connecting routes
  final String landmark;
  final String city; // New: city where the station is located
  final String schedule;
  final String tracker;
  final String imageUrl;
  final String structureType;
  final bool hasElevator;
  final bool hasEscalator;
  final bool isAccessible; // PWD/Senior friendly

  Station({
    required this.id,
    required this.name,
    required this.line,
    required this.order,
    required this.lat,
    required this.lng,
    required this.isTransfer,
    required this.isTerminus,
    required this.isExtension,
    required this.opensOnLeft,
    required this.connections,
    required this.structureType,
    this.city = "Unknown City",
    this.hasElevator = true,
    this.hasEscalator = true,
    this.isAccessible = true,
    this.connectingRoutes = "No connecting routes available.",
    this.landmark = "Station landmark information",
    this.schedule = "Scheduled trains will appear here.",
    this.tracker = "Live train tracking coming soon.",
    this.imageUrl = "https://images.unsplash.com/photo-1555529733-0e670560f7e1?q=80&w=1000&auto=format&fit=crop",
  });

  factory Station.fromMap(Map<String, dynamic> map) {
    String determinedStructure = map['structureType'] ?? "Elevated";
    final name = map['name'] ?? '';
    final line = map['line'] ?? '';

    // Hardcoded overrides based on official structure
    if (line == 'LRT2' && name.contains('Katipunan')) {
      determinedStructure = "Underground";
    } else if (line == 'MRT3') {
      if (name.contains('Ayala') || name.contains('Buendia')) {
        determinedStructure = "Underground";
      } else if (name.contains('Taft Avenue') || name.contains('Boni')) {
        determinedStructure = "At-Grade";
      }
    }

    return Station(
      id: map['id'] ?? '',
      name: name,
      line: line,
      order: map['order'] ?? 0,
      lat: map['lat'] ?? 0.0,
      lng: map['lng'] ?? 0.0,
      isTransfer: map['isTransfer'] ?? false,
      isTerminus: map['isTerminus'] ?? false,
      isExtension: map['isExtension'] ?? false,
      opensOnLeft: map['opensOnLeft'] ?? false,
      hasElevator: map['hasElevator'] ?? true,
      hasEscalator: map['hasEscalator'] ?? true,
      isAccessible: map['isAccessible'] ?? true,
      connections: List<String>.from(map['connections'] ?? []),
      connectingRoutes: map['connectingRoutes'] ?? "No connecting routes available.",
      landmark: map['landmark'] ?? "Station landmark information",
      city: map['city'] ?? "Unknown City",
      imageUrl: map['imageUrl'] ?? "https://images.unsplash.com/photo-1555529733-0e670560f7e1?q=80&w=1000&auto=format&fit=crop",
      structureType: determinedStructure,
    );
  }

  String get stationCode {
    String prefix = '';
    if (line == 'LRT1') {
      prefix = 'GL-';
    } else if (line == 'LRT2') {
      prefix = 'PL-';
    } else if (line == 'MRT3') {
      prefix = 'YL-';
    } else if (line == 'MRT-7') {
      prefix = 'M7-';
    } else if (line == 'MMS' || line == 'Metro Manila Subway') {
      prefix = 'MS-';
    } else if (line == 'NSCR') {
      prefix = 'NS-';
    } else if (line == 'MRT-4') {
      prefix = 'M4-';
    } else {
      prefix = 'S-';
    }
    return '$prefix${order.toString().padLeft(2, '0')}';
  }
}

class TrainLine {
  final String name;
  final List<Station> stations;
  final int color;
  final String scheduleSummary;
  final String fullSchedule;
  final List<String> fareInfo;
  final String logoAsset;
  final String coverAsset; // New: Branded cover image

  final int headwayMinutes; // Frequency in minutes
  final double averageSpeedKmh; // Avg speed for travel estimation

  TrainLine({
    required this.name,
    required this.stations,
    required this.color,
    required this.scheduleSummary,
    required this.fullSchedule,
    required this.fareInfo,
    required this.logoAsset,
    required this.coverAsset,
    this.headwayMinutes = 5, // Default 5 mins
    this.averageSpeedKmh = 35.0, // Default 35km/h
  });
}
