import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class GeoJsonLoadException implements Exception {
  final String message;
  final String? assetPath;
  GeoJsonLoadException(this.message, [this.assetPath]);
  @override
  String toString() => 'GeoJsonLoadException: $message${assetPath != null ? ' ($assetPath)' : ''}';
}

class GeoJsonService {
  static final Map<String, List<LatLng>> _stationPolygons = {};
  static final List<List<LatLng>> _walkways = [];

  static List<LatLng>? getStationPolygon(String name) {
    // Exact match
    if (_stationPolygons.containsKey(name)) return _stationPolygons[name];
    
    // Fuzzy match using Jaro-Winkler
    String? bestMatch;
    double highestScore = 0.0;
    const double threshold = 0.85;

    final String query = _normalizeStationName(name);

    for (var stationName in _stationPolygons.keys) {
      final String target = _normalizeStationName(stationName);
      final double score = _jaroWinklerSimilarity(query, target);
      
      if (score > highestScore) {
        highestScore = score;
        bestMatch = stationName;
      }
    }

    if (highestScore >= threshold && bestMatch != null) {
      debugPrint('Fuzzy match found: "$name" -> "$bestMatch" (score: ${highestScore.toStringAsFixed(3)})');
      return _stationPolygons[bestMatch];
    }

    return null;
  }

  static String _normalizeStationName(String name) {
    return name.toLowerCase()
        .replaceAll('station', '')
        .replaceAll('stn', '')
        .replaceAll('ave', '')
        .replaceAll('st.', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  static double _jaroWinklerSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    int matchDistance = (max(s1.length, s2.length) / 2).floor() - 1;
    List<bool> s1Matches = List.filled(s1.length, false);
    List<bool> s2Matches = List.filled(s2.length, false);

    int matches = 0;
    for (int i = 0; i < s1.length; i++) {
      int start = max(0, i - matchDistance);
      int end = min(i + matchDistance + 1, s2.length);
      for (int j = start; j < end; j++) {
        if (!s2Matches[j] && s1[i] == s2[j]) {
          s1Matches[i] = true;
          s2Matches[j] = true;
          matches++;
          break;
        }
      }
    }

    if (matches == 0) return 0.0;

    double transpositions = 0;
    int k = 0;
    for (int i = 0; i < s1.length; i++) {
      if (s1Matches[i]) {
        while (!s2Matches[k]) k++;
        if (s1[i] != s2[k]) transpositions++;
        k++;
      }
    }

    double jaro = (matches / s1.length + matches / s2.length + (matches - transpositions / 2) / matches) / 3.0;
    
    // Winkler modification
    int prefix = 0;
    for (int i = 0; i < min(4, min(s1.length, s2.length)); i++) {
      if (s1[i] == s2[i]) prefix++;
      else break;
    }

    return jaro + (prefix * 0.1 * (1 - jaro));
  }

  static Future<Map<String, List<dynamic>>> loadAllLines() async {
    final List<Polygon> allPolygons = [];
    final List<Polyline> allPolylines = [];
    final List<String> errors = [];
    
    final files = [
      'assets/geojson/LRT-1 with tracks-stations-walkways.geojson',
      'assets/geojson/LRT-2 with tracks-stations.geojson',
      'assets/geojson/MRT-3 with tracks-stations.geojson',
    ];

    for (var file in files) {
      try {
        final data = await loadGeoJson(file);
        allPolygons.addAll(data['polygons'] as List<Polygon>);
        allPolylines.addAll(data['polylines'] as List<Polyline>);
      } catch (e) {
        errors.add(e.toString());
      }
    }

    if (errors.isNotEmpty && allPolygons.isEmpty && allPolylines.isEmpty) {
      throw GeoJsonLoadException("Failed to load any GeoJSON data:\n${errors.join('\n')}");
    } else if (errors.isNotEmpty) {
      debugPrint("GeoJsonService: Some files failed to load:\n${errors.join('\n')}");
    }

    return {
      'polygons': allPolygons,
      'polylines': allPolylines,
    };
  }

  static Future<Map<String, List<dynamic>>> loadGeoJson(String assetPath) async {
    try {
      final String response = await rootBundle.loadString(assetPath);
      final dynamic data;
      try {
        data = json.decode(response);
      } catch (e) {
        throw GeoJsonLoadException("Malformed JSON in GeoJSON file", assetPath);
      }
      
      final List<Polygon> polygons = [];
      final List<Polyline> polylines = [];

      if (data is! Map || data['type'] != 'FeatureCollection' || data['features'] == null) {
        throw GeoJsonLoadException("Invalid GeoJSON format: Expected FeatureCollection", assetPath);
      }

      for (var feature in data['features']) {
        final geometry = feature['geometry'];
        final properties = feature['properties'] ?? {};
        if (geometry == null || geometry['type'] == null || geometry['coordinates'] == null) continue;

        final type = geometry['type'];
        final coords = geometry['coordinates'];
        
        final colorStr = properties['_umap_options']?['color'] ?? 'Green';
        final color = _parseColor(colorStr);

        if (type == 'Polygon') {
          final String stationName = properties['name'] ?? 'Unknown';
          for (var ring in coords) {
            final List<LatLng> pointsList = [];
            for (var coord in ring) {
              if (coord is List && coord.length >= 2) {
                pointsList.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
              }
            }
            if (pointsList.isNotEmpty) {
              polygons.add(Polygon(
                points: pointsList,
                color: color.withValues(alpha: 0.3),
                borderColor: color,
                borderStrokeWidth: 2,
                isFilled: true,
              ));
              
              if (stationName != 'Unknown') {
                _stationPolygons[stationName] = pointsList;
              }
            }
          }
        } else if (type == 'LineString') {
          final List<LatLng> pointsList = [];
          for (var coord in coords) {
            if (coord is List && coord.length >= 2) {
              pointsList.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
            }
          }

          if (pointsList.isNotEmpty) {
            final String featureName = properties['name']?.toString().toLowerCase() ?? '';
            final bool isWalkway = featureName.contains('walkway');

            if (isWalkway) {
              _walkways.add(pointsList);
            }

            polylines.add(Polyline(
              points: pointsList,
              color: color,
              strokeWidth: isWalkway ? 4.0 : 6.0,
            ));
          }
        }
      }

      return {
        'polygons': polygons,
        'polylines': polylines,
      };
    } catch (e) {
      if (e is GeoJsonLoadException) rethrow;
      if (e is FlutterError || e is PlatformException) {
         throw GeoJsonLoadException("Asset not found or inaccessible", assetPath);
      }
      throw GeoJsonLoadException("Unexpected error loading GeoJSON: $e", assetPath);
    }
  }

  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int i, j = polygon.length - 1;
    bool oddNodes = false;
    double x = point.longitude;
    double y = point.latitude;

    for (i = 0; i < polygon.length; i++) {
      if ((polygon[i].latitude < y && polygon[j].latitude >= y ||
          polygon[j].latitude < y && polygon[i].latitude >= y) &&
          (polygon[i].longitude <= x || polygon[j].longitude <= x)) {
        if (polygon[i].longitude + (y - polygon[i].latitude) /
            (polygon[j].latitude - polygon[i].latitude) *
            (polygon[j].longitude - polygon[i].longitude) < x) {
          oddNodes = !oddNodes;
        }
      }
      j = i;
    }
    return oddNodes;
  }

  static Color _parseColor(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'green': return Colors.green;
      case 'purple': return Colors.purple;
      case 'yellow': return const Color(0xFFFFD700);
      case 'black': return Colors.black;
      case 'blue': return Colors.blue;
      case 'red': return Colors.red;
      default: return Colors.grey;
    }
  }

  static double? getWalkwayDistance(LatLng point) {
    if (_walkways.isEmpty) return null;
    
    double minD = double.infinity;
    for (var path in _walkways) {
      for (int i = 0; i < path.length - 1; i++) {
        final double dist = _distanceToSegment(point, path[i], path[i+1]);
        if (dist < minD) minD = dist;
      }
    }
    return minD;
  }

  static double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    const double latToMeters = 111139.0;
    const double lngToMeters = 111320.0 * 0.968;
    
    double px = p.longitude * lngToMeters;
    double py = p.latitude * latToMeters;
    double ax = a.longitude * lngToMeters;
    double ay = a.latitude * latToMeters;
    double bx = b.longitude * lngToMeters;
    double by = b.latitude * latToMeters;

    double l2 = (bx - ax) * (bx - ax) + (by - ay) * (by - ay);
    if (l2 == 0) return _dist(px, py, ax, ay);
    
    double t = ((px - ax) * (bx - ax) + (py - ay) * (by - ay)) / l2;
    t = t.clamp(0.0, 1.0);
    
    return _dist(px, py, ax + t * (bx - ax), ay + t * (by - ay));
  }

  static double _dist(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return sqrt(dx * dx + dy * dy);
  }
}
