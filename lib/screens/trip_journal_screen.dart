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

          return Column(
            children: [
              _summaryHeader(logs.length, totalSpent),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) => _tripCard(logs[index]),
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
        boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 10)],
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
              _statItem(Icons.train, '$count Trips'),
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

  Widget _tripCard(TripLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
    if (line == 'LRT1') return Colors.green;
    if (line == 'LRT2') return Colors.purple;
    if (line == 'MRT3') return Colors.yellow.shade700;
    return Colors.indigo;
  }
}
