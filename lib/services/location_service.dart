import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  double? _lastHeading;
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
  // Per-leg tracking: each contiguous segment on ONE line is a separate leg.
  // When the user transfers, the completed leg is saved to the journal first,
  // then a fresh leg starts when they board the next line.
  String? _tripStartStation;   // Board station of the CURRENT leg
  String? _tripEndStation;     // Most-recently-seen station on the CURRENT leg
  String? _legLine;            // Line code for the CURRENT leg
  final Set<String> _tripLines = {}; // All lines used across the whole journey

  DateTime _lastReportTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _wasOnboard = false;
  bool _gpsLost = false;

  bool _peakHourSentMorning = false;
  bool _peakHourSentEvening = false;
  bool _lastTrainSent = false;
  DateTime _scheduleResetDate = DateTime(0);
  int _offboardCount = 0;
  String? _lastEnteredStationName; // Boarding/Alighting station by geofence
  final ValueNotifier<bool> manuallyOpenedIsland = ValueNotifier<bool>(false);
  DateTime? _lastOnboardTime;

  // ── False-Positive Guard (road vehicles under elevated tracks) ──────────────
  // Counts consecutive GPS ticks that satisfy ALL train-motion criteria.
  // We only declare "onboard" once this reaches _kOnboardThreshold.
  // A jeepney stopping at a traffic light resets it to 0 immediately.
  int _onboardConfidence = 0;
  static const int _kOnboardThreshold = 10; // ~5 seconds at 500 ms ticks

  // LAYER 5: Geographic road exclusion zones.
  // These bounding boxes cover road corridors that run directly below or
  // alongside LRT-1's southern elevated structure. A new boarding session
  // will never START inside these boxes. An existing confirmed session
  // (already onboard) can pass through them without interruption.
  //
  // Format: [minLat, minLng, maxLat, maxLng]
  static const List<List<double>> _kRoadExclusionZones = [
    // (1) Dr. Santos Avenue (LRT-1 Extension Area)
    [14.4790, 120.9820, 14.4950, 121.0050],
    // (2) CAVITEX / Coastal Road (Ninoy Aquino to MIA Road stretch)
    [14.4700, 120.9880, 14.5100, 121.0050],
    // (3) Roxas Boulevard (NAIA Road to Baclaran / Aseana)
    [14.5100, 120.9900, 14.5420, 121.0010],
    // (4) Taft Avenue (Manila Hubs: UN Ave to Pedro Gil to Vito Cruz)
    [14.5550, 120.9800, 14.5850, 120.9980],
    // (5) EDSA - North (North Ave to Kamuning)
    [14.6200, 121.0280, 14.6580, 121.0450],
    // (6) EDSA - South (Magallanes to Taft Ave Interchange)
    [14.5350, 121.0000, 14.5480, 121.0250],
    // (7) Rizal Avenue (LRT-1 North: Carriedo to Monumento stretch)
    [14.5980, 120.9750, 14.6550, 120.9880],
  ];

  final Set<String> favouriteStationIds = {};

  static const Map<String, double> _avgSegmentTimes = {
    "Vito Cruz-Gil Puyat": 90,
    "Gil Puyat-Libertad": 85,
    "Libertad-EDSA": 105,
    "EDSA-Baclaran": 110,
    "Quirino-Vito Cruz": 70,
    "Pedro Gil-Quirino": 65,
    "UN Avenue-Pedro Gil": 60,
    "Central Terminal-UN Avenue": 95,
  };

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
      processPosition(position); // fire-and-forget async
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

  Future<void> processPosition(Position position) async {
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
    
    // LAYER 1 — Altitude filter (accuracy-gated)
    //
    // ⚠️  GPS altitude on Android has ±10–20 m vertical error in dense urban
    //     canyons (multipath reflections off buildings). Applying a hard altitude
    //     block when the sensor itself is unreliable causes random false-negatives
    //     (legitimate train rides silently dropped).
    //
    // FIX: Only engage the filter when Android reports a reliable vertical
    //      accuracy (altitudeAccuracy < 15 m). If the chip can't vouch for its
    //      own reading we trust the other 5 layers to do the work.
    //
    // MRT-3 station classification (verified against Wikipedia / DOTC data):
    //   • Underground  : Ayala, Buendia               (track ≈ −10 m MSL)
    //   • At-grade     : North Ave, Quezon Ave,
    //                    Kamuning, Magallanes          (track ≈ 0 m MSL)
    //   • Elevated     : all other stations            (track ≈ 7–12 m MSL)
    bool validElevation = true;
    // altitudeAccuracy == 0 means "not reported"; treat as unreliable.
    final bool altitudeReliable =
        position.altitudeAccuracy > 0 && position.altitudeAccuracy < 15.0;

    if (altitudeReliable && position.altitude > 0) {
      if (trackLine == 'LRT1' && position.altitude < 5.5) {
        // LRT-1 elevated sections: track ≈ 8–12 m. Below 5.5 m = road level.
        validElevation = false;
      } else if (trackLine == 'LRT2' && position.altitude < 7.0) {
        // LRT-2 is taller (12–16 m platforms). Below 7.0 m = Aurora Blvd / Marcos Hwy.
        // Underground Katipunan section: GPS loses lock naturally — no filter needed.
        validElevation = false;
      } else if (trackLine == 'MRT3') {
        if (closest != null && closest['line'] == 'MRT3') {
          final String sid = closest['id'];
          if (sid == 'mrt3-buendia' || sid == 'mrt3-ayala') {
            // ↓ UNDERGROUND stations. Track is ~−10 m MSL.
            // A reading at 0–5.5 m means the user is on the EDSA road ABOVE the tunnel.
            if (position.altitude < 5.5) validElevation = false;
          } else if (sid == 'mrt3-north-ave' ||
              sid == 'mrt3-quezon-ave' ||
              sid == 'mrt3-kamuning' ||
              sid == 'mrt3-magallanes') {
            // ↓ AT-GRADE stations. Track and road are both ~0 m — altitude cannot
            //   distinguish them, so skip the filter and let Layers 2–6 decide.
          } else {
            // ↓ ELEVATED stations (all others). Track ≈ 7–12 m.
            // Below 5.5 m = road-level EDSA vehicle.
            if (position.altitude < 5.5) validElevation = false;
          }
        }
      }
    }

    // LAYER 2 — Speed threshold (raised from 4.5 → 7.0 m/s, ~25 km/h)
    // Metro Manila jeepneys/buses under elevated tracks rarely sustain 25 km/h
    // due to traffic signals and congestion. Trains always cruise above it.
    // Note: _wasOnboard keeps a slightly lower bar (4.5) for midway-stall safety.
    final bool rawSpeedOk = position.speed > 7.0;

    // LAYER 3 — Track heading alignment
    // A road vehicle following an overpass road will deviate from the track bearing.
    // We compute the bearing of the nearest track segment and reject motion that
    // differs by more than 50 degrees. Skip check if speed is too low (heading noise).
    bool trackAligned = true;
    if (isNearTracks && trackLine != 'Transfer' && position.speed > 3.0) {
      final double? segBearing =
          _getTrackBearing(position.latitude, position.longitude, trackLine);
      if (segBearing != null) {
        double diff = (position.heading - segBearing).abs();
        if (diff > 180) diff = 360 - diff;
        // Allow the reverse direction too (train going the other way = 180° off)
        if (diff > 50 && diff < 130) trackAligned = false;
      }
    }

    // A reading is "train-like" only when ALL three layers agree.
    final bool looksTrain = rawSpeedOk && isNearTracks && validElevation && trackAligned;

    // LAYER 6 — Track Deviation Score
    // Measures how tightly the raw GPS fix hugs the rail polyline.
    // A real train sits within 8–15 m of the centreline at all times.
    // Cars on parallel roads (EDSA, Taft, Aurora Blvd) drift 20–60 m sideways.
    //
    //  deviation < 15 m  → score 2  (very tight — almost certainly on the rail)
    //  deviation < 40 m  → score 1  (plausible — could still be a road vehicle)
    //  deviation ≥ 40 m  → score 0  (too far — road car / GPS multipath)
    //
    // The score is added to the confidence increment below so that a genuine
    // train reaches _kOnboardThreshold in 1–2 ticks instead of 4, while a car
    // that passes all boolean layers still has to accumulate slowly.
    int _trackDeviationScore = 0;
    if (looksTrain && trackLine != 'Transfer') {
      final snappedPt =
          TrackData.snapToTrack(position.latitude, position.longitude, trackLine);
      if (snappedPt != null) {
        final double deviation = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          snappedPt.latitude,
          snappedPt.longitude,
        );
        if (deviation < 15) {
          _trackDeviationScore = 2; // ← tight rail hug → fast lock
        } else if (deviation < 40) {
          _trackDeviationScore = 1; // ← plausible alignment → normal lock
        }
        // deviation ≥ 40 → score 0 → no bonus; confidence builds slowly
      }
    }

    // LAYER 4 — Confidence counter (most important for eliminating glitches)
    // Gate: require _kOnboardThreshold consecutive "looks like a train" readings
    // before flipping isOnboard. One traffic-light stop resets it to zero.
    //
    // LAYER 5 — Geographic road exclusion zones
    // Prevent a brand-new session from starting inside known road corridors
    // that run parallel to the LRT-1 southern structure.
    // Already-confirmed trips (e.g. boarding at Baclaran) pass through freely.
    final bool inExclusionZone =
        !_wasOnboard && _isInRoadExclusionZone(position.latitude, position.longitude);

    // LAYER 7 — Stop-Pattern Analysis
    // Trains only stop at stations. A ground vehicle (jeepney) stopping at a
    // traffic light or loading zone between stations is a definitive "Not a Train".
    // 150m buffer covers most platforms.
    final bool stoppedBetweenStations = position.speed < 1.0 && minD > 150;

    if (looksTrain && !inExclusionZone) {
      // Weight the increment: +1 base + deviation bonus (max 1 instead of 2 for safety).
      // Throttled if speed is < 10 m/s (approx 36 km/h) to demand sustained high speed.
      int increment = (position.speed > 10.0) ? 2 : 1;
      if (_trackDeviationScore > 0) increment += 1;
      
      _onboardConfidence =
          (_onboardConfidence + increment).clamp(0, _kOnboardThreshold);
    } else if (stoppedBetweenStations || !looksTrain) {
      // Hard reset confidence if we stop randomly or violate basic train physics
      // Only if not already locked onboard.
      if (!_wasOnboard) {
        _onboardConfidence = 0;
      } else if (stoppedBetweenStations && _onboardConfidence >= _kOnboardThreshold) {
        // If we WERE onboard but stopped mid-track for > 15 seconds, likely offboarded
        // or the "onboard" was a false positive that finally stopped.
        _onboardConfidence -= 2; // Decay slowly rather than instant drop to avoid jitter
        if (_onboardConfidence < 5) _onboardConfidence = 0;
      }
    }
    final bool movingOnTrain = _onboardConfidence >= _kOnboardThreshold;

    bool transferring = false;
    if (_wasOnboard && !movingOnTrain && minD < 450) {
      transferring = true;
    }

    // Midway Stall Safety: stays onboard if near tracks but slow
    final bool midwayStall = _wasOnboard && isNearTracks && !movingOnTrain;
    // Detect walkway FIRST — grace period variables depend on the matched route.
    bool isWalkway = false;
    TransferRoute? activeTransferRoute;
    final transferMatch = TrackData.snapToTransferRoute(position.latitude, position.longitude);
    if (transferMatch != null) {
      isWalkway = true;
      activeTransferRoute = transferMatch.route;
    }

    // Grace period variables (route-aware). Declared before the check block below.
    final int gracePeriodMinutes = activeTransferRoute != null
        ? activeTransferRoute.estimatedMinutes + 7   // buffer on top of walking estimate
        : 12;                                         // default for non-walkway gaps
    final double gracePeriodRadius = activeTransferRoute != null
        ? activeTransferRoute.distanceMeters * 2.0   // wide net for long mall walk
        : 600.0;

    // TRANSFER GRACE PERIOD:
    // Stay onboard if we were onboard recently and near a transit station.
    // Duration and radius are scaled to the active walkway (Cubao = 22 min, 1400 m).
    bool inGracePeriod = false;
    if (_wasOnboard && !movingOnTrain) {
      if (_lastOnboardTime != null &&
          DateTime.now().difference(_lastOnboardTime!).inMinutes < gracePeriodMinutes) {
        if (minD < gracePeriodRadius) {
          inGracePeriod = true;
        }
      }
    }

    final String? prevLine = onboardLine.value;
    final bool onboard = movingOnTrain || transferring || midwayStall || inGracePeriod || isWalkway;
    final String? lineName = isWalkway ? 'Transfer' : (movingOnTrain ? trackLine : onboardLine.value);
    isTransferring.value = transferring || isWalkway;
    
    // ── Checkpoint Leg (Transfer Detection) ──
    if (onboard && _wasOnboard && prevLine != null && prevLine != 'Transfer' && lineName == 'Transfer') {
      _finalizeTripLog();
    }

    if (onboard) {
       _lastOnboardTime = DateTime.now();
       isOnboard.value = true;
       onboardLine.value = lineName;
    } else {
       isOnboard.value = false;
       onboardLine.value = null;
    }

    // ── Per-leg journal tracking ───────────────────────────────────────
    // Each contiguous segment on a SINGLE line = one leg. When the user
    // transfers (line changes) or the journey ends, the leg is saved immediately.

    if (movingOnTrain && lineName != null && lineName != 'Transfer') {
      if (!_wasOnboard) {
        // Brand-new journey: open a fresh leg.
        // Priority: Last station we were physically inside (geofenced)
        // Fallback: Current closest station
        _tripStartStation = _lastEnteredStationName ?? closest?['name'];
        _tripEndStation   = _tripStartStation;
        _legLine          = lineName;
        _tripLines.clear();
        _tripLines.add(lineName);
        _wasOnboard = true;

        NotificationService().showNotification(
          id: 777,
          title: '🚆 All Aboard: ${_lineFriendlyName(lineName)}',
          body: "We're boarding at $_tripStartStation. Have a safe trip!",
        );
      } else if (_legLine != null && _legLine != lineName) {
        // Line has changed (e.g. from Transfer → new train line).
        // Save the completed leg, then start a fresh one.
        await _saveLeg();
        
        // Use the geofence station we just entered as the start of the new leg
        _tripStartStation = _lastEnteredStationName ?? closest?['name'];
        _tripEndStation   = _tripStartStation;
        _legLine          = lineName;
        _tripLines.add(lineName);

        NotificationService().showNotification(
          id: 777,
          title: '🚇 Boarded: ${_lineFriendlyName(lineName)}',
          body: 'Continuing your journey at $_tripStartStation — welcome aboard!',
        );
      } else {
        // Same line, rolling forward: update exit station.
        _legLine = lineName;
        _tripLines.add(lineName);
        if (closest != null) _tripEndStation = closest['name'];
      }
    } else if (onboard) {
      // onboard but not necessarily moving (stalled at station or in grace period)
      // Update end station if we are definitively at a station on our line
      if (closest != null && lineName != null && lineName != 'Transfer' && 
          closest['line'] == lineName && minD < 150) {
        _tripEndStation = closest['name'];
      }
    } else if (!onboard && _wasOnboard) {
      // Journey ended: finalize the leg.
      // If we are currently at a station, make sure it's the end station.
      if (closest != null && minD < 300) {
        _tripEndStation = closest['name'];
      }
      
      _wasOnboard = false;
      _lastOnboardTime = null;
      await _saveLeg();

      if (_tripEndStation != null) {
        final endSt = metroStations.firstWhere(
            (s) => s['name'] == _tripEndStation,
            orElse: () => <String, dynamic>{});
        final bool isTransferHub = endSt['isTransfer'] == true;

        NotificationService().showProximityNotification(
          id: 888,
          title: isTransferHub
              ? '🔄 Transfer Hub: $_tripEndStation'
              : '🏁 Journey Finished: $_tripEndStation',
          body: 'Trip saved to Journal.',
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

          // Arrival Alert: Logic moved to universal Dynamic Island update at end of processPosition.
          // This prevents double-calling and ensures consistent state.

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
        _lastEnteredStationName = sName;


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
      // ── Show/Update System Overlay (Dynamic Island) ──
      bool isNowArrivingOnly = false;
      bool isApproachingAny = false;
      String? approachBody;

      if (closest != null) {
        final double distToClosest = Geolocator.distanceBetween(
          position.latitude, position.longitude, closest['lat'], closest['lng']);
        final double bToClosest = _calculateBearing(position.latitude, position.longitude, closest['lat'], closest['lng']);
        double diffToClosest = (position.heading - bToClosest).abs();
        if (diffToClosest > 180) diffToClosest = 360 - diffToClosest;

        if ((distToClosest < 150 && closest['line'] == lineName && diffToClosest < 90) || 
            (speedKmH < 5 && distToClosest < 150)) {
          isApproachingAny = true;
          approachBody = 'Platform on the ${closest['opensOnLeft'] == true ? 'Left' : 'Right'}.';
          if (distToClosest < 50) isNowArrivingOnly = true;
        }
      }

      // 1. Determine the 'Focal' station.
      Map<String, dynamic>? focalStation;
      bool isAtStation = (speedKmH < 8 && closest != null && minD < 300);
      
      if (isAtStation || isApproachingAny) {
        focalStation = closest;
      } else {
        double minDInFront = double.infinity;
        for (var s in metroStations) {
          if (s['line'] != lineName || s['isExtension'] == true) continue;
          final double d = Geolocator.distanceBetween(position.latitude, position.longitude, s['lat'], s['lng']);
          final double b = _calculateBearing(position.latitude, position.longitude, s['lat'], s['lng']);
          double diff = (position.heading - b).abs();
          if (diff > 180) diff = 360 - diff;
          if (diff < 90 && d < minDInFront) {
            minDInFront = d;
            focalStation = s;
          }
        }
        focalStation ??= closest;
      }

      _offboardCount = 0;
      final List<Map<String, dynamic>> lStations = metroStations
          .where((s) => s['line'] == lineName && s['isExtension'] != true)
          .map((s) => s as Map<String, dynamic>)
          .toList();
      lStations.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

      bool isOnRight = _isNextOnRight(_lastHeading ?? position.heading, lineName);
      String? focalName = focalStation?['name'];

      String? pStat;
      String? cStat; 
      String? nextS;
      String statusLabel = "Tracking...";

      final String dir = _getCardinalDirection(_lastHeading ?? position.heading, lineName);
      currentDirection.value = dir;
      String? focusTarget = focalName;

      if (isAtStation) {
        statusLabel = closest?['isTerminus'] == true ? "$dir • Terminus:" : "$dir • Stopped:";
      } else if (isNowArrivingOnly) {
        statusLabel = "$dir • NOW ARRIVING:";
      } else if (isApproachingAny) {
        statusLabel = closest?['isTerminus'] == true ? "$dir • Arriving Terminus:" : "$dir • Arriving:";
      } else {
        statusLabel = (speedKmH < 5) ? "$dir • Stopped:" : "$dir • Next:";
      }

      cStat = focusTarget;
      if (focusTarget != null) {
        int idx = lStations.indexWhere((s) => s['name'] == focusTarget);
        if (idx != -1) {
          // Identify the 'Mirror' perspective. 
          // Default: Match the side the doors open on at the focal station.
          bool opensOnLeft = focalStation?['opensOnLeft'] == true;
          
          // User Facing Perspective Mapping:
          // IF FACING LEFT DOOR: Prev --- Current --- Next
          // IF FACING RIGHT DOOR: Next --- Current --- Prev
          
          if (opensOnLeft) {
            // Door on Left Perspective (Standard Index Flow)
            if (isOnRight) { // Southbound
              pStat = idx > 0 ? lStations[idx - 1]['name'] : null;
              nextS = idx < lStations.length - 1 ? lStations[idx + 1]['name'] : null;
            } else { // Northbound
              pStat = idx < lStations.length - 1 ? lStations[idx + 1]['name'] : null;
              nextS = idx > 0 ? lStations[idx - 1]['name'] : null;
            }
          } else {
            // Door on Right Perspective (Flipped for Mirror Effect)
            if (isOnRight) { // Southbound: Next is Order + 1 (Right in index, but show on Left of UI)
              nextS = idx > 0 ? lStations[idx - 1]['name'] : null;
              pStat = idx < lStations.length - 1 ? lStations[idx + 1]['name'] : null;
            } else { // Northbound
              nextS = idx < lStations.length - 1 ? lStations[idx + 1]['name'] : null;
              pStat = idx > 0 ? lStations[idx - 1]['name'] : null;
            }
          }
        }
      }

      double? distVal;
      if (focalStation != null) {
        distVal = Geolocator.distanceBetween(position.latitude, position.longitude, focalStation['lat'], focalStation['lng']);
      }

      String? paceVal;
      if (speedKmH > 0 && distVal != null) {
        // live math: distance (m) / speed (m/s)
        double liveEtaSeconds = distVal / (position.speed > 1.0 ? position.speed : 1.0);
        
        // Hybrid System: Combine live ETA with historical average for this segment
        double? historicalAvg;
        if (pStat != null && focusTarget != null) {
           String segForward = "$pStat-$focusTarget";
           String segReverse = "$focusTarget-$pStat";
           historicalAvg = _avgSegmentTimes[segForward] ?? _avgSegmentTimes[segReverse];
        }
        
        double finalEtaSeconds = liveEtaSeconds;
        if (historicalAvg != null) {
           // Scale the historical average based on remaining distance (assuming ~800m avg distance)
           double historicalRemaining = historicalAvg * (distVal / 800.0).clamp(0.1, 1.0);
           finalEtaSeconds = (liveEtaSeconds + historicalRemaining) / 2;
        }

        if (finalEtaSeconds < 60) {
           paceVal = "< 1 min";
        } else {
           paceVal = "${(finalEtaSeconds / 60).toStringAsFixed(1)} min";
        }
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
          isNowArriving: isNowArrivingOnly,
        );
    } else if (isWalkway && activeTransferRoute != null) {
      // User is walking a transfer walkway — keep the overlay alive with
      // route-specific info so they know what to expect.
      _offboardCount = 0;
      final String acTag = activeTransferRoute.isAirConditioned ? '❄️ AC' : '🌡️ Not AC';
      SystemOverlayService().show(
        nextStation: activeTransferRoute.toStation,
        line: activeTransferRoute.toLine,
        speed: 0,
        isArrivalAlert: false,
        bodyText: '${activeTransferRoute.walkDescription}  $acTag',
        prevStation: activeTransferRoute.fromStation,
        currentStation: '${activeTransferRoute.label} Transfer',
        statusLabel: 'Walking • ${activeTransferRoute.estimatedMinutes} min walk',
        distance: activeTransferRoute.distanceMeters.toDouble(),
        pace: '~${activeTransferRoute.estimatedMinutes} min',
        isSouthbound: true,
      );
      islandStatusLabel.value = '${activeTransferRoute.label} Transfer';
      islandBodyText.value = activeTransferRoute.walkDescription;
    } else if (!onboard) {
      _offboardCount++;
      if (_offboardCount > 8) {
        if (!manuallyOpenedIsland.value) {
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
      manuallyOpenedIsland.value = false; // Reset lock once they board naturally
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
            if (df < 90 && d < minDN) {
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
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        LiveTrainService().reportLocation(
            "T-$lineName-${user.id.substring(0, 5)}",
            lineName,
            ll.LatLng(currentPosition.value!.latitude, currentPosition.value!.longitude),
            user.id,
            direction: _getCardinalDirection(position.heading, lineName),
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

  /// Saves the current in-progress leg (one line segment) to the journal,
  /// then resets only the leg fields so the next leg can start cleanly.
  /// Called when: (a) the user boards a different line after a transfer,
  /// or (b) the journey ends completely.
  Future<void> _saveLeg() async {
    final String? from = _tripStartStation;
    final String? to   = _tripEndStation;
    final String? line = _legLine;

    // Reset leg fields immediately (journey fields stay for next leg)
    _tripStartStation = null;
    _tripEndStation   = null;
    _legLine          = null;

    // Don't save trivial single-station or unknown legs
    if (from == null || to == null || line == null || from == to) return;
    if (line == 'Transfer') return;

    try {
      final startSt = metroStations.firstWhere(
          (s) => s['name'] == from,
          orElse: () => <String, dynamic>{});
      final endSt = metroStations.firstWhere(
          (s) => s['name'] == to,
          orElse: () => <String, dynamic>{});

      if (startSt.isEmpty || endSt.isEmpty) return;

      final station1 = Station.fromMap(startSt);
      final station2 = Station.fromMap(endSt);

      final userType = SettingsService().userType;
      final fareResult = FareService().getFareResult(station1, station2, userType: userType);

      double fare = 0.0;
      if (userType == 'beep') {
        fare = fareResult['sv']?.toDouble() ?? 0.0;
      } else {
        fare = fareResult['sj']?.toDouble() ?? 0.0;
      }

      final String typeSuffix = userType == 'beep'    ? ' [Beep]'      :
                                userType == 'senior'  ? ' [Senior 50%]' :
                                userType == 'student' ? ' [Student 50%]' : '';

      await TripLogService().logTrip(
        from: from,
        to:   to,
        line: '$line$typeSuffix',
        fare: fare,
      );

      debugPrint('Leg saved: $line  $from → $to  ₱$fare');
    } catch (e) {
      debugPrint('Error saving leg: $e');
    }
  }

  /// Legacy method — kept so any external callers still compile.
  /// Internally now just calls _saveLeg().
  void _finalizeTripLog() {
    _saveLeg(); // fire-and-forget
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

    // Heading Smoothing and Stabilization
    double rawHeading = processedPos.heading;
    double smoothedHeading = rawHeading;

    if (_lastPosition != null) {
      // If moving (> 5km/h), calculate heading from position delta (which is snapped to track)
      // This is much more stable than raw GPS heading for trains.
      if (processedPos.speed > 1.4) {
        double deltaHeading = _calculateBearing(
          _lastPosition!.latitude, _lastPosition!.longitude,
          processedPos.latitude, processedPos.longitude
        );
        
        if (_lastHeading == null) {
          smoothedHeading = deltaHeading;
        } else {
          // Angular interpolation
          double diff = (deltaHeading - _lastHeading!);
          if (diff > 180) diff -= 360;
          if (diff < -180) diff += 360;
          smoothedHeading = (_lastHeading! + diff * 0.4) % 360; // Smooth blending
          if (smoothedHeading < 0) smoothedHeading += 360;
        }
      } else {
        // If stopped or very slow, lock heading to last reliable direction 
        // to prevent the icon from spinning while at a station.
        smoothedHeading = _lastHeading ?? rawHeading;
      }
    }
    _lastHeading = smoothedHeading;

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
        heading: smoothedHeading,
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

  /// Returns the bearing (degrees) of the track segment nearest to [lat]/[lng]
  /// for [lineName]. Used by Layer 3 (heading alignment) to reject road vehicles.
  double? _getTrackBearing(double lat, double lng, String lineName) {
    List<dynamic>? trackPoints;
    if (lineName == 'LRT1') trackPoints = TrackData.lrt1Track;
    else if (lineName == 'LRT2') trackPoints = TrackData.lrt2Track;
    else if (lineName == 'MRT3') trackPoints = TrackData.mrt3Track;
    if (trackPoints == null || trackPoints.length < 2) return null;

    // Find the closest segment (pair of consecutive track points)
    int bestIdx = 0;
    double minD = double.infinity;
    for (int i = 0; i < trackPoints.length - 1; i++) {
      final mid_lat = (trackPoints[i].latitude + trackPoints[i + 1].latitude) / 2;
      final mid_lng = (trackPoints[i].longitude + trackPoints[i + 1].longitude) / 2;
      final d = Geolocator.distanceBetween(lat, lng, mid_lat, mid_lng);
      if (d < minD) { minD = d; bestIdx = i; }
    }

    // Bearing of that segment
    return _calculateBearing(
      trackPoints[bestIdx].latitude, trackPoints[bestIdx].longitude,
      trackPoints[bestIdx + 1].latitude, trackPoints[bestIdx + 1].longitude,
    );
  }

  /// Returns true if [lat]/[lng] falls inside one of the known road corridors
  /// that run alongside or below the LRT-1 southern elevated structure.
  /// Used by Layer 5 to prevent a *new* boarding session from starting there.
  bool _isInRoadExclusionZone(double lat, double lng) {
    for (final zone in _kRoadExclusionZones) {
      final double minLat = zone[0], minLng = zone[1];
      final double maxLat = zone[2], maxLng = zone[3];
      if (lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng) {
        return true;
      }
    }
    return false;
  }

  String _getCardinalDirection(double heading, String? line) {
    if (heading < 0 || heading == 0.0) return "Orienting";

    if (line == 'LRT2') {
      // East-West Line: Focus on East/West
      return (heading > 180 && heading < 360) ? "Westbound" : "Eastbound";
    } else {
      // North-South Lines (LRT1, MRT3): Focus on North/South
      return (heading > 90 && heading < 270) ? "Southbound" : "Northbound";
    }
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
      // East-West Line: Eastbound heading is approx 90°, Westbound approx 270°
      // If heading is East, next stations have higher orders (isOnRight = true)
      // If heading is West, next stations have lower orders (isOnRight = false)
      return heading > 45 && heading < 135;
    }
    // For North-South lines (LRT1, MRT3), flip to the left only for Northbound.
    bool isSouth = heading > 90 && heading < 270;
    return isSouth;
  }

}
