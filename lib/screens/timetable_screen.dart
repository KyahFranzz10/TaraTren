import 'package:flutter/material.dart';
import '../data/lrt1_timetable.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('LRT-1 Timetable', style: TextStyle(fontWeight: FontWeight.w900)),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Southbound', icon: Icon(Icons.arrow_downward)),
              Tab(text: 'Northbound', icon: Icon(Icons.arrow_upward)),
            ],
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            _buildOperationalHeader(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTimetableList(lrt1SouthboundTimetable),
                  _buildTimetableList(lrt1NorthboundTimetable),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'LINE OPERATIONAL OVERVIEW',
            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('FIRST TRAIN', lrt1Stats.operatingFirst, Icons.wb_sunny_outlined),
              _statItem('LAST TRAIN', lrt1Stats.operatingLast, Icons.nights_stay_outlined),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _fleetItem('PEAK FLEET', '${lrt1Stats.peakTrains} Trains', Colors.orangeAccent),
                Container(width: 1, height: 30, color: Colors.white24),
                _fleetItem('OFF-PEAK', '${lrt1Stats.offPeakTrains} Trains', Colors.blueAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String time, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(time, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _fleetItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimetableList(List<TimetableEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;
        
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline Column
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green.shade700, width: 2),
                    ),
                    child: Center(
                      child: Text('${index + 1}', style: TextStyle(color: Colors.green.shade900, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.green.shade200,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.stationName,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0D1B3E)),
                              ),
                            ),
                            if (entry.distanceToNext != null && entry.distanceToNext! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  '${entry.distanceToNext} km to next',
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _timeBox('FIRST', entry.firstTrain, Colors.orange.shade700),
                            const SizedBox(width: 12),
                            _timeBox('LAST', entry.lastTrain, Colors.indigo.shade700),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _timeBox(String label, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
          Text(time, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
