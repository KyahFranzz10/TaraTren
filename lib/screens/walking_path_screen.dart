import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/transfer_path.dart';
import '../widgets/cached_tile_provider.dart';

class WalkingPathScreen extends StatelessWidget {
  final TransferPath path;
  final String fromName;
  final String toName;

  const WalkingPathScreen({
    super.key,
    required this.path,
    required this.fromName,
    required this.toName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transfer Guide"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.transfer_within_a_station, color: Colors.indigo, size: 20),
                          const SizedBox(width: 8),
                          Text("$fromName ↔ $toName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.directions_walk, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text("${path.distanceMeters}m total distance", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(width: 16),
                          const Icon(Icons.timer_outlined, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text("${path.estMinutes} mins walking time", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Map view
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: path.points[0],
                    initialZoom: 17.5,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      tileProvider: CachedTileProvider(),
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: path.points,
                          color: Colors.indigo,
                          strokeWidth: 5,
                          isDotted: true,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: path.points.first,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                        ),
                        Marker(
                          point: path.points.last,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.green, size: 30),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                    child: const Text("Walking Path", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Directions list
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey.shade50,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: path.instructions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(color: index == 0 ? Colors.green.withValues(alpha: 0.1) : Colors.indigo.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(color: index == 0 ? Colors.green : Colors.indigo, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                path.instructions[index],
                                style: const TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 12),
                              if (index < path.instructions.length - 1)
                                Container(width: 1, height: 12, color: Colors.grey.shade300, margin: const EdgeInsets.only(left: 0)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
