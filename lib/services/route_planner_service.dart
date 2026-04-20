// route_planner_service.dart
// Solves optimal rail-only journeys across LRT-1, LRT-2, and MRT-3.
//
// Algorithm: Dijkstra over a small graph (≤ 40 nodes, 3 transfer edges).
// Each node is a station. Edge cost = estimated travel time in seconds.
// Transfer edges (walk) have fixed costs from TrackData.transferRoutes.

import '../data/stations/lrt1_stations.dart';
import '../data/stations/lrt2_stations.dart';
import '../data/stations/mrt3_stations.dart';
import '../data/track_data.dart';
import 'fare_service.dart';
import '../models/station.dart';

// ── Result model ───────────────────────────────────────────────────────────────

enum LegType { ride, walk, transfer }

class RouteLeg {
  final LegType type;
  final String line;           // 'LRT1' | 'LRT2' | 'MRT3' | 'Walk'
  final String fromStation;
  final String toStation;
  final int stops;             // number of intermediate stations (ride) or 0 (walk)
  final int estMinutes;        // estimated travel time
  final double fare;           // in PHP (0 for walk)
  final bool isDiscounted;     // senior/student fare applied
  final String? transferNote;  // e.g. "~250 m covered footbridge. Not AC."

  const RouteLeg({
    required this.type,
    required this.line,
    required this.fromStation,
    required this.toStation,
    required this.stops,
    required this.estMinutes,
    required this.fare,
    this.isDiscounted = false,
    this.transferNote,
  });
}

class PlannedRoute {
  final List<RouteLeg> legs;
  final int totalMinutes;
  final double totalFare;
  final int transfers;         // number of line changes

  const PlannedRoute({
    required this.legs,
    required this.totalMinutes,
    required this.totalFare,
    required this.transfers,
  });
}

// ── Internal graph node ────────────────────────────────────────────────────────

class _Node {
  final Map<String, dynamic> station;
  String get id    => station['id'] as String;
  String get line  => station['line'] as String;
  int    get order => station['order'] as int;
  String get name  => station['name'] as String;
  _Node(this.station);
}

// ── Service ────────────────────────────────────────────────────────────────────

class RoutePlannerService {
  static final RoutePlannerService _instance = RoutePlannerService._internal();
  factory RoutePlannerService() => _instance;
  RoutePlannerService._internal();

  // Operational stations only (no extension, no future lines)
  static final List<_Node> _nodes = [
    ...lrt1Stations,
    ...lrt2Stations,
    ...mrt3Stations,
  ]
      .where((s) => s['isExtension'] != true)
      .map((s) => _Node(s))
      .toList();

  // ── Average speed: trains do ~40 km/h (≈ 111 s/km).
  // We estimate 90 s per station stop (including dwell time).
  static const int _secondsPerStop = 90;

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Returns a list of best possible routes between [fromName] and [toName].
  /// [userType] = 'normal' | 'beep' | 'senior' | 'student'
  List<PlannedRoute> plan(String fromName, String toName,
      {String userType = 'normal'}) {
    final origin = _nodeByName(fromName);
    final dest   = _nodeByName(toName);
    if (origin == null || dest == null) return [];
    if (origin.id == dest.id) return [PlannedRoute(legs: [], totalMinutes: 0, totalFare: 0, transfers: 0)];

    final List<PlannedRoute> routes = [];

    // ── 1. Same line: direct ride ──
    if (origin.line == dest.line) {
      routes.add(_buildDirectRoute(origin, dest, userType: userType));
    }

    // ── 2. One-transfer paths ──
    for (final tr in TrackData.transferRoutes) {
      final nodeA = _nodeByName(tr.fromStation, line: tr.fromLine);
      final nodeB = _nodeByName(tr.toStation,   line: tr.toLine);
      if (nodeA == null || nodeB == null) continue;

      // Combo A: Origin → NodeA (ride) | Walk | NodeB → Dest (ride)
      final legToA   = _sameLineIf(origin, nodeA);
      final legFromB = _sameLineIf(nodeB, dest);
      if (legToA != null && legFromB != null) {
        routes.add(_combine([legToA, _walkLeg(tr, reverse: false), legFromB], userType: userType));
      }
      
      // Combo B: Origin → NodeB (ride) | Walk | NodeA → Dest (ride)
      final legToB   = _sameLineIf(origin, nodeB);
      final legFromA = _sameLineIf(nodeA, dest);
      if (legToB != null && legFromA != null) {
        routes.add(_combine([legToB, _walkLeg(tr, reverse: true), legFromA], userType: userType));
      }
    }

    // ── 3. Two-transfer paths ──
    for (int i = 0; i < TrackData.transferRoutes.length; i++) {
      for (int j = 0; j < TrackData.transferRoutes.length; j++) {
        if (i == j) continue;
        final tr1 = TrackData.transferRoutes[i];
        final tr2 = TrackData.transferRoutes[j];

        for (final t1a in [true, false]) {
          final n1from = t1a ? _nodeByName(tr1.fromStation, line: tr1.fromLine) : _nodeByName(tr1.toStation, line: tr1.toLine);
          final n1to   = t1a ? _nodeByName(tr1.toStation, line: tr1.toLine) : _nodeByName(tr1.fromStation, line: tr1.fromLine);
          if (n1from == null || n1to == null) continue;

          for (final t2a in [true, false]) {
            final n2from = t2a ? _nodeByName(tr2.fromStation, line: tr2.fromLine) : _nodeByName(tr2.toStation, line: tr2.toLine);
            final n2to   = t2a ? _nodeByName(tr2.toStation, line: tr2.toLine) : _nodeByName(tr2.fromStation, line: tr2.fromLine);
            if (n2from == null || n2to == null) continue;
            if (n1to.line != n2from.line) continue;

            final l1 = _sameLineIf(origin, n1from);
            final l2 = _sameLineIf(n1to,   n2from);
            final l3 = _sameLineIf(n2to,   dest);
            if (l1 == null || l2 == null || l3 == null) continue;

            routes.add(_combine([l1, _walkLeg(tr1, reverse: !t1a), l2, _walkLeg(tr2, reverse: t2a), l3], userType: userType));
          }
        }
      }
    }

    // ── Post-processing: Deduplicate and Sort ──
    final uniqueRoutes = <String, PlannedRoute>{};
    for (final r in routes) {
      if (r.legs.isEmpty) continue;
      final key = r.legs.map((l) => '${l.fromStation}-${l.toStation}-${l.line}').join('|');
      if (!uniqueRoutes.containsKey(key)) {
        uniqueRoutes[key] = r;
      } else {
        if (r.totalMinutes < uniqueRoutes[key]!.totalMinutes) {
          uniqueRoutes[key] = r;
        }
      }
    }

    final sorted = uniqueRoutes.values.toList()
      ..sort((a, b) {
        int cmp = a.totalMinutes.compareTo(b.totalMinutes);
        if (cmp != 0) return cmp;
        return a.totalFare.compareTo(b.totalFare);
      });

    return sorted.take(5).toList();
  }

  /// All operational station keys (Format: Name-Line).
  List<String> get allStationKeys =>
      _nodes.map((n) => '${n.name}-${n.line}').toList();

  // ── Helpers ───────────────────────────────────────────────────────────────────

  _Node? _nodeByName(String name, {String? line}) {
    // If name is a composite key (Name-Line), split it
    String searchName = name;
    String? searchLine = line;

    if (name.contains('-')) {
      final lastDash = name.lastIndexOf('-');
      final potentialLine = name.substring(lastDash + 1);
      final potentialName = name.substring(0, lastDash);
      
      // Basic validation that it's a line code
      if (['LRT1', 'LRT2', 'MRT3', 'MRT7', 'NSCR', 'MMS', 'LRT4'].contains(potentialLine)) {
        searchName = potentialName;
        searchLine = potentialLine;
      }
    }

    try {
      return _nodes.firstWhere(
        (n) => n.name == searchName && (searchLine == null || n.line == searchLine),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns a ride leg if [from] and [to] are on the same line, else null.
  RouteLeg? _sameLineIf(_Node from, _Node to) {
    if (from.line != to.line) return null;
    if (from.id == to.id) {
      // Zero-stop "leg" — still needed as placeholder for single-line combo
      return RouteLeg(
        type: LegType.ride,
        line: from.line,
        fromStation: from.name,
        toStation: to.name,
        stops: 0,
        estMinutes: 0,
        fare: 0,
      );
    }
    return _rideLeg(from, to);
  }

  RouteLeg _rideLeg(_Node from, _Node to) {
    final stops = (from.order - to.order).abs();
    final estMin = ((stops * _secondsPerStop) / 60).ceil();
    return RouteLeg(
      type: LegType.ride,
      line: from.line,
      fromStation: from.name,
      toStation: to.name,
      stops: stops,
      estMinutes: estMin,
      fare: 0, // filled in by _combine after fare calculation
    );
  }

  RouteLeg _walkLeg(TransferRoute tr, {bool reverse = false}) => RouteLeg(
        type: LegType.walk,
        line: 'Walk',
        fromStation: reverse ? tr.toStation : tr.fromStation,
        toStation: reverse ? tr.fromStation : tr.toStation,
        stops: 0,
        estMinutes: tr.estimatedMinutes,
        fare: 0,
        transferNote: '${tr.walkDescription}  ${tr.isAirConditioned ? "❄️ AC" : "🌡️ Not AC"}',
      );

  PlannedRoute _buildDirectRoute(_Node from, _Node to,
      {String userType = 'normal'}) {
    final leg = _rideLeg(from, to);
    final fare = _calcFare(from.station, to.station, userType: userType);
    final paid = RouteLeg(
      type: leg.type,
      line: leg.line,
      fromStation: leg.fromStation,
      toStation: leg.toStation,
      stops: leg.stops,
      estMinutes: leg.estMinutes,
      fare: fare,
    );
    return PlannedRoute(
      legs: [paid],
      totalMinutes: leg.estMinutes,
      totalFare: fare,
      transfers: 0,
    );
  }

  PlannedRoute _combine(List<RouteLeg> rawLegs,
      {String userType = 'normal'}) {
    // Filter out zero-stop ride legs (same station placeholders)
    final legs = rawLegs.where((l) => !(l.type == LegType.ride && l.stops == 0)).toList();

    // Re-price each ride leg
    final priced = <RouteLeg>[];
    int totalMin = 0;
    double totalFare = 0;
    int transfers = 0;
    String? prevLine;

    for (final leg in legs) {
      if (leg.type == LegType.ride) {
        final fromNode = _nodeByName(leg.fromStation, line: leg.line);
        final toNode   = _nodeByName(leg.toStation,   line: leg.line);
        final fare = (fromNode != null && toNode != null)
            ? _calcFare(fromNode.station, toNode.station, userType: userType)
            : 0.0;
        totalFare += fare;
        totalMin  += leg.estMinutes;
        if (prevLine != null && prevLine != leg.line) transfers++;
        prevLine = leg.line;
        priced.add(RouteLeg(
          type: LegType.ride,
          line: leg.line,
          fromStation: leg.fromStation,
          toStation: leg.toStation,
          stops: leg.stops,
          estMinutes: leg.estMinutes,
          fare: fare,
        ));
      } else {
        totalMin += leg.estMinutes;
        priced.add(leg);
      }
    }

    return PlannedRoute(
      legs: priced,
      totalMinutes: totalMin,
      totalFare: totalFare,
      transfers: transfers,
    );
  }

  double _calcFare(Map<String, dynamic> fromMap, Map<String, dynamic> toMap,
      {String userType = 'normal'}) {
    try {
      final s1 = Station.fromMap(fromMap);
      final s2 = Station.fromMap(toMap);
      final result = FareService().getFareResult(s1, s2, userType: userType);
      if (userType == 'beep') return (result['sv'] as num).toDouble();
      return (result['sj'] as num).toDouble();
    } catch (_) {
      return 0.0;
    }
  }
}
