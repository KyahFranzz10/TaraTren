// future_line_models.dart — Shared models for future train lines
// Used by all individual future line data files.

import 'package:latlong2/latlong.dart';

class FutureStation {
  final String name;
  final LatLng position;
  final String city;
  final String? code;
  final String? nearby;
  final String? connections;
  final String? imageUrl;

  FutureStation({
    required this.name,
    required this.position,
    required this.city,
    this.code,
    this.nearby,
    this.connections,
    this.imageUrl,
  });
}

class FutureLine {
  final String name;
  final List<FutureStation> stations;
  final List<LatLng>? trackPoints;
  final int color;
  final String status;
  final String? bgImage;
  final String? logoAsset;
  final dynamic icon; // IconData or similar

  FutureLine({
    required this.name,
    required this.stations,
    required this.color,
    required this.status,
    this.trackPoints,
    this.bgImage,
    this.logoAsset,
    this.icon,
  });

  List<LatLng> get points => trackPoints ?? stations.map((s) => s.position).toList();
}
