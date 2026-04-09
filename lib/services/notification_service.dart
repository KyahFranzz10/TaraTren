import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'navigation_controller.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final String? payload = response.actionId;
        if (payload == 'view_map') {
          NavigationController().setTab(1);
        } else if (payload == 'dismiss') {
          await flutterLocalNotificationsPlugin.cancel(response.id ?? 0);
        }
      },
    );

    // Main station alerts channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'tara_tren_alerts_v3',
      'Tara Tren Voice Alerts',
      description: 'Official train voice announcements for arrivals',
      importance: Importance.max,
    );

    // Schedule & info channel (lower priority — no sound/vibration)
    const AndroidNotificationChannel infoChannel = AndroidNotificationChannel(
      'tara_tren_info_v1',
      'Tara Tren Journey Info',
      description: 'Peak hours, schedule reminders, and GPS status',
      importance: Importance.low,
    );

    // Sticky onboard tracker channel (no sound, no pop-up, persistent)
    const AndroidNotificationChannel onboardChannel = AndroidNotificationChannel(
      'tara_tren_onboard_v1',
      'Tara Tren Onboard Tracker',
      description: 'Live journey tracker while riding a train',
      importance: Importance.low,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(infoChannel);
    await androidPlugin?.createNotificationChannel(onboardChannel);
  }

  Future<void> requestPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Generic notification (used for All Aboard, etc.)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tara_tren_alerts_v3',
      'Tara Tren Voice Alerts',
      channelDescription: 'Official train voice announcements for arrivals',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      ticker: 'Tara Tren Alert',
      color: const Color(0xFF4CAF50),
      colorized: true,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Tara Tren',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('view_map', 'View Map',
            showsUserInterface: true, cancelNotification: false),
        const AndroidNotificationAction('dismiss', 'Dismiss',
            cancelNotification: true),
      ],
    );
    await flutterLocalNotificationsPlugin.show(
        id, title, body, NotificationDetails(android: androidDetails));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Station approach / entry notification  (no station code — name only)
  // ─────────────────────────────────────────────────────────────────────────
  /// [isApproach] true  → 150-m "Approaching" alert
  /// [isApproach] false → 80-m  "Entered" alert
  /// [isExit]     true  → 250-m "Left" alert
  Future<void> showStationNotification({
    required int id,
    required String stationName,
    required String line,
    required String body,
    required bool isApproach,
    bool isExit = false,
  }) async {
    final Color accentColor = _lineColor(line);
    String emoji = isApproach ? '📍' : '🚉';
    if (isExit) emoji = '👋';

    String title = isApproach
        ? '$emoji Approaching $stationName'
        : '$emoji Entered: $stationName';
    if (isExit) title = '$emoji Left: $stationName';

    String summary = isApproach ? 'Approaching Station' : 'Station Entry';
    if (isExit) summary = 'Station Exit';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tara_tren_alerts_v3',
      'Tara Tren Voice Alerts',
      channelDescription: 'Official train voice announcements for arrivals',
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      ticker: summary,
      color: accentColor,
      colorized: true,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: summary,
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('view_map', 'View Map',
            showsUserInterface: true, cancelNotification: false),
        const AndroidNotificationAction('dismiss', 'Dismiss',
            cancelNotification: true),
      ],
    );
    await flutterLocalNotificationsPlugin.show(
        id, title, body, NotificationDetails(android: androidDetails));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Journey & Ride notifications  (high importance, line-coloured)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> showJourneyNotification({
    required int id,
    required String title,
    required String body,
    required String line,
    String summary = 'Journey Update',
  }) async {
    final Color accentColor = _lineColor(line);
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tara_tren_alerts_v3',
      'Tara Tren Voice Alerts',
      channelDescription: 'Official train voice announcements for arrivals',
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      ticker: summary,
      color: accentColor,
      colorized: true,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: summary,
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('view_map', 'View Map',
            showsUserInterface: true, cancelNotification: false),
        const AndroidNotificationAction('dismiss', 'Dismiss',
            cancelNotification: true),
      ],
    );
    await flutterLocalNotificationsPlugin.show(
        id, title, body, NotificationDetails(android: androidDetails));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Schedule / timing notifications  (low importance — info channel)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> showScheduleNotification({
    required int id,
    required String title,
    required String body,
    String summary = 'Schedule Info',
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tara_tren_info_v1',
      'Tara Tren Journey Info',
      channelDescription: 'Peak hours, schedule reminders, and GPS status',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      ticker: summary,
      color: const Color(0xFF3F51B5),
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: summary,
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('dismiss', 'Dismiss',
            cancelNotification: true),
      ],
    );
    await flutterLocalNotificationsPlugin.show(
        id, title, body, NotificationDetails(android: androidDetails));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Location / proximity notifications  (default importance)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> showProximityNotification({
    required int id,
    required String title,
    required String body,
    String summary = 'Location Alert',
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tara_tren_alerts_v3',
      'Tara Tren Voice Alerts',
      channelDescription: 'Official train voice announcements for arrivals',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: false,
      enableVibration: true,
      ticker: summary,
      color: const Color(0xFF00BCD4),
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: summary,
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('view_map', 'View Map',
            showsUserInterface: true, cancelNotification: false),
        const AndroidNotificationAction('dismiss', 'Dismiss',
            cancelNotification: true),
      ],
    );
    await flutterLocalNotificationsPlugin.show(
        id, title, body, NotificationDetails(android: androidDetails));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Onboard Tracking — sticky ongoing notification
  // Stays in the notification shade while the user is riding.
  // Call repeatedly to update; call cancelOnboardTracking() on exit.
  // ─────────────────────────────────────────────────────────────────────────
  static const int onboardNotifId = 999;

  /// Shows / updates the persistent onboard tracking notification.
  ///
  /// [line]         – raw line code, e.g. "LRT1"
  /// [lineFriendly] – display name, e.g. "LRT-1 (Green Line)"
  /// [nextStation]  – name of the next station
  /// [etaSeconds]   – estimated seconds to next station (null = unknown)
  Future<void> showOnboardTracking({
    required String line,
    required String lineFriendly,
    required String nextStation,
    int? etaSeconds,
    int? speedKmH,
    String? pace,
    String? direction, // New: Current travel direction
    int? nextTrainInterval,
  }) async {
    final Color accentColor = _lineColor(line);

    // Format the ETA string
    final String etaLabel;
    if (speedKmH == 0) {
      etaLabel = 'Station Halt';
    } else if (etaSeconds == null || etaSeconds <= 0) {
      etaLabel = 'Calculating…';
    } else if (etaSeconds < 60) {
      etaLabel = 'Arriving soon';
    } else {
      final int mins = (etaSeconds / 60).round();
      etaLabel = 'ETA: ~$mins min';
    }

    final String dirTxt = direction != null ? " • $direction" : "";
    final String intervalTxt = nextTrainInterval != null ? " • Next: ${nextTrainInterval}m" : "";
    final String paceTxt = pace != null ? " · $pace" : "";
    
    // Main display strings
    final String contentTitle = '🚆 $nextStation';
    final String speedInfo = '${speedKmH ?? 0} km/h$paceTxt$dirTxt$intervalTxt';
    final String contentText = '$lineFriendly • $etaLabel\n$speedInfo';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tara_tren_onboard_v1',
      'Tara Tren Onboard Tracker',
      channelDescription: 'Live journey tracker while riding a train',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      showWhen: false,
      color: accentColor,
      colorized: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ticker: 'Tracking journey on $lineFriendly',
      styleInformation: MediaStyleInformation(
        htmlFormatContent: true,
        htmlFormatTitle: true,
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'view_map',
          'VIEW MAP',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    await flutterLocalNotificationsPlugin.show(
      onboardNotifId,
      contentTitle,
      contentText,
      NotificationDetails(android: androidDetails),
      payload: 'onboard_tracking',
    );
  }

  /// Cancels the onboard tracking notification (call when user exits the train).
  Future<void> cancelOnboardTracking() async {
    await flutterLocalNotificationsPlugin.cancel(onboardNotifId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────
  /// Returns the brand colour for a given line code.
  Color _lineColor(String line) {
    switch (line.replaceAll('-', '').toUpperCase()) {
      case 'LRT1': return const Color(0xFF4CAF50); // green
      case 'LRT2': return const Color(0xFF9C27B0); // purple
      case 'MRT3': return const Color(0xFFFFD700); // gold
      default:     return const Color(0xFF3F51B5); // indigo
    }
  }
}
