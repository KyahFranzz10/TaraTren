import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../data/metro_stations.dart';
import '../data/track_data.dart';
import '../models/station.dart';
import 'system_overlay_service.dart';
import 'notification_service.dart';
import 'voice_service.dart';
import 'live_train_service.dart';
import 'settings_service.dart';
import 'fare_service.dart';
import 'trip_log_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final ValueNotifier<Position?> currentPosition =
      ValueNotifier<Position?>(null);
  final ValueNotifier<String?> onboardLine = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isOnboard = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isTransferring = ValueNotifier<bool>(false);
  final ValueNotifier<String?> nextStationName = ValueNotifier<String?>(null);
  final ValueNotifier<String?> islandStatusLabel = ValueNotifier<String?>(null);
  final ValueNotifier<double?> distanceToNext = ValueNotifier<double?>(null);
  final ValueNotifier<int?> currentSpeed = ValueNotifier<int?>(0);
  final ValueNotifier<String?> prevStationName = ValueNotifier<String?>(null);
  final ValueNotifier<String?> currentStationOnboard = ValueNotifier<String?>(null);
  final ValueNotifier<String?> currentDirection = ValueNotifier<String?>(null);
  final ValueNotifier<String?> islandBodyText = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isArrivalAlert = ValueNotifier<bool>(false);

  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(accuracy: LocationAccuracy.high));
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> getNearestStation(Position position) {
    Map<String, dynamic>? closest;
    double minD = double.infinity;

    for (var station in metroStations) {
      final double dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        station['lat'] as double,
        station['lng'] as double,
      );
      if (dist < minD) {
        minD = dist;
        closest = station;
      }
    }
    return closest ?? metroStations.first;
  }

  Position? _lastPosition;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;

  // ── Geofence state ────────────────────────────────────────────────────────
  String? _activeStationId;
  final Set<String> _notifiedStations = {};
  final Set<String> _entryNotified = {};
  final Set<String> _nextStationNotified = {};
  final Set<String> _nearFavouriteSent = {};
  final Set<String> _easterEggTriggered = {};
  final Map<String, DateTime> _lastNotifiedTime = {};

  // ── Trip Logging State ──
  String? _tripStartStation;
  String? _tripEndStation;
  final Set<String> _tripLines = {};

  DateTime _lastReportTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _wasOnboard = false;
  bool _gpsLost = false;

  bool _peakHourSentMorning = false;
  bool _peakHourSentEvening = false;
  bool _lastTrainSent = false;
  DateTime _scheduleResetDate = DateTime(0);
  int _offboardCount = 0;
  bool manuallyOpenedIsland = false;
  DateTime? _lastOnboardTime;

  final Set<String> favouriteStationIds = {};

  Future<void> init() async {
    // Listen for service status changes (GPS on/off)
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.enabled) {
        _startTracking();
      } else {
        _handleGpsLost();
      }
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _handleGpsLost();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _startTracking();
  }

  void dispose() {
    _positionStream?.cancel();
    _positionStream = null;
    _serviceStatusStream?.cancel();
    _serviceStatusStream = null;
  }

  void _startTracking() {
    _positionStream?.cancel();
    final bool powerSaving = SettingsService().isPowerSavingMode;
    final LocationAccuracy accuracy =
        powerSaving ? LocationAccuracy.medium : LocationAccuracy.high;
    final Duration interval =
        powerSaving ? const Duration(seconds: 10) : const Duration(milliseconds: 500);
    final int distanceFilter = powerSaving ? 10 : 0;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        intervalDuration: interval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              "TaraTren is tracking your location for station announcements.",
          notificationTitle: "Active Tracking",
          enableWakeLock: true,
        ),
      ),
    ).listen((Position position) {
      _handleGpsRestored();
      processPosition(position);
    }, onError: (e) {
      debugPrint("GPS Status Alert: $e");
      _handleGpsLost();
    });
  }

  void refreshBatterySettings() => _startTracking();

  void _handleGpsLost() {
    if (!_gpsLost) {
      _gpsLost = true;
      NotificationService().showProximityNotification(
        id: 900,
        title: '📡 GPS Signal Lost',
        body:
            'Location tracking paused. Station notifications will resume when signal is restored.',
        summary: 'GPS Status',
      );
    }
  }

  void _handleGpsRestored() {
    if (_gpsLost) {
      _gpsLost = false;
      NotificationService().showProximityNotification(
        id: 901,
        title: '📡 GPS Signal Restored',
        body:
            'Location tracking is active again. Station alerts are back online.',
        summary: 'GPS Status',
      );
    }
  }

  void processPosition(Position position) {
    _updateFilteredPosition(position);
    final now = DateTime.now();
    _resetDailyFlagsIfNeeded(now);
    _checkScheduleNotifications(now);

    Map<String, dynamic>? closest;
    double minD = double.infinity;
    Map<String, dynamic>? secondClosest;
    double secondMinD = double.infinity;

    // We do a first pass to find the absolute closest station (any line) for "Entered" notifications
    for (var station in metroStations) {
      if (station['isExtension'] == true) continue;

      final double dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        station['lat'] as double,
        station['lng'] as double,
      );
      if (dist < minD) {
        secondMinD = minD;
        secondClosest = closest;
        minD = dist;
        closest = station;
      } else if (dist < secondMinD) {
        secondMinD = dist;
        secondClosest = station;
      }
    }

    final int speedKmH = (position.speed * 3.6).round().clamp(0, 100);
    
    // ── Onboard Detection & Transfer Logic ──────────────────
    final String? trackLine =
        _getLineByTrackProximity(position.latitude, position.longitude);
    final bool isNearTracks = trackLine != null;
    
    // Altitude check to avoid tracking buses/cars directly under the tracks
    bool validElevation = true;
    if (trackLine == 'LRT1' && position.altitude > 0 && position.altitude < 5.5) {
      validElevation = false;
    } else if (trackLine == 'LRT2' && position.altitude > 0 && position.altitude < 7.0) {
      // LRT-2 is significantly taller (12-16m tracks/platforms)
      // Any altitude below 7.0m is securely identified as Aurora Blvd / Marcos Hwy road traffic
      // (Underground Katipunan sections naturally lose GPS or drop below 0m MSL)
      validElevation = false;
    } else if (trackLine == 'MRT3') {
      // MRT-3 Rollercoaster Profile: Track elevation depends strictly on the current zone
      if (closest != null && closest['line'] == 'MRT3') {
        String sid = closest['id'];
        if (sid == 'mrt3-buendia' || sid == 'mrt3-ayala') {
          // Underground: Track is -10m. If altitude is 0 to 5.5m, they are on EDSA above it.
          if (position.altitude > 0 && position.altitude < 5.5) validElevation = false;
        } else if (sid == 'mrt3-north-ave' || sid == 'mrt3-quezon-ave' || sid == 'mrt3-kamuning' || sid == 'mrt3-magallanes') {
          // At-Grade: Track is 0m. EDSA traffic is also 0m.
          // By skipping the filter here, we appropriately allow tracking at 0m!
        } else {
          // Elevated: Ortigas, Guadalupe, Shaw, Boni, Taft, Santolan. Track is 7-12m.
          if (position.altitude > 0 && position.altitude < 5.5) validElevation = false;
        }
      }
    }

    final bool movingOnTrain = position.speed > 4.5 && isNearTracks && validElevation;

    bool transferring = false;
    if (_wasOnboard && !movingOnTrain && minD < 450) {
      transferring = true;
    }

    // Midway Stall Safety: stays onboard if near tracks but slow
    final bool midwayStall = _wasOnboard && isNearTracks && !movingOnTrain;

    // TRANSFER GRACE PERIOD (NEW):
    // Stay onboard if we were onboard recently (< 6 min) and are currently at a station area.
    // This allows walking between platforms without ending the trip.
    bool inGracePeriod = false;
    if (_wasOnboard && !movingOnTrain) {
      if (_lastOnboardTime != null && 
          DateTime.now().difference(_lastOnboardTime!).inMinutes < 6) {
        if (minD < 500) { // Still near a transit station
           inGracePeriod = true;
        }
      }
    }

    bool isWalkway = false;
    final snappedT = TrackData.snapToTransfer(position.latitude, position.longitude);
    if (snappedT != null && Geolocator.distanceBetween(position.latitude, position.longitude, snappedT.latitude, snappedT.longitude) <= 30.0) {
       isWalkway = true;
    }

    final bool onboard = movingOnTrain || transferring || midwayStall || inGracePeriod || isWalkway;
    final String? lineName = isWalkway ? 'Transfer' : (movingOnTrain ? trackLine : onboardLine.value);
    isTransferring.value = transferring || isWalkway;
    
    if (onboard) {
       _lastOnboardTime = DateTime.now();
       isOnboard.value = true;
       onboardLine.value = lineName;
    } else {
       isOnboard.value = false;
       onboardLine.value = null;
    }

    if (movingOnTrain && !_wasOnboard && lineName != null && closest != null) {
      NotificationService().showNotification(
        id: 777,
        title: '🚆 All Aboard: ${_lineFriendlyName(lineName)}',
        body: "We're now tracking your journey. Have a safe trip!",
      );
      _wasOnboard = true;

      // Start a new Trip Log session
      _tripStartStation = closest['name'];
      _tripLines.clear();
      _tripLines.add(lineName);
    } else if (onboard && lineName != null) {
      _tripLines.add(lineName);
      if (closest != null) _tripEndStation = closest['name'];
    } else if (!onboard && _wasOnboard) {
      _wasOnboard = false;
      _lastOnboardTime = null;
      _finalizeTripLog();

      // Show summary notification
      if (_tripEndStation != null) {
        final endSt = metroStations.firstWhere(
            (s) => s['name'] == _tripEndStation,
            orElse: () => <String, dynamic>{});
        final bool isTransfer = endSt['isTransfer'] == true;
        
        NotificationService().showProximityNotification(
          id: 888,
          title: isTransfer ? '🔄 Transfer Hub: $_tripEndStation' : '🏁 Journey Finished: $_tripEndStation',
          body: 'You have completed your trip. Trip details saved to Journal.',
          summary: 'Trip Finished',
        );
      }
    }

    // ── Station Proximity Loop (Next Stop, Approach, Entry, Exit) ──
    for (var station in metroStations) {
      if (station['isExtension'] == true) continue;

      final String sId = station['id'];
      final String sName = station['name'];
      final double dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        station['lat'] as double,
        station['lng'] as double,
      );
      final String sLine = station['line'] ?? '';
      final int notifId = sId.hashCode.abs() % 1000;
      final bool isClosest = closest?['id'] == sId;

      // Next Stop (While Onboard)
      // Use heading/bearing to ensure we only notify for stations in front of us
      final double bearing = _calculateBearing(
          position.latitude, position.longitude, station['lat'], station['lng']);
      double angleDiff = (position.heading - bearing).abs();
      if (angleDiff > 180) angleDiff = 360 - angleDiff;
      final bool isInFront = angleDiff < 85; // Train curves: 85 deg allowance

      final String? currentLine = lineName;
      final String nextStopKey = "next_$sId";
      final nowTime = DateTime.now();

      if (onboard &&
          currentLine != null &&
          sLine == currentLine &&
          dist < 700 &&
          dist > 250 &&
          isInFront &&
          !_nextStationNotified.contains(sId)) {
        
        // Cooldown check: 2 minutes for the same Next Stop alert
        final lastSent = _lastNotifiedTime[nextStopKey];
        if (lastSent == null || nowTime.difference(lastSent).inSeconds > 120) {
          _nextStationNotified.add(sId);
          _lastNotifiedTime[nextStopKey] = nowTime;

          final String stopsAway =
              _stopsAway(closest ?? station, station, currentLine);
          NotificationService().showJourneyNotification(
            id: notifId,
            title: '🚃 Next Stop: $sName',
            body: stopsAway,
            line: currentLine,
          );
          if (SettingsService().isVoiceEnabled) {
            VoiceService().announceNextStation(
              stationId: sId,
              stationName: sName,
              line: currentLine,
            );
          }
        }
      }

      // Approach (120m - Only if onboard, closest, and IN FRONT)
      final approachKey = "arrival_$sId";
      if (onboard &&
          dist < 120 &&
          isClosest &&
          isInFront &&
          !_notifiedStations.contains(sId)) {
        
        final lastSent = _lastNotifiedTime[approachKey];
        if (lastSent == null || nowTime.difference(lastSent).inSeconds > 120) {
          _notifiedStations.add(sId);
          _lastNotifiedTime[approachKey] = nowTime;

          // Arrival Alert: Only show system overlay if app is in background
          if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
            SystemOverlayService().show(
              nextStation: sName,
              line: sLine,
              speed: speedKmH,
              bodyText: 'Platform on the ${station['opensOnLeft'] == true ? 'Left' : 'Right'}.',
              isArrivalAlert: true,
            );
          }

          // DISABLED: Removing standard notification as requested by user
          /*
          NotificationService().showStationNotification(
            id: notifId,
            stationName: sName,
            line: sLine,
            body:
                'Platform on the ${station['opensOnLeft'] == true ? 'Left' : 'Right'}.',
            isApproach: true,
          );
          */
          if (SettingsService().isVoiceEnabled) {
            VoiceService().announceArrival(
              stationId: sId,
              stationName: sName,
              line: sLine,
              isTerminus: station['isTerminus'] == true,
              opensOnLeft: station['opensOnLeft'] == true,
              connections: List<String>.from(station['connections'] ?? []),
            );
          }
        }
      }

      // Entry (Rectangular Box Area - ~50m threshold)
      // A lat/lng delta of 0.00045 is approx 50m.
      final double latDiff =
          (position.latitude - (station['lat'] as double)).abs();
      final double lngDiff =
          (position.longitude - (station['lng'] as double)).abs();
      final bool insideBox = latDiff < 0.00045 && lngDiff < 0.00045;

      if (insideBox && isClosest && !_entryNotified.contains(sId)) {
        _entryNotified.add(sId);
        _activeStationId = sId;

        // Only show generic "Entered" notification if user is NOT currently riding a train.
        // Riders already get "Next Stop" and "Approach" alerts which are more relevant.
        if (!onboard) {
          NotificationService().showStationNotification(
            id: notifId,
            stationName: sName,
            line: sLine,
            body: 'You have entered the station area.',
            isApproach: false,
          );
        }

        // 🍒 EASTER EGG: Vito Cruz
        if (sId == 'lrt1-vito-cruz' && !_easterEggTriggered.contains(sId)) {
          _triggerVitoCruzEasterEgg();
          _easterEggTriggered.add(sId);
        }
      }

      // Exit (Larger buffers to prevent jitter reset: 500m/1200m)
      if (dist > 500) {
        if (_entryNotified.contains(sId)) {
          _entryNotified.remove(sId);
          if (_activeStationId == sId) _activeStationId = null;

          if (!onboard) {
            NotificationService().showStationNotification(
              id: notifId,
              stationName: sName,
              line: sLine,
              body: 'You have left the station area. Safe journey!',
              isApproach: false,
              isExit: true,
            );
          }
        }
        _notifiedStations.remove(sId);
        if (dist > 1200) {
          _nextStationNotified.remove(sId);
          _easterEggTriggered.remove(sId);
        }
      }

      // Near Favourite (500m)
      if (dist < 500 &&
          favouriteStationIds.contains(sId) &&
          !_nearFavouriteSent.contains(sId)) {
        _nearFavouriteSent.add(sId);
        NotificationService().showProximityNotification(
          id: 600 + sId.hashCode.abs() % 300,
          title: '⭐ Favourite Station Nearby',
          body: 'You\'re within 500m of $sName.',
        );
      }
      if (dist > 800) _nearFavouriteSent.remove(sId);
    }

    // ── Journey Info & Dynamic Island ────────────────────────
    if (onboard && lineName != null) {
      // Find the next station on the same line that is IN FRONT of us
      Map<String, dynamic>? nextStation;
      double minDInFront = double.infinity;

      for (var s in metroStations) {
        if (s['line'] != lineName || s['isExtension'] == true) continue;
        
        final double d = Geolocator.distanceBetween(
            position.latitude, position.longitude, s['lat'] as double, s['lng'] as double);
        final double b = _calculateBearing(
            position.latitude, position.longitude, s['lat'] as double, s['lng'] as double);
        
        double diff = (position.heading - b).abs();
        if (diff > 180) diff = 360 - diff;
        
        // Use a 90-degree cone for "in front" detection
        if (diff < 90) {
          // If we are VERY close to a station (e.g. stopped at it), 
          // we want the NEXT station in front, not the one we are currently at.
          if (d < 120) continue; 
          
          if (d < minDInFront) {
            minDInFront = d;
            nextStation = s;
          }
        }
      }

      // Fallback to second closest if no station found in front (e.g. heading jitter)
      nextStation ??= (secondClosest != null && secondClosest['line'] == lineName)
          ? secondClosest
          : null;

      // Show/Update System Overlay (Dynamic Island)
      bool isApproachingAny = false;
      String? approachStation;
      String? approachBody;

      if (closest != null) {
        final double distToClosest = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          closest['lat'] as double,
          closest['lng'] as double,
        );
        // Only trigger visual arrival alert if it's the station in front of us
        final double bToClosest = _calculateBearing(
            position.latitude, position.longitude, closest['lat'], closest['lng']);
        double diffToClosest = (position.heading - bToClosest).abs();
        if (diffToClosest > 180) diffToClosest = 360 - diffToClosest;

        if ((distToClosest < 120 && closest['line'] == lineName && diffToClosest < 90) || 
            (speedKmH < 5 && distToClosest < 120 && closest['line'] == lineName)) {
          isApproachingAny = true;
          approachStation = closest['name'];
          approachBody = 'Platform on the ${closest['opensOnLeft'] == true ? 'Left' : 'Right'}.';
        }
      }

      _offboardCount = 0;

      // Calculate Map Bar (Prev --- Center --- Future) and Status Label
      final lStations = metroStations.where((s) => s['line'] == lineName && s['isExtension'] != true).toList();
      lStations.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      
      bool isOnRight = _isNextOnRight(position.heading, lineName);
      String? nStat = nextStation?['name'];

      String? pStat;
      String? cStat; 
      String? nextS;
      String statusLabel = "Tracking...";

      bool isAtStation = speedKmH < 5 && closest != null && (minD < 120);

      final String dir = _getCardinalDirection(position.heading);
      currentDirection.value = dir;
      String? focusTarget;
      if (isAtStation) {
        statusLabel = closest['isTerminus'] == true ? "$dir • Terminus:" : "$dir • Stopped:";
        focusTarget = closest['name'];
        // Reset arrival alert if we've been stopped for a while at a terminus
        if (closest['isTerminus'] == true && speedKmH == 0) {
           isApproachingAny = false; 
        }
      } else if (isApproachingAny) {
        statusLabel = closest?['isTerminus'] == true ? "$dir • Arriving Terminus:" : "$dir • Arriving:";
        focusTarget = approachStation;
      } else {
        if (speedKmH < 5) {
           statusLabel = "$dir • Stopped:";
        } else {
           statusLabel = "$dir • Next:";
        }
        focusTarget = nStat; 
      }

      cStat = focusTarget;
      if (focusTarget != null) {
        int idx = lStations.indexWhere((s) => s['name'] == focusTarget);
        if (idx != -1) {
          if (isOnRight) {
            pStat = idx > 0 ? lStations[idx - 1]['name'] : null;
            nextS = idx < lStations.length - 1 ? lStations[idx + 1]['name'] : null;
          } else {
            pStat = idx < lStations.length - 1 ? lStations[idx + 1]['name'] : null;
            nextS = idx > 0 ? lStations[idx - 1]['name'] : null;
          }
        }
      }

      double? distVal;
      if (isApproachingAny && closest != null) {
        distVal = Geolocator.distanceBetween(position.latitude, position.longitude, closest['lat'], closest['lng']);
      } else if (nextStation != null) {
        distVal = Geolocator.distanceBetween(position.latitude, position.longitude, nextStation['lat'], nextStation['lng']);
      }

      String? paceVal;
      if (position.speed > 1.0) {
        double pMinKm = (1000 / position.speed) / 60;
        paceVal = "${pMinKm.toStringAsFixed(1)} min/km";
      } else {
        paceVal = isAtStation ? "Stopped" : "Idle";
      }

      _offboardCount = 0;

      // System Island: Always show/update to act as the universal Dynamic Island.
      SystemOverlayService().show(
        nextStation: nextS ?? '--',
        line: lineName,
        speed: speedKmH,
        isArrivalAlert: isApproachingAny,
        bodyText: isApproachingAny ? approachBody : null,
        prevStation: pStat ?? '--',
        currentStation: cStat ?? '--',
        statusLabel: statusLabel,
        distance: distVal,
          pace: paceVal,
          isSouthbound: isOnRight,
        );
    } else if (!onboard) {
      _offboardCount++;
      if (_offboardCount > 8) {
        if (!manuallyOpenedIsland) {
          SystemOverlayService().hide();
        } else {
          SystemOverlayService().show(
            nextStation: 'Search...',
            line: 'LRT1',
            speed: 0,
            isArrivalAlert: false,
            bodyText: null,
            prevStation: '--',
            currentStation: 'Awaiting Signal',
            statusLabel: 'STANDBY',
            distance: 0.0,
            pace: 'Scan',
            isSouthbound: true,
          );
        }
        nextStationName.value = null;
        prevStationName.value = null;
        currentStationOnboard.value = null;
        distanceToNext.value = null;
        currentSpeed.value = 0;
      }
    }

    // Update public notifiers for UI (Dynamic Island In-App)
    if (onboard) {
      manuallyOpenedIsland = false; // Reset lock once they board naturally
      final lStations = metroStations.where((s) => s['line'] == lineName && s['isExtension'] != true).toList();
      lStations.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

      bool isAtStation = speedKmH < 5 && closest != null && (minD < 120);
      bool isOnRight = _isNextOnRight(position.heading, lineName ?? '');

      // Check approach again for in-app consistency
      bool isAppr = false;
      String? aStat;
      String? aBody;
      if (closest != null) {
        final double distToC = Geolocator.distanceBetween(
          position.latitude, position.longitude,
          closest['lat'] as double, closest['lng'] as double,
        );
        final double bToC = _calculateBearing(position.latitude, position.longitude, closest['lat'], closest['lng']);
        double diffToC = (position.heading - bToC).abs();
        if (diffToC > 180) diffToC = 360 - diffToC;
        if (distToC < 120 && closest['line'] == lineName && diffToC < 90) {
          isAppr = true;
          aStat = closest['name'];
          aBody = 'Platform on the ${closest['opensOnLeft'] == true ? 'Left' : 'Right'}.';
        }
      }
      // Identify Focus Station for UI
      String? focusStation;
      String? bestNextName;
      if (!isAtStation && !isAppr) {
        Map<String, dynamic>? nextGoal;
        double minDN = double.infinity;
        for (var s in metroStations) {
          if (s['line'] == lineName && s['isExtension'] != true) {
            final double d = Geolocator.distanceBetween(position.latitude, position.longitude, s['lat'] as double, s['lng'] as double);
            final double b = _calculateBearing(position.latitude, position.longitude, s['lat'] as double, s['lng'] as double);
            double df = (position.heading - b).abs();
            if (df > 180) df = 360 - df;
            if (df < 90 && d > 120 && d < minDN) {
              minDN = d;
              nextGoal = s;
            }
          }
        }
        bestNextName = nextGoal?['name'];
      }

      if (isAtStation) {
        islandStatusLabel.value = "Currently station:";
        focusStation = closest['name'];
      } else if (isAppr) {
        islandStatusLabel.value = "Arriving (${aBody?.split('.').first ?? ''}):";
        focusStation = aStat;
      } else {
        islandStatusLabel.value = "Next Station:";
        focusStation = bestNextName;
      }

      currentStationOnboard.value = focusStation;
      int idx = lStations.indexWhere((s) => s['name'] == focusStation);
      if (idx != -1) {
        if (isOnRight) {
          prevStationName.value = idx > 0 ? lStations[idx - 1]['name'] : null;
          nextStationName.value = idx < lStations.length - 1 ? lStations[idx + 1]['name'] : null;
        } else {
          prevStationName.value = idx < lStations.length - 1 ? lStations[idx + 1]['name'] : null;
          nextStationName.value = idx > 0 ? lStations[idx - 1]['name'] : null;
        }
      }

      currentSpeed.value = (position.speed * 3.6).round().clamp(0, 100);
      
      final Map<String, dynamic>? nextTracked = nextStationName.value != null 
          ? lStations.firstWhere((s) => s['name'] == nextStationName.value, orElse: () => <String, dynamic>{}) 
          : null;

      if (nextTracked != null && nextTracked.isNotEmpty) {
        distanceToNext.value = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          nextTracked['lat'] as double,
          nextTracked['lng'] as double,
        );
      } else {
        distanceToNext.value = null;
      }
    }

    isOnboard.value = onboard;
    onboardLine.value = lineName;

    if (onboard &&
        lineName != null &&
        !SettingsService().isOfflineMode &&
        now.difference(_lastReportTime).inSeconds > 15) {
      _lastReportTime = now;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        LiveTrainService().reportLocation(
            "T-$lineName-${user.uid.substring(0, 5)}",
            lineName,
            ll.LatLng(currentPosition.value!.latitude, currentPosition.value!.longitude),
            user.uid,
            direction: _getCardinalDirection(position.heading),
            heading: position.heading);
      }
    }
  }

  void _checkScheduleNotifications(DateTime now) {
    if (now.weekday <= DateTime.friday &&
        now.hour == 7 &&
        now.minute == 0 &&
        !_peakHourSentMorning) {
      _peakHourSentMorning = true;
      NotificationService().showScheduleNotification(
          id: 800,
          title: '🕖 Morning Rush Hour',
          body: 'Heavy crowd expected.');
    }
    if (now.weekday <= DateTime.friday &&
        now.hour == 17 &&
        now.minute == 0 &&
        !_peakHourSentEvening) {
      _peakHourSentEvening = true;
      NotificationService().showScheduleNotification(
          id: 801,
          title: '🕔 Evening Rush Hour',
          body: 'Heavy crowd expected.');
    }
    if (now.hour == 21 && now.minute == 0 && !_lastTrainSent) {
      _lastTrainSent = true;
      NotificationService().showScheduleNotification(
          id: 802,
          title: '🌙 Last Train Soon',
          body: 'Trains stop after 10 PM.');
    }
  }

  void _triggerVitoCruzEasterEgg() async {
    final List<String> messages = [
      "Wait...",
      "There are places that quietly hold memories.",
      "Even if the reason they mattered is no longer there.",
      "Still... thank you.",
      "I miss you 🍒 - Francis"
    ];

    for (int i = 0; i < messages.length; i++) {
      await Future.delayed(Duration(seconds: i == 0 ? 3 : 5));
      NotificationService().showProximityNotification(
        id: 1111 + i,
        title: "Vito Cruz",
        body: messages[i],
        summary: "Memories",
      );
    }
  }

  void _resetDailyFlagsIfNeeded(DateTime now) {
    if (now.day != _scheduleResetDate.day) {
      _peakHourSentMorning = false;
      _peakHourSentEvening = false;
      _lastTrainSent = false;
      _scheduleResetDate = now;
    }
  }

  String _lineFriendlyName(String line) {
    switch (line.toUpperCase()) {
      case 'LRT1':
        return 'LRT-1 (Green Line)';
      case 'LRT2':
        return 'LRT-2 (Purple Line)';
      case 'MRT3':
        return 'MRT-3 (Yellow Line)';
      default:
        return line;
    }
  }

  String _stopsAway(
      Map<String, dynamic> from, Map<String, dynamic> to, String line) {
    final int diff =
        ((to['order'] as int? ?? 0) - (from['order'] as int? ?? 0)).abs();
    return diff <= 1
        ? 'Next station on ${_lineFriendlyName(line)}.'
        : '$diff stops away on ${_lineFriendlyName(line)}.';
  }

  void _finalizeTripLog() async {
    if (_tripStartStation != null &&
        _tripEndStation != null &&
        _tripStartStation != _tripEndStation &&
        _tripLines.isNotEmpty) {
      try {
        final startSt =
            metroStations.firstWhere((s) => s['name'] == _tripStartStation);
        final endSt =
            metroStations.firstWhere((s) => s['name'] == _tripEndStation);

        final station1 = Station.fromMap(startSt);
        final station2 = Station.fromMap(endSt);

        final userType = SettingsService().userType;
        final fareResult = FareService().getFareResult(station1, station2, userType: userType);
        
        double fare = 0.0;
        if (userType == 'beep') {
          fare = fareResult['sv']?.toDouble() ?? 0.0;
        } else {
          // Senior citizen, Student, or Normal Single Journey
          fare = fareResult['sj']?.toDouble() ?? 0.0;
        }

        final String combinedLines = _tripLines.take(3).join(" • ");
        final String typeSuffix = userType == 'beep' ? " [Beep]" : 
                                  userType == 'senior' ? " [Senior 50%]" : 
                                  userType == 'student' ? " [Student 50%]" : "";

        await TripLogService().logTrip(
          from: _tripStartStation!,
          to: _tripEndStation!,
          line: "$combinedLines$typeSuffix",
          fare: fare,
        );
      } catch (e) {
        debugPrint("Error logging trip: $e");
      }
    }

    // Reset session
    _tripStartStation = null;
    _tripEndStation = null;
    _tripLines.clear();
  }

  void _updateFilteredPosition(Position newPos) {
    Position processedPos = newPos;

    String? currentLine = onboardLine.value;
    if (currentLine != null) {
      // PREVENT SNAPPING IF ON WALKWAY
      final snappedTransfer = TrackData.snapToTransfer(newPos.latitude, newPos.longitude);
      bool isOnWalkway = false;
      if (snappedTransfer != null) {
        if (Geolocator.distanceBetween(newPos.latitude, newPos.longitude, snappedTransfer.latitude, snappedTransfer.longitude) <= 30.0) {
          isOnWalkway = true;
        }
      }

      if (!isOnWalkway) {
        final snapped = TrackData.snapToTrack(newPos.latitude, newPos.longitude, currentLine);
        if (snapped != null) {
          processedPos = Position(
            latitude: snapped.latitude,
            longitude: snapped.longitude,
            timestamp: newPos.timestamp,
            accuracy: newPos.accuracy,
            altitude: newPos.altitude,
            heading: newPos.heading,
            speed: newPos.speed,
            speedAccuracy: newPos.speedAccuracy,
            altitudeAccuracy: newPos.altitudeAccuracy,
            headingAccuracy: newPos.headingAccuracy,
          );
        }
      }
    }

    if (_lastPosition == null) {
      _lastPosition = processedPos;
    } else {
      const double alpha = 0.85;
      _lastPosition = Position(
        latitude:
            (processedPos.latitude * alpha) + (_lastPosition!.latitude * (1 - alpha)),
        longitude: (processedPos.longitude * alpha) +
            (_lastPosition!.longitude * (1 - alpha)),
        timestamp: processedPos.timestamp,
        accuracy: processedPos.accuracy,
        altitude: processedPos.altitude,
        heading: processedPos.heading,
        speed: processedPos.speed,
        speedAccuracy: processedPos.speedAccuracy,
        altitudeAccuracy: processedPos.altitudeAccuracy,
        headingAccuracy: processedPos.headingAccuracy,
      );
    }
    currentPosition.value = _lastPosition;
  }

  String? _getLineByTrackProximity(double lat, double lng) {
    // Check walkways first
    final snappedTransfer = TrackData.snapToTransfer(lat, lng);
    if (snappedTransfer != null) {
      if (Geolocator.distanceBetween(lat, lng, snappedTransfer.latitude, snappedTransfer.longitude) <= 30.0) {
        return 'Transfer';
      }
    }

    final allTracks = ['LRT1', 'LRT2', 'MRT3'];
    // Hysteresis: Maintain track lock up to 150m if we were already onboard
    // Otherwise strictly require < 50m to start tracking
    double threshold = _wasOnboard ? 150.0 : 50.0;
    
    for (var line in allTracks) {
      final snapped = TrackData.snapToTrack(lat, lng, line);
      if (snapped != null) {
        double d = Geolocator.distanceBetween(lat, lng, snapped.latitude, snapped.longitude);
        if (d <= threshold) return line;
      }
    }
    return null;
  }

  String _getCardinalDirection(double heading) {
    if (heading < 0 || heading == 0.0) return "Orienting";
    if (heading >= 315 || heading < 45) return "Northbound";
    if (heading >= 45 && heading < 135) return "Eastbound";
    if (heading >= 135 && heading < 225) return "Southbound";
    if (heading >= 225 && heading < 315) return "Westbound";
    return "Orienting";
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    double lat1Rad = lat1 * pi / 180;
    double lon1Rad = lon1 * pi / 180;
    double lat2Rad = lat2 * pi / 180;
    double lon2Rad = lon2 * pi / 180;

    double dLon = lon2Rad - lon1Rad;

    double y = sin(dLon) * cos(lat2Rad);
    double x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
    double bearing = atan2(y, x) * 180 / pi;

    return (bearing + 360) % 360;
  }

  bool _isNextOnRight(double heading, String line) {
    if (line == 'LRT2') {
      // For the East-West line, the user prefers the destination on the right 
      // for both Eastbound and Westbound.
      return true;
    }
    // For North-South lines (LRT1, MRT3), flip to the left only for Northbound.
    bool isSouth = heading > 90 && heading < 270;
    return isSouth;
  }

}
