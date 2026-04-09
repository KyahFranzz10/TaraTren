import 'dart:async';

enum TrainServiceStatus {
  normal,
  delayed,
  suspended,
  limited;

  String get label {
    switch (this) {
      case TrainServiceStatus.normal: return 'NORMAL';
      case TrainServiceStatus.delayed: return 'DELAYED';
      case TrainServiceStatus.suspended: return 'SUSPENDED';
      case TrainServiceStatus.limited: return 'LIMITED';
    }
  }
}

class ServiceSegment {
  final String startStationId;
  final String endStationId;

  ServiceSegment({required this.startStationId, required this.endStationId});
}

class ServiceAlert {
  final String line;
  final TrainServiceStatus status;
  final String message;
  final DateTime lastUpdated;
  final List<ServiceSegment>? activeSegments; // Support for multiple loop sections

  ServiceAlert({
    required this.line,
    required this.status,
    required this.message,
    required this.lastUpdated,
    this.activeSegments,
  });
}

class ServiceStatusService {
  static final ServiceStatusService _instance = ServiceStatusService._internal();
  factory ServiceStatusService() => _instance;
  ServiceStatusService._internal();

  final Map<String, ServiceAlert> _alerts = {
    'LRT-1': ServiceAlert(
      line: 'LRT-1',
      status: TrainServiceStatus.normal,
      message: 'Service is operating normally across all stations.',
      lastUpdated: DateTime.now(),
    ),
    'LRT-2': ServiceAlert(
      line: 'LRT-2',
      status: TrainServiceStatus.normal,
      message: 'Full line from Recto to Antipolo is operational.',
      lastUpdated: DateTime.now(),
    ),
    'MRT-3': ServiceAlert(
      line: 'MRT-3',
      status: TrainServiceStatus.delayed,
      message: 'Expect 10-15 min delays due to signaling system maintenance at North Avenue.',
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  };

  Stream<Map<String, ServiceAlert>> get alertsStream => Stream.value(_alerts);

  ServiceAlert getAlertForLine(String line) {
    return _alerts[line] ?? ServiceAlert(
      line: line,
      status: TrainServiceStatus.normal,
      message: 'Status unavailable.',
      lastUpdated: DateTime.now(),
    );
  }

  // Helper for mock updates
  void updateStatus(String line, TrainServiceStatus status, String message) {
    _alerts[line] = ServiceAlert(
      line: line,
      status: status,
      message: message,
      lastUpdated: DateTime.now(),
    );
  }
}
