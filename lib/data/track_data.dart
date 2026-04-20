import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/station.dart';

class TrackData {
  static LatLng? snapToTrack(double lat, double lng, String lineName) {
    List<LatLng>? track;
    if (lineName == 'LRT1') track = lrt1Track;
    else if (lineName == 'LRT2') track = lrt2Track;
    else if (lineName == 'MRT3') track = mrt3Track;
    if (track == null || track.isEmpty) return null;

    LatLng? bestSnap;
    double minSqD = double.infinity;
    final double latToMeters = 111139.0;
    final double lngToMeters = 111320.0 * 0.968;
    double pX = lng * lngToMeters;
    double pY = lat * latToMeters;

    for (int i = 0; i < track.length - 1; i++) {
        double aX = track[i].longitude * lngToMeters;
        double aY = track[i].latitude * latToMeters;
        double bX = track[i + 1].longitude * lngToMeters;
        double bY = track[i + 1].latitude * latToMeters;
        double lenSq = (bX - aX) * (bX - aX) + (bY - aY) * (bY - aY);
        double t = 0.0;
        if (lenSq != 0) {
            t = ((pX - aX) * (bX - aX) + (pY - aY) * (bY - aY)) / lenSq;
            t = t.clamp(0.0, 1.0);
        }
        double projX = aX + t * (bX - aX);
        double projY = aY + t * (bY - aY);
        double dSq = (pX - projX) * (pX - projX) + (pY - projY) * (pY - projY);
        if (dSq < minSqD) {
            minSqD = dSq;
            bestSnap = LatLng(projY / latToMeters, projX / lngToMeters);
        }
    }
    return bestSnap;
  }

  static LatLng? snapToTransfer(double lat, double lng) =>
      snapToTransferRoute(lat, lng)?.snappedPoint;

  static TransferRouteMatch? snapToTransferRoute(double lat, double lng) {
    TransferRoute? bestRoute;
    LatLng? bestSnap;
    double minSqD = double.infinity;
    final double latToMeters = 111139.0;
    final double lngToMeters = 111320.0 * 0.968;
    const double thresholdMeters = 55.0;
    final double threshSq = thresholdMeters * thresholdMeters;

    double pX = lng * lngToMeters;
    double pY = lat * latToMeters;

    for (final route in transferRoutes) {
      final track = route.path;
      for (int i = 0; i < track.length - 1; i++) {
        double aX = track[i].longitude * lngToMeters;
        double aY = track[i].latitude * latToMeters;
        double bX = track[i + 1].longitude * lngToMeters;
        double bY = track[i + 1].latitude * latToMeters;
        double lenSq = (bX - aX) * (bX - aX) + (bY - aY) * (bY - aY);
        double t = 0.0;
        if (lenSq != 0) {
          t = ((pX - aX) * (bX - aX) + (pY - aY) * (bY - aY)) / lenSq;
          t = t.clamp(0.0, 1.0);
        }
        double projX = aX + t * (bX - aX);
        double projY = aY + t * (bY - aY);
        double dSq = (pX - projX) * (pX - projX) + (pY - projY) * (pY - projY);
        if (dSq < minSqD && dSq <= threshSq) {
          minSqD = dSq;
          bestSnap = LatLng(projY / latToMeters, projX / lngToMeters);
          bestRoute = route;
        }
      }
    }
    if (bestSnap == null || bestRoute == null) return null;
    return TransferRouteMatch(snappedPoint: bestSnap, route: bestRoute);
  }

  static List<List<LatLng>> get transferWalkways =>
      transferRoutes.map((r) => r.path).toList();

  static final List<TransferRoute> transferRoutes = [
    TransferRoute(
      id: 'lrt1-dj-lrt2-recto',
      fromLine: 'LRT1', toLine: 'LRT2',
      fromStation: 'Doroteo Jose', toStation: 'Recto',
      distanceMeters: 250, isAirConditioned: false,
      walkDescription: '~250 m covered footbridge above Rizal Ave.',
      path: const [
        LatLng(14.60535, 120.98221), LatLng(14.605216, 120.982282),
        LatLng(14.60518, 120.98242), LatLng(14.6051, 120.9826),
        LatLng(14.605076, 120.98278), LatLng(14.6049, 120.98284),
        LatLng(14.603923, 120.982486),
      ],
    ),
    TransferRoute(
      id: 'lrt1-edsa-mrt3-taft',
      fromLine: 'LRT1', toLine: 'MRT3',
      fromStation: 'EDSA', toStation: 'Taft Avenue',
      distanceMeters: 150, isAirConditioned: true,
      walkDescription: '~150 m via Metropoint Mall.',
      path: const [
        LatLng(14.5386, 121.00072), LatLng(14.5383, 121.00082),
        LatLng(14.53798, 121.000855), LatLng(14.537779, 121.0012),
      ],
    ),
    TransferRoute(
      id: 'lrt2-cubao-mrt3-cubao',
      fromLine: 'LRT2', toLine: 'MRT3',
      fromStation: 'Araneta Center-Cubao', toStation: 'Araneta Center-Cubao',
      distanceMeters: 700, isAirConditioned: true,
      walkDescription: '~700 m via Gateway Mall & Farmers Plaza.',
      path: const [
        LatLng(14.6227, 121.05276), LatLng(14.6223, 121.05298),
        LatLng(14.6218, 121.05305), LatLng(14.6215, 121.05278),
        LatLng(14.6211, 121.05268), LatLng(14.6207, 121.05256),
        LatLng(14.6203, 121.05245), LatLng(14.6199, 121.05242),
        LatLng(14.619558, 121.052336), LatLng(14.619078, 121.051413),
      ],
    ),
    TransferRoute(
      id: 'lrt1-fpj-mrt3-north-ave',
      fromLine: 'LRT1', toLine: 'MRT3',
      fromStation: 'Fernando Poe Jr.', toStation: 'North Avenue',
      distanceMeters: 1400, isAirConditioned: false,
      walkDescription: 'Via EDSA Bus Carousel.',
      path: const [
        LatLng(14.6575, 121.0211), LatLng(14.6571, 121.0245),
        LatLng(14.656, 121.03), LatLng(14.652171, 121.032279),
      ],
    ),
  ];

  static const List<LatLng> lrt1Track = [
    LatLng(14.485355, 120.989323), LatLng(14.48575, 120.989527), LatLng(14.508441, 120.991257),
    LatLng(14.518438, 120.992987), LatLng(14.530283, 120.992936), LatLng(14.534255, 120.998362),
    LatLng(14.538783, 121.000628), LatLng(14.547748, 120.998617), LatLng(14.5614, 120.9955),
    LatLng(14.5755, 120.9886), LatLng(14.5868, 120.9822), LatLng(14.5919, 120.9818),
    LatLng(14.6053, 120.982), LatLng(14.628, 120.983), LatLng(14.6379, 120.9831),
    LatLng(14.6443, 120.9835), LatLng(14.6561, 120.9839), LatLng(14.6576, 121.0039),
    LatLng(14.6575, 121.0211),
  ];

  static const List<LatLng> lrt2Track = [
    LatLng(14.604271, 120.979501), LatLng(14.603806, 120.98195), LatLng(14.601052, 120.993129),
    LatLng(14.600606, 120.990527), LatLng(14.60112, 121.000618), LatLng(14.601587, 121.003858),
    LatLng(14.602631, 121.015037), LatLng(14.608528, 121.021641), LatLng(14.613526, 121.034156),
    LatLng(14.621095, 121.048951), LatLng(14.627043, 121.061515), LatLng(14.629514, 121.06969),
    LatLng(14.632296, 121.075494), LatLng(14.631175, 121.078327), LatLng(14.621427, 121.08662),
    LatLng(14.618613, 121.091566), LatLng(14.619953, 121.098239), LatLng(14.621468, 121.105535),
    LatLng(14.625382, 121.124032),
  ];

  static const List<LatLng> mrt3Track = [
    LatLng(14.537534, 121.000835), LatLng(14.53863, 121.009694), LatLng(14.539103, 121.012816),
    LatLng(14.542066, 121.019547), LatLng(14.550583, 121.029768), LatLng(14.558808, 121.039521),
    LatLng(14.566679, 121.045486), LatLng(14.580074, 121.052781), LatLng(14.5881, 121.056794),
    LatLng(14.607474, 121.056633), LatLng(14.619527, 121.051065), LatLng(14.629638, 121.046408),
    LatLng(14.635234, 121.043361), LatLng(14.652185, 121.032246),
  ];

  static LatLng interpolateAlongTrack(String lineName, LatLng start, LatLng end, double percent) {
    List<LatLng>? track;
    final normLine = lineName.replaceAll('-', '').toUpperCase();
    if (normLine == 'LRT1') track = lrt1Track;
    else if (normLine == 'LRT2') track = lrt2Track;
    else if (normLine == 'MRT3') track = mrt3Track;
    if (track == null || track.isEmpty) {
      return LatLng(
        start.latitude + (end.latitude - start.latitude) * percent,
        start.longitude + (end.longitude - start.longitude) * percent,
      );
    }
    int startIndex = findClosestIndex(track, start);
    int endIndex = findClosestIndex(track, end);
    if (startIndex == -1 || endIndex == -1) return start;
    if (startIndex == endIndex) return track[startIndex];
    List<LatLng> subPath = startIndex < endIndex 
        ? track.sublist(startIndex, endIndex + 1)
        : track.sublist(endIndex, startIndex + 1).reversed.toList();
    double totalDist = 0;
    List<double> segmentDistances = [];
    for (int i = 0; i < subPath.length - 1; i++) {
        double d = Geolocator.distanceBetween(
            subPath[i].latitude, subPath[i].longitude,
            subPath[i+1].latitude, subPath[i+1].longitude
        );
        segmentDistances.add(d);
        totalDist += d;
    }
    if (totalDist == 0) return start;
    double targetDist = percent * totalDist;
    double currentDist = 0;
    for (int i = 0; i < segmentDistances.length; i++) {
        if (currentDist + segmentDistances[i] >= targetDist) {
            double segmentPercent = (targetDist - currentDist) / segmentDistances[i];
            return LatLng(
                subPath[i].latitude + (subPath[i+1].latitude - subPath[i].latitude) * segmentPercent,
                subPath[i].longitude + (subPath[i+1].longitude - subPath[i].longitude) * segmentPercent,
            );
        }
        currentDist += segmentDistances[i];
    }
    return subPath.last;
  }

  static LatLng getTurnbackPosition(String lineName, Station terminus, double percent) {
    List<LatLng>? track;
    final normLine = lineName.replaceAll('-', '').toUpperCase();
    if (normLine == 'LRT1') track = lrt1Track;
    else if (normLine == 'LRT2') track = lrt2Track;
    else if (normLine == 'MRT3') track = mrt3Track;
    if (track == null || track.isEmpty) return LatLng(terminus.lat, terminus.lng);
    int stationIdx = findClosestIndex(track, LatLng(terminus.lat, terminus.lng));
    if (stationIdx == -1) return LatLng(terminus.lat, terminus.lng);
    int targetIdx = stationIdx < track.length / 2 ? 0 : track.length - 1;
    return LatLng(
      track[stationIdx].latitude + (track[targetIdx].latitude - track[stationIdx].latitude) * percent,
      track[stationIdx].longitude + (track[targetIdx].longitude - track[stationIdx].longitude) * percent,
    );
  }

  static int findClosestIndex(List<LatLng> track, LatLng point) {
    int bestIndex = -1;
    double minSqD = double.infinity;
    for (int i = 0; i < track.length; i++) {
      double dy = track[i].latitude - point.latitude;
      double dx = track[i].longitude - point.longitude;
      double dSq = dy * dy + dx * dx;
      if (dSq < minSqD) {
        minSqD = dSq;
        bestIndex = i;
      }
    }
    return bestIndex;
  }
}

class TransferRoute {
  final String id;
  final String fromLine;
  final String toLine;
  final String fromStation;
  final String toStation;
  final int distanceMeters;
  final bool isAirConditioned;
  final String walkDescription;
  final List<LatLng> path;
  const TransferRoute({
    required this.id, required this.fromLine, required this.toLine,
    required this.fromStation, required this.toStation,
    required this.distanceMeters, required this.isAirConditioned,
    required this.walkDescription, required this.path,
  });
  String get label => '$fromLine → $toLine';
  int get estimatedMinutes => (distanceMeters / 72).ceil();
}

class TransferRouteMatch {
  final LatLng snappedPoint;
  final TransferRoute route;
  const TransferRouteMatch({required this.snappedPoint, required this.route});
}
