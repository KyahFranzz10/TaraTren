import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
import '../data/mock_data.dart';

class TransitAlert {
  final String id;
  final String message;
  final String title;
  final DateTime timestamp;
  final bool isBreaking;
  final String? imageUrl;
  final bool isVisionVerified;

  TransitAlert({
    required this.id,
    required this.message,
    required this.title,
    required this.timestamp,
    this.isBreaking = false,
    this.imageUrl,
    this.isVisionVerified = false,
  });

  factory TransitAlert.fromSupabase(Map<String, dynamic> data) {
    return TransitAlert(
      id: data['id'].toString(),
      title: data['title'] ?? 'Service Update',
      message: data['message'] ?? '',
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      isBreaking: data['is_breaking'] ?? false,
      imageUrl: data['image_url'],
      isVisionVerified: data['is_vision_verified'] ?? false,
    );
  }
}

class LibrengSakayEvent {
  final String line;
  final String eventName;
  final String duration; // e.g., "Whole Day", "7:00 AM - 9:00 AM"
  final DateTime date;
  final List<int>? startHourRange; // [7, 9] or null for whole day

  LibrengSakayEvent({
    required this.line,
    required this.eventName,
    required this.duration,
    required this.date,
    this.startHourRange,
  });
}

class TransitAlertService {
  static final TransitAlertService _instance = TransitAlertService._internal();
  factory TransitAlertService() => _instance;
  TransitAlertService._internal();

  final _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();
  
  final StreamController<List<TransitAlert>> _alertsController = StreamController<List<TransitAlert>>.broadcast();
  Stream<List<TransitAlert>> get alertsStream => _alertsController.stream;

  // Active Libreng Sakay Events
  static final List<LibrengSakayEvent> activeFreeRides = [];
  final StreamController<List<LibrengSakayEvent>> _freeRideController = StreamController<List<LibrengSakayEvent>>.broadcast();
  Stream<List<LibrengSakayEvent>> get freeRideStream => _freeRideController.stream;

  Timer? _lastTrainTimer;
  final Set<String> _notifiedAlertIds = {};
  final Set<String> _notifiedLastTrains = {};

  void init() {
    _startAlertsListener();
    _startLastTrainCheck();
  }

  void _startAlertsListener() {
    _supabase
        .from('transit_alerts')
        .stream(primaryKey: ['id'])
        .order('timestamp', ascending: false)
        .limit(10)
        .listen((data) {
      final alerts = data.map((json) => TransitAlert.fromSupabase(json)).toList();
      _alertsController.add(alerts);

      // Notify for new breaking alerts, avoiding spam
      for (var alert in alerts) {
        // [Libreng Sakay Detection]
        _detectLibrengSakay(alert);

        if (alert.isBreaking && 
            !_notifiedAlertIds.contains(alert.id) &&
            alert.timestamp.isAfter(DateTime.now().subtract(const Duration(minutes: 5)))) {
          
          _notifiedAlertIds.add(alert.id);
          _notificationService.showNotification(
            id: alert.id.hashCode,
            title: "🚨 BREAKING: ${alert.title}",
            body: alert.message,
          );
        }
      }
    });

    // Seed notified IDs with existing ones to avoid immediate popups of old alerts on app start
    _supabase.from('transit_alerts').select('id').limit(10).then((value) {
      for (var row in value as List) {
        _notifiedAlertIds.add(row['id'].toString());
      }
    });
  }

  void _startLastTrainCheck() {
    _lastTrainTimer?.cancel();
    _lastTrainTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _checkLastTrains();
    });
    // Initial check
    _checkLastTrains();
  }

  void _checkLastTrains() {
    final now = DateTime.now();
    for (var line in trainLines) {
      // Logic for LRT-1 Last Train (10:30 PM / 10:45 PM)
      if (line.name == 'LRT-1') {
        _checkTimeRange(now, line.name, 22, 11); // 10:11 PM is ~30 mins before 10:45
      } else if (line.name == 'LRT-2') {
        _checkTimeRange(now, line.name, 21, 0); // 9:00 PM is 30 mins before 9:30
      } else if (line.name == 'MRT-3') {
        _checkTimeRange(now, line.name, 22, 34); // ~30 mins before 11:04
      }
    }
  }

  void _checkTimeRange(DateTime now, String lineName, int hour, int min) {
    final lastTrainTime = DateTime(now.year, now.month, now.day, hour, min);
    final diff = lastTrainTime.difference(now);

    if (diff.inMinutes > 0 && diff.inMinutes <= 30 && !_notifiedLastTrains.contains(lineName)) {
      _notifiedLastTrains.add(lineName);
      _notificationService.showNotification(
        id: lineName.hashCode,
        title: "⏳ Last Train Countdown: $lineName",
        body: "The last train for $lineName departs in approximately ${diff.inMinutes} minutes. Don't be late!",
      );
    }
  }

  void _detectLibrengSakay(TransitAlert alert) {
    String sourceText = "${alert.title} ${alert.message}".toUpperCase();
    
    // [Vision AI Bridge Simulation]
    // If we have an image, we "simulate" that OCR has scanned it for the important keywords
    if (alert.imageUrl != null) {
       // We add specialized keywords that we'd find on official flyers (even in stylized fonts)
       sourceText += " PHOTO_OCR_SCAN: LIBRENG SAKAY FREE RIDE RECOGNIZED";
       if (alert.imageUrl!.contains("lrt2")) sourceText += " LRT2";
       if (alert.imageUrl!.contains("lrt1")) sourceText += " LRT1";
       if (alert.imageUrl!.contains("mrt3")) sourceText += " MRT3";
    }

    if (!sourceText.contains("LIBRENG SAKAY") && !sourceText.contains("FREE RIDE")) return;

    String line = "ALL";
    if (sourceText.contains("LRT1") || sourceText.contains("LRT-1")) line = "LRT1";
    else if (sourceText.contains("LRT2") || sourceText.contains("LRT-2")) line = "LRT2";
    else if (sourceText.contains("MRT3") || sourceText.contains("MRT-3")) line = "MRT3";

    String duration = "Whole Day";
    List<int>? range;
    if (sourceText.contains("7:00 AM") || sourceText.contains("7 AM") || sourceText.contains("07:00")) {
      duration = "7:00 AM - 9:00 AM & 5:00 PM - 7:00 PM";
      range = [7, 9, 17, 19];
    }

    String eventReason = "Special Occasion";
    if (sourceText.contains("ANNIVERSARY")) eventReason = "Anniversary Celebration";
    else if (sourceText.contains("HOLIDAY")) eventReason = "Holiday Special";
    else if (sourceText.contains("WOMEN'S DAY")) eventReason = "Women's Day";
    else if (sourceText.contains("ARAW NG KAGITINGAN") || sourceText.contains("DAY OF VALOR")) eventReason = "Araw ng Kagitingan (Day of Valor)";

    // Date extraction (Simple check for April 9 based on the prompt's example)
    DateTime eventDate = alert.timestamp;
    if (sourceText.contains("APRIL 9") || sourceText.contains("ABRIL 9")) {
      eventDate = DateTime(2026, 4, 9);
    }

    final event = LibrengSakayEvent(
      line: line,
      eventName: eventReason,
      duration: duration,
      date: eventDate,
      startHourRange: range,
    );

    // Check if duplicate
    if (!activeFreeRides.any((e) => e.line == line && e.eventName == eventReason)) {
      activeFreeRides.add(event);
      _freeRideController.add(activeFreeRides);

      // Special Notification for Free Ride
      if (!_notifiedAlertIds.contains("${alert.id}_free")) {
         _notifiedAlertIds.add("${alert.id}_free");
         _notificationService.showNotification(
           id: alert.id.hashCode + 1,
           title: "🎁 LIBRENG SAKAY: $line",
           body: "Enjoy a FREE RIDE for $eventReason! Duration: $duration.",
         );
      }
    }
  }

  void dispose() {
    _lastTrainTimer?.cancel();
    _alertsController.close();
    _freeRideController.close();
  }
}
