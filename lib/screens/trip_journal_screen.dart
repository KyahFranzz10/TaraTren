import 'package:flutter/material.dart';
import '../services/trip_log_service.dart';
import 'package:intl/intl.dart';

class TripJournalScreen extends StatelessWidget {
  const TripJournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TripLogService service = TripLogService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Trip Journal'),
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear All Journals',
            onPressed: () => _confirmClear(context, service),
          ),
        ],
      ),
      body: StreamBuilder<List<TripLog>>(
        stream: service.getTripLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _emptyState();
          }

          final logs = snapshot.data!;
          final totalSpent = logs.fold<double>(0, (sum, item) => sum + item.fare);
          final journeys = _groupLogsIntoJourneys(logs);

          return Column(
            children: [
              _summaryHeader(journeys.length, totalSpent),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                  itemCount: journeys.length,
                  itemBuilder: (context, index) => _journeyCard(journeys[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryHeader(int count, double total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B3E), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1B3E).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          const Text('Total Commute Spending', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('₱${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statItem(Icons.map_outlined, '$count Journeys'),
              const SizedBox(width: 30),
              _statItem(Icons.savings, '₱${(total * 0.2).toStringAsFixed(1)} Saved'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 16),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  List<List<TripLog>> _groupLogsIntoJourneys(List<TripLog> logs) {
    if (logs.isEmpty) return [];
    
    List<List<TripLog>> journeys = [];
    List<TripLog> currentJourney = [logs[0]];
    
    for (int i = 1; i < logs.length; i++) {
      final currentLog = logs[i];
      
      // If the current log is within 90 minutes of the journey's most recent leg
      final lastLog = currentJourney.last;
      final diff = lastLog.timestamp.difference(currentLog.timestamp).inMinutes.abs();
      
      if (diff < 90) {
        currentJourney.add(currentLog);
      } else {
        journeys.add(currentJourney);
        currentJourney = [currentLog];
      }
    }
    journeys.add(currentJourney);
    return journeys;
  }

  Widget _journeyCard(List<TripLog> logs) {
    if (logs.length == 1) {
      return _tripCard(logs[0]);
    }

    final totalFare = logs.fold<double>(0, (sum, log) => sum + log.fare);
    final journeyDate = DateFormat('MMM d, h:mm a').format(logs.last.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Multi-leg Journey', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                      Text(journeyDate, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    Text('₱${totalFare.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.indigo)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
            ),
            itemBuilder: (context, index) => _tripLeg(logs[index]),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tripLeg(TripLog log) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              color: _getLineColor(log.line),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${log.fromStation} → ${log.toStation}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text(
                  '${log.line} • PHP ${log.fare.toInt()}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripCard(TripLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getLineColor(log.line).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.directions_transit, color: _getLineColor(log.line)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${log.fromStation} → ${log.toStation}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM d, h:mm a').format(log.timestamp)} • ${log.line}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '₱${log.fare.toInt()}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.indigo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text('No Trip Journals Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
            child: Text(
              'Your logged trips from the station details will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, TripLogService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Journal?'),
        content: const Text('Are you sure you want to delete all trip history? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              service.clearLogs();
              Navigator.pop(context);
            }, 
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getLineColor(String line) {
    final l = line.toUpperCase();
    if (l.contains('LRT1')) return Colors.green;
    if (l.contains('LRT2')) return Colors.purple;
    if (l.contains('MRT3')) return Colors.yellow.shade700;
    return Colors.indigo;
  }
}
