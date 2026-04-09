import 'package:flutter/material.dart';
import '../data/metro_stations.dart';
import '../models/station.dart';
import '../screens/station_detail_screen.dart';

class StationSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _search(query);
    return _buildListView(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = _search(query);
    return _buildListView(results);
  }

  List<Map<String, dynamic>> _search(String query) {
    if (query.isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    return metroStations.where((s) {
      final name = s['name'].toString().toLowerCase();
      final line = s['line'].toString().toLowerCase();
      final city = (s['city'] ?? '').toString().toLowerCase();
      final landmark = (s['landmark'] ?? '').toString().toLowerCase();
      
      return name.contains(lowercaseQuery) || 
             line.contains(lowercaseQuery) || 
             city.contains(lowercaseQuery) ||
             landmark.contains(lowercaseQuery);
    }).toList();
  }

  Widget _buildListView(List<Map<String, dynamic>> results) {
    if (results.isEmpty && query.isNotEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No stations, cities, or landmarks found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final stationMap = results[index];
        final station = Station.fromMap(stationMap);
        final Color lineColor = _getLineColor(station.line);
        final String lineLogo = _getLineLogo(station.line);
        
        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: lineColor.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [BoxShadow(color: lineColor.withValues(alpha: 0.1), blurRadius: 4)],
            ),
            child: ClipOval(
              child: lineLogo.isNotEmpty
                ? Image.asset(lineLogo, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.train, color: lineColor, size: 20))
                : Icon(Icons.train, color: lineColor, size: 24),
            ),
          ),
          title: Text(station.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          subtitle: Text("${station.line} • ${station.city}\n${station.landmark}", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StationDetailScreen(station: station)),
            );
          },
        );
      },
    );
  }

  String _getLineLogo(String line) {
    if (line.contains('LRT')) return 'assets/image/LRTA.png';
    if (line == 'MRT3') return 'assets/image/MRT3.jpg';
    if (line == 'MRT7') return 'assets/image/MRT7.png';
    if (line == 'NSCR') return 'assets/image/PNR_Logo.png';
    return '';
  }

  Color _getLineColor(String line) {
    switch (line.toUpperCase()) {
      case 'LRT-1':
      case 'LRT1': return const Color(0xFF4CAF50);
      case 'LRT-2':
      case 'LRT2': return const Color(0xFF9C27B0);
      case 'MRT-3':
      case 'MRT3': return const Color(0xFFFFD54F);
      case 'MRT-4': return const Color(0xFF009688);
      case 'MRT-7':
      case 'MRT7': return const Color(0xFFEF5350);
      case 'NSCR':
      case 'NORTH-SOUTH COMMUTER RAILWAY': return const Color(0xFF800000);
      case 'SUBWAY':
      case 'MMS':
      case 'METRO MANILA SUBWAY': return const Color(0xFF1E3A8A);
      default: return const Color(0xFF64748B);
    }
  }
}
