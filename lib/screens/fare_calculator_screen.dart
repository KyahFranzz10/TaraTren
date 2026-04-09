import 'package:flutter/material.dart';
import '../models/station.dart';
import '../data/mock_data.dart';
import '../services/fare_service.dart';
import '../services/settings_service.dart';

class FareCalculatorScreen extends StatefulWidget {
  final TrainLine? initialLine;
  const FareCalculatorScreen({super.key, this.initialLine});

  @override
  State<FareCalculatorScreen> createState() => _FareCalculatorScreenState();
}

class _FareCalculatorScreenState extends State<FareCalculatorScreen> {
  late List<TrainLine> _operationalLines;
  TrainLine? _selectedLine;
  Station? _sourceStation;
  Station? _destStation;
  final FareService _fareService = FareService();
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    
    // Filter only operational lines and their active stations
    _operationalLines = trainLines.where((line) => 
      ['LRT-1', 'LRT-2', 'MRT-3'].contains(line.name)
    ).map((line) {
      // Create a copy with filtered stations (removing future extensions)
      return TrainLine(
        name: line.name,
        color: line.color,
        scheduleSummary: line.scheduleSummary,
        fullSchedule: line.fullSchedule,
        fareInfo: line.fareInfo,
        logoAsset: line.logoAsset,
        coverAsset: line.coverAsset,
        stations: line.stations.where((s) => s.isExtension != true).toList(),
      );
    }).toList();

    _selectedLine = widget.initialLine != null 
        ? _operationalLines.firstWhere((l) => l.name == widget.initialLine!.name, orElse: () => _operationalLines.first)
        : _operationalLines.first;

    if (_selectedLine!.stations.isNotEmpty) {
      _sourceStation = _selectedLine!.stations.first;
      _destStation = _selectedLine!.stations.last;
    }
  }

  Map<String, dynamic> _calculateFares() {
    if (_sourceStation == null || _destStation == null) {
      return {'sv': 0, 'sj': 0, 'sv50': 0, 'sj50': 0};
    }
    return _fareService.getFareResult(_sourceStation!, _destStation!, userType: _settings.userType);
  }

  @override
  Widget build(BuildContext context) {
    final fares = _calculateFares();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fare Calculator'),
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Line Selection
            const Text('Choose Tren Line', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TrainLine>(
                  isExpanded: true,
                  value: _selectedLine,
                  items: _operationalLines.map((line) => DropdownMenuItem(value: line, child: Text(line.name))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedLine = val;
                      _sourceStation = val!.stations.first;
                      _destStation = val.stations.last;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 2. From/To Selection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Origin Station', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      DropdownButton<Station>(
                        isExpanded: true,
                        value: _sourceStation,
                        items: _selectedLine!.stations.map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) => setState(() => _sourceStation = val),
                      ),
                    ],
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.compare_arrows, color: Colors.blueGrey)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Destination', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      DropdownButton<Station>(
                        isExpanded: true,
                        value: _destStation,
                        items: _selectedLine!.stations.map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) => setState(() => _destStation = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 3. Price Results
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B3E).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF0D1B3E).withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  const Text('Commuter Fare Matrix', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E))),
                  if (fares['isFreeRide'] == 1) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade500]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 8)],
                      ),
                      child: Column(
                        children: [
                          const Text("🎁 LIBRENG SAKAY", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                          Text("${fares['freeRideEvent']}", style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text("Valid: ${fares['freeRideDuration']}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ] else if (fares['isPromo'] == 1) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.shade800, borderRadius: BorderRadius.circular(8)),
                      child: const Text("PROMO: 50% OFF FOR ALL", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                  ],
                  const SizedBox(height: 25),
                  
                  // THE FOUR REQUESTED FARE CATEGORIES
                  _fareRow('Single Journey Card', fares['isFreeRide'] == 1 ? 'FREE' : '₱${fares['sj_base']?.toStringAsFixed(2)}', fares['isFreeRide'] == 1 ? Colors.green : Colors.orange),
                  const Divider(height: 24),

                  _fareRow('Single Journey Card (Senior/Student)', fares['isFreeRide'] == 1 ? 'FREE' : '₱${fares['sj50']?.toStringAsFixed(2)}', fares['isFreeRide'] == 1 ? Colors.green : Colors.orange.shade700, subtitle: fares['isFreeRide'] == 1 ? null : "50% Discount Applied"),
                  const Divider(height: 24),
                  
                  _fareRow('Stored Value Card', fares['isFreeRide'] == 1 ? 'FREE' : '₱${fares['sv_base']?.toStringAsFixed(2)}', fares['isFreeRide'] == 1 ? Colors.green : Colors.blue),
                  const Divider(height: 24),

                  _fareRow('Stored Value Card for Senior/Student', fares['isFreeRide'] == 1 ? 'FREE' : '₱${fares['sv50']?.toStringAsFixed(2)}', fares['isFreeRide'] == 1 ? Colors.green : Colors.blue.shade700, subtitle: fares['isFreeRide'] == 1 ? null : "50% Discount Applied"),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text("White Beep Cards provide the highest discount (50%) for eligible Philippine citizens.", style: TextStyle(fontSize: 11, color: Colors.black87),))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _fareRow(String title, String val, Color color, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
