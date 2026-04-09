import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'settings_service.dart';
import '../data/metro_stations.dart';

class SystemOverlayService {
  static final SystemOverlayService _instance = SystemOverlayService._internal();
  factory SystemOverlayService() => _instance;
  SystemOverlayService._internal();

  bool _isActive = false;

  Future<void> show({
    required String nextStation,
    required String line,
    required int speed,
    String? bodyText,
    bool isArrivalAlert = false,
    String? prevStation,
    String? currentStation,
    String? statusLabel,
    double? distance,
    String? pace,
    bool isSouthbound = true,
  }) async {
    if (!SettingsService().isSystemIslandEnabled) {
      await hide();
      return;
    }

    // Strict filter: Only operational lines (LRT-1, LRT-2, MRT-3)
    final String lineCode = line.toUpperCase().replaceAll('-', '').replaceAll(' ', '');
    final operationalLines = ['LRT1', 'LRT2', 'MRT3'];
    if (!operationalLines.contains(lineCode)) {
      await hide();
      return;
    }

    // Strict filter: Do not detect or show tracking for expansion stations not yet open
    final bool isNextExt = metroStations.any((s) => s['name'] == nextStation && s['isExtension'] == true);
    final bool isCurrentExt = currentStation != null && metroStations.any((s) => s['name'] == currentStation && s['isExtension'] == true);
    final bool isPrevExt = prevStation != null && metroStations.any((s) => s['name'] == prevStation && s['isExtension'] == true);

    if (isNextExt || isCurrentExt || isPrevExt) {
      await hide();
      return;
    }
    if (!await FlutterOverlayWindow.isPermissionGranted()) return;

    if (!_isActive) {
      try {
        await FlutterOverlayWindow.showOverlay(
          height: 400, // Increased from 350 to ensure no overflow even with tall content
          width: WindowSize.matchParent,
          alignment: OverlayAlignment.topCenter,
          enableDrag: true,
          overlayTitle: "TaraTren Live",
          overlayContent: "Tracking journey...",
          flag: OverlayFlag.defaultFlag,
        );
        _isActive = true;
      } catch (e) {
        debugPrint("Overlay show error: $e");
      }
    }

    // Share data to the overlay entry point
    await FlutterOverlayWindow.shareData({
      'nextStation': nextStation,
      'line': line,
      'speed': speed,
      'bodyText': bodyText,
      'isArrivalAlert': isArrivalAlert,
      'prevStation': prevStation,
      'currentStation': currentStation,
      'statusLabel': statusLabel,
      'distance': distance,
      'pace': pace,
      'isSouthbound': isSouthbound,
    });
  }

  Future<void> hide() async {
    if (_isActive) {
      await FlutterOverlayWindow.closeOverlay();
      _isActive = false;
    }
  }

  Future<void> requestPermission() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
  }
}
