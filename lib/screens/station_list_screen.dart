import 'package:flutter/material.dart';
import '../models/station.dart';
import 'station_detail_screen.dart';

class StationListScreen extends StatelessWidget {
  final TrainLine trainLine;

  const StationListScreen({super.key, required this.trainLine});

  @override
  Widget build(BuildContext context) {
    final bool isFutureLine = ['MRT-7', 'Metro Manila Subway', 'North-South Commuter Railway', 'MRT-4', 'MMS', 'NSCR'].contains(trainLine.name);
    final bool isMRT3 = trainLine.name == 'MRT-3';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            stretch: true,
            backgroundColor: Color(trainLine.color),
            leading: const BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 20),
              title: LayoutBuilder(
                builder: (context, constraints) {
                  final double top = constraints.biggest.height;
                  final bool isCollapsed = top <= (MediaQuery.of(context).padding.top + kToolbarHeight + 10);
                  // For MRT-3, text is white on image (expanded), black on yellow bar (collapsed)
                  final Color titleColor = (isMRT3 && isCollapsed) ? Colors.black : Colors.white;
                  final Color subtextColor = (isMRT3 && isCollapsed) ? Colors.black54 : Colors.white70;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 32, // Smaller for the animated title
                        height: 32,
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            trainLine.logoAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(Icons.train, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trainLine.name,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                shadows: (titleColor == Colors.white) 
                                    ? [const Shadow(color: Colors.black54, blurRadius: 10)] 
                                    : [],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Transit Line'.toUpperCase(),
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover Image
                  Image.asset(
                    trainLine.coverAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Color(trainLine.color).withValues(alpha: 0.5)),
                  ),
                  // Dark Gradient for readability
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black45, Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05), 
                    blurRadius: 15, 
                    offset: const Offset(0, 5)
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: const Icon(Icons.access_time_filled_rounded, size: 20, color: Colors.indigo),
                      ),
                      const SizedBox(width: 12),
                      const Text('Operating Hours', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isFutureLine ? "System opening dates to be announced by DOTr." : trainLine.fullSchedule,
                    style: TextStyle(fontSize: 14, height: 1.5, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)),
                  ),
                  if (!isFutureLine) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: const Icon(Icons.payments_rounded, size: 20, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Text('Fare Rates (${trainLine.name})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...trainLine.fareInfo.map((fare) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(trainLine.color))),
                              Expanded(child: Text(fare, style: const TextStyle(fontSize: 13, height: 1.4))),
                            ],
                          ),
                        )),
                    
                    // ── ROLLING STOCK SECTION ──────────────────────
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: const Icon(Icons.train_rounded, size: 20, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        const Text('Rolling Stock', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _getTrainsForLine(trainLine.name).map((train) => _buildTrainCard(context, train['name']!, train['path']!)).toList(),
                      ),
                    ),
                  ] else ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text('Line under construction', style: TextStyle(fontSize: 13, color: Colors.orange.shade800, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Show future fleet for non-open lines too
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _getTrainsForLine(trainLine.name).map((train) => _buildTrainCard(context, train['name']!, train['path']!)).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final station = trainLine.stations[index];
                  final bool isLast = index == trainLine.stations.length - 1;
                  
                  return Column(
                    children: [
                      _buildStationTile(context, station),
                      if (!isLast) _buildTravelTimeDivider(context, index),
                    ],
                  );
                },
                childCount: trainLine.stations.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationTile(BuildContext context, Station station) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            station.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Color(trainLine.color).withValues(alpha: 0.1),
              child: Icon(Icons.train, color: Color(trainLine.color)),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              station.name,
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 17, 
                color: Theme.of(context).textTheme.titleLarge?.color
              ),
            ),
          ),
          if (station.isExtension)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)),
              child: const Text('FUTURE', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w900)),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (station.landmark != "Not specified.")
              Text(station.landmark, style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor, height: 1.2)),
            const SizedBox(height: 6),
            Row(
              children: [
                if (!station.isExtension) ...[
                  _smallAccessIcon(Icons.elevator_rounded, station.hasElevator),
                  _smallAccessIcon(Icons.escalator_rounded, station.hasEscalator),
                  _smallAccessIcon(Icons.accessible_rounded, station.isAccessible),
                ],
                if (station.isTransfer)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(4)),
                      child: const Text("TRANSFER", style: TextStyle(fontSize: 9, color: Colors.indigo, fontWeight: FontWeight.w900)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Theme.of(context).dividerColor.withOpacity(0.05), shape: BoxShape.circle),
        child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Theme.of(context).hintColor),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StationDetailScreen(station: station)),
        );
      },
    );
  }

  Widget _buildTravelTimeDivider(BuildContext context, int index) {
    final s1 = trainLine.stations[index];
    final s2 = trainLine.stations[index + 1];
    final minutes = _getTravelTime(s1, s2);

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const SizedBox(width: 30), // Center of image
          Container(
            width: 2,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(trainLine.color).withValues(alpha: 0.5), Color(trainLine.color).withValues(alpha: 0.1)],
              ),
            ),
          ),
          const SizedBox(width: 48),
          if (!['MRT-7', 'Metro Manila Subway', 'North-South Commuter Railway', 'MRT-4', 'MMS', 'NSCR'].contains(trainLine.name) && !s1.isExtension && !s2.isExtension)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Text(
                "$minutes mins travel",
                style: TextStyle(fontSize: 10, color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey.shade500, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(child: Container()),
        ],
      ),
    );
  }

  int _getTravelTime(Station s1, Station s2) {
    // Default fallback
    int mins = 2;

    // Manila specific rail durations
    final String line = s1.line.toUpperCase();
    
    // LRT-1 (Green Line)
    if (line == 'LRT1') {
      if (s1.name.contains('Fernando Poe') && s2.name.contains('Balintawak')) return 2;
      if (s1.name.contains('Balintawak') && s2.name.contains('Monumento')) return 4;
      return 3; // Most other LRT-1 stations are 3 mins apart
    }

    // LRT-2 (Purple Line)
    if (line == 'LRT2') {
      if (s1.name.contains('Katipunan') && s2.name.contains('Santolan')) return 3;
      if (s1.name.contains('Marikina') && s2.name.contains('Antipolo')) return 3;
      return 2; // Flat 2 mins for urban segments
    }

    // MRT-3 (Yellow Line)
    if (line == 'MRT3') {
      if (s1.name.contains('North Ave') && s2.name.contains('Quezon Ave')) return 3;
      if (s1.name.contains('Ayala') && s2.name.contains('Magallanes')) return 3;
      return 2;
    }

    return mins;
  }

  List<Map<String, String>> _getTrainsForLine(String lineName) {
    if (lineName.contains('LRT-1')) {
      return [
        {'name': 'Generation 1', 'path': 'assets/image/Trains/LRT1-G1.jpg'},
        {'name': 'Generation 2', 'path': 'assets/image/Trains/LRT1-G2.jpg'},
        {'name': 'Generation 3', 'path': 'assets/image/Trains/LRT1-G3.jpg'},
        {'name': 'Generation 4', 'path': 'assets/image/Trains/LRT1-G4.jpg'},
      ];
    } else if (lineName.contains('LRT-2')) {
      return [
        {'name': 'Rotem/Hyundai 2000', 'path': 'assets/image/Trains/LRT2-2000.jpg'},
      ];
    } else if (lineName.contains('MRT-3')) {
      return [
        {'name': 'Tatra RT8D5M', 'path': 'assets/image/Trains/MRT3-Tatra.jpg'},
        {'name': 'CNR Dalian 8000', 'path': 'assets/image/Trains/MRT3-Dalian.jpg'},
      ];
    } else if (lineName.contains('MRT-7')) {
      return [
        {'name': 'Hyundai Rotem EMU', 'path': 'assets/image/Trains/MRT-7_trains_2021.png'},
      ];
    } else if (lineName.contains('North-South')) {
      return [
        {'name': 'Sustina EMU100000', 'path': 'assets/image/Trains/NSCR-EMU100000.jpg'},
      ];
    }
    return [];
  }

  Widget _buildTrainCard(BuildContext context, String name, String path) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Expanded(
              child: Image.asset(path, fit: BoxFit.cover, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).textTheme.bodySmall?.color
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallAccessIcon(IconData icon, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            size: 14,
            color: isAvailable ? Colors.green.shade600 : Colors.grey.shade300,
          ),
          if (!isAvailable)
            Icon(
              Icons.close_rounded,
              size: 16,
              color: Colors.red.shade400.withValues(alpha: 0.8),
            ),
        ],
      ),
    );
  }
}

