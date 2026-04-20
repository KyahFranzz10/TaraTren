import 'package:flutter/material.dart';
import 'route_planner_service.dart';

class NavigationController {
  static final NavigationController _instance = NavigationController._internal();
  factory NavigationController() => _instance;
  NavigationController._internal();

  final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);
  final ValueNotifier<Map<String, dynamic>?> focusedStation = ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<PlannedRoute?> activeRoute = ValueNotifier<PlannedRoute?>(null);

  void setTab(int index) {
    selectedIndex.value = index;
  }

  void focusStationOnMap(Map<String, dynamic> station) {
    focusedStation.value = station;
    setTab(1); // 1 is the Map tab
  }

  void startNavigation(PlannedRoute route) {
    activeRoute.value = route;
    setTab(1); // 1 is the Map tab
  }
}
