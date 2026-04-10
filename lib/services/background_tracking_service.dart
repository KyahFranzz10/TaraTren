import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart' as far;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/metro_stations.dart';
import '../data/track_data.dart';
import 'live_train_service.dart';
import 'crowd_insight_service.dart';
import 'system_overlay_service.dart';
import 'settings_service.dart';
import 'voice_service.dart';
import 'geojson_service.dart';

class BackgroundTrackingService {
  static final BackgroundTrackingService _instance = BackgroundTrackingService._internal();
  factory BackgroundTrackingService() => _instance;
  BackgroundTrackingService._internal();

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'tara_tren_bg_channel',
      'Tara Tren Background Service',
      description: 'Used for journey tracking and battery optimization',
      importance: Importance.low,
    );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'tara_tren_bg_channel',
        initialNotificationTitle: 'TaraTren Crowdsourcing',
        initialNotificationContent: 'System optimization active...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    await Firebase.initializeApp();
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Initialize GeoJSON data for polygon-based station detection
    try {
      await GeoJsonService.loadAllLines();
    } catch (e) {
      debugPrint("BG Service Error: Critical GeoJSON load failed: $e");
      // Notify UI via Background Service instance if possible, or just log
      // In a real app, we might send this to Sentry/Firebase Crashlytics
    }

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    StreamSubscription<Position>? positionSubscription;
    StreamSubscription? activitySubscription;
    bool isStopping = false;

    service.on('stopService').listen((event) async {
      isStopping = true;
      debugPrint("BG Service: stopService event received. Cleaning up...");
      await positionSubscription?.cancel();
      await activitySubscription?.cancel();
      service.stopSelf();
    });

    final activityRecognition = far.FlutterActivityRecognition.instance;
    final LiveTrainService liveTrainService = LiveTrainService();
    
    far.ActivityType currentActivity = far.ActivityType.STILL;
    DateTime lastReportTime = DateTime.fromMillisecondsSinceEpoch(0);
    String? lastNotifTitle;
    String? lastNotifContent;
    String? lastSpokenNext;
    String? lastReportedStation;

    void updateNotification(String title, String content) {
      if (isStopping) return;
      if (service is AndroidServiceInstance) {
        if (lastNotifTitle != title || lastNotifContent != content) {
          lastNotifTitle = title;
          lastNotifContent = content;
          service.setForegroundNotificationInfo(title: title, content: content);
        }
      }
    }

    void startGpsStream() {
      if (positionSubscription != null) return;
      
      final bool isPowerSaving = prefs.getBool('power_saving_mode') ?? false;
      
        positionSubscription = Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: isPowerSaving ? LocationAccuracy.medium : LocationAccuracy.high,
            distanceFilter: isPowerSaving ? 20 : 5,
            intervalDuration: const Duration(seconds: 10),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: "TaraTren Tracking",
              notificationText: "Verifying journey trajectory...",
              enableWakeLock: true,
            ),
          ),
        ).listen((Position position) async {
          if (isStopping) return;
          double speedKph = position.speed * 3.6;

          Map<String, dynamic>? nearest;
          double minDistance = double.infinity;
          for (var station in metroStations) {
            if (station['isExtension'] == true) continue;
            double dist = Geolocator.distanceBetween(
              position.latitude, position.longitude,
              station['lat'] as double, station['lng'] as double,
            );
            if (dist < minDistance) {
              minDistance = dist;
              nearest = station;
            }
          }

          final String? activeTrack = _getTrackLine(position, nearest);
          
          if (activeTrack == null) {
            updateNotification("TaraTren Optimization", "Staying offline while on roads.");
            return;
          }

          if (activeTrack == "Transfer") {
            updateNotification("🚶 Station Transfer", "Walking to transfer line...");
            return;
          }

          if (nearest != null) {
             double distVal = Geolocator.distanceBetween(
               position.latitude, position.longitude,
               nearest['lat'] as double, nearest['lng'] as double
             );

             final lStations = metroStations.where((s) => s['line'] == activeTrack && s['isExtension'] != true).toList();
             lStations.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
             int currentIdx = lStations.indexWhere((s) => s['id'] == nearest!['id']);
             if (currentIdx == -1) currentIdx = 0;
             
             final bool isIncreasing = (activeTrack == 'LRT1' || activeTrack == 'MRT3') 
                 ? (position.heading < 45 || position.heading > 315) 
                 : (position.heading > 45 && position.heading < 135);
             
             final nextSt = isIncreasing 
                ? (currentIdx < lStations.length - 1 ? lStations[currentIdx + 1] : lStations[currentIdx])
                : (currentIdx > 0 ? lStations[currentIdx - 1] : lStations[currentIdx]);

             final double distToNext = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                nextSt['lat'] as double,
                nextSt['lng'] as double,
              );

             String paceVal = speedKph > 3.6 ? "${(60 / speedKph).toStringAsFixed(1)} min/km" : "Idle";
              
             bool isAtSt = speedKph < 5 && distVal < 120;
             final polygon = GeoJsonService.getStationPolygon(nearest['name']);
             if (polygon != null) {
               isAtSt = GeoJsonService.isPointInPolygon(
                 ll.LatLng(position.latitude, position.longitude), 
                 polygon
               );
             }

             String dir = "Orienting";
             double h = position.heading;
             if (h >= 315 || h < 45) dir = "Northbound";
             else if (h >= 45 && h < 135) dir = "Eastbound";
             else if (h >= 135 && h < 225) dir = "Southbound";
             else if (h >= 225 && h < 315) dir = "Westbound";

             try {
               final user = FirebaseAuth.instance.currentUser;
               if (user != null) {
                 await CrowdInsightService().updateCurrentStationPresence(position, user.uid);
                 
                 if (speedKph > 15) {
                    final String tId = "T-$activeTrack-${user.uid.substring(0, 6)}";
                    int interval = isPowerSaving ? 30 : 15;
                    
                    if (DateTime.now().difference(lastReportTime).inSeconds > interval) {
                      lastReportTime = DateTime.now();
                      ll.LatLng reportPos = ll.LatLng(position.latitude, position.longitude);
                      final snapped = TrackData.snapToTrack(position.latitude, position.longitude, activeTrack);
                      if (snapped != null) reportPos = snapped;
                      
                      await liveTrainService.reportLocationRTDB(
                        trainsetId: tId,
                        lineName: activeTrack,
                        pos: reportPos,
                        userId: user.uid,
                        heading: h,
                        direction: dir,
                      );
                      updateNotification("🚉 Live Train Crowdsourcing", "Reporting $activeTrack • $dir @ ${speedKph.toInt()} km/h");
                    }
                 }
               }
             } catch (e) {
               debugPrint("BG Tracking: Offline or Firebase error: $e");
             }

             final double? walkD = GeoJsonService.getWalkwayDistance(ll.LatLng(position.latitude, position.longitude));
             final bool isOnWalkway = walkD != null && walkD < 30;

             String? pStat;
             String? nStat;
             
             if (isIncreasing) {
               pStat = currentIdx > 0 ? lStations[currentIdx - 1]['name'] : null;
               nStat = currentIdx < lStations.length - 1 ? lStations[currentIdx + 1]['name'] : null;
             } else {
               pStat = currentIdx < lStations.length - 1 ? lStations[currentIdx + 1]['name'] : null;
               nStat = currentIdx > 0 ? lStations[currentIdx - 1]['name'] : null;
             }

             String statusLabel;
             String? bodyText;

             if (isAtSt) {
               statusLabel = "$dir • Stopped:";
               bodyText = "Doors Opening • Platform $dir";
             } else if (isOnWalkway) {
               statusLabel = "🚶 Transferring:";
               bodyText = "Walking to ${nearest!['name']} connection";
             } else {
               statusLabel = "$dir • Next:";
               bodyText = null;
             }

             SystemOverlayService().show(
               nextStation: nStat ?? '--',
               line: activeTrack,
               speed: speedKph.toInt(),
               currentStation: nearest!['name'],
               statusLabel: statusLabel,
               distance: distVal,
               pace: paceVal,
               isSouthbound: !isIncreasing,
               prevStation: pStat ?? '--',
               bodyText: bodyText,
             );

             LiveTrainService().reportLocationRTDB(
                trainsetId: "T-BG-$activeTrack",
                lineName: activeTrack,
                pos: ll.LatLng(position.latitude, position.longitude),
                userId: "SYSTEM_BG",
                heading: h,
                direction: dir,
              );

             if (SettingsService().isVoiceEnabled && !isOnWalkway) {
                final String currentNextId = nextSt['id'] as String;
                final String currentNextName = nextSt['name'] as String;

                // Arriving Announcement
                if (distToNext <= 300 && lastReportedStation != currentNextName) {
                  lastReportedStation = currentNextName;
                  VoiceService().announceArrival(
                     stationId: currentNextId, 
                     stationName: currentNextName, 
                     line: activeTrack,
                     isTerminus: nextSt['isTerminus'] == true,
                     opensOnLeft: nextSt['opensOnLeft'] == true,
                     connections: List<String>.from(nextSt['connections'] ?? []),
                   );
                } 
                // Next Station Announcement
                else if (speedKph > 12 && distVal > 150 && distToNext > 300 && lastSpokenNext != currentNextId) {
                    lastSpokenNext = currentNextId;
                    VoiceService().announceNextStation(
                      stationId: currentNextId, 
                      stationName: currentNextName, 
                      line: activeTrack,
                    );
                }

                // Reset triggers
                if (distVal > 2000) {
                  lastReportedStation = null;
                  lastSpokenNext = null;
                }
             }
          }
        }, onError: (e) {
        debugPrint("BG GPS Stream Error: $e");
      });
    }

    void stopGpsStream() {
      positionSubscription?.cancel();
      positionSubscription = null;
    }

    // 1. Monitor Activity and start/stop GPS accordingly
    activitySubscription = activityRecognition.activityStream.listen((activity) {
      currentActivity = activity.type;
      debugPrint("BG Activity: ${activity.type}");
      
      // Relaxed activity tracking to support station transfers and platform wait times
      bool shouldTrack = currentActivity == far.ActivityType.IN_VEHICLE || 
                         currentActivity == far.ActivityType.WALKING ||
                         currentActivity == far.ActivityType.UNKNOWN ||
                         currentActivity == far.ActivityType.STILL; // Track while waiting at platform

      if (shouldTrack) {
        startGpsStream();
      } else {
        stopGpsStream();
        updateNotification("TaraTren Power Save", "Waiting for transit movement...");
      }
    });

    // Handle initial state
    startGpsStream();
  }

  static String? _getTrackLine(Position position, Map<String, dynamic>? nearest) {
    const double thresholdMeters = 50.0;

    // Check for walkways first
    final snappedTransfer = TrackData.snapToTransfer(position.latitude, position.longitude);
    if (snappedTransfer != null) {
      if (Geolocator.distanceBetween(position.latitude, position.longitude, snappedTransfer.latitude, snappedTransfer.longitude) <= 30.0) {
        return "Transfer";
      }
    }

    final allTracks = ['LRT1', 'LRT2', 'MRT3'];
    for (var track in allTracks) {
      final snapped = TrackData.snapToTrack(position.latitude, position.longitude, track);
      if (snapped != null) {
        if (Geolocator.distanceBetween(position.latitude, position.longitude, snapped.latitude, snapped.longitude) <= thresholdMeters) {
           // Altitude check to avoid tracking buses/cars directly under the tracks
           if (track == 'LRT1' && position.altitude > 0 && position.altitude < 5.5) {
             return null;
           } else if (track == 'LRT2' && position.altitude > 0 && position.altitude < 7.0) {
             // Underground Katipunan loses GPS or drops negative, 13-16m tracks elevate far higher
             return null;
           } else if (track == 'MRT3' && nearest != null && nearest['line'] == 'MRT3') {
             String sid = nearest['id'];
             if (sid == 'mrt3-buendia' || sid == 'mrt3-ayala') {
               // Underground
               if (position.altitude > 0 && position.altitude < 5.5) return null;
             } else if (sid == 'mrt3-north-ave' || sid == 'mrt3-quezon-ave' || sid == 'mrt3-kamuning' || sid == 'mrt3-magallanes') {
               // At-Grade
             } else {
               // Elevated 
               if (position.altitude > 0 && position.altitude < 5.5) return null;
             }
           }
           return track;
        }
      }
    }
    return null;
  }
}
