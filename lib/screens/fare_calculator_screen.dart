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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Fare Calculator'),
        backgroundColor: isDark ? Colors.black : const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Heritage Header
            _buildHeader(),

            // 2. Journey Selection Card
            _buildSelectionCard(),

            const SizedBox(height: 16),

            // 3. Price Results Card
            _buildMatrixCard(fares),

            const SizedBox(height: 24),
            
            // 4. White Beep Info
            _buildInfoTile(),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            color: const Color(0xFF0D1B3E).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedLine?.name.toUpperCase() ?? "SELECT LINE",
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          const Text(
            "COMMUTER PRICING",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Calculated based on current operating matrices",
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: isDark ? Theme.of(context).colorScheme.surfaceContainer : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _dropDown<TrainLine>(
              label: "CHOOSE TREN LINE",
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
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)),
            Row(
              children: [
                Expanded(child: _dropDown<Station>(
                  label: "ORIGIN",
                  value: _sourceStation,
                  items: _selectedLine!.stations.map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => setState(() => _sourceStation = val),
                )),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Icon(Icons.swap_horiz, color: Colors.blueGrey)),
                Expanded(child: _dropDown<Station>(
                  label: "DESTINATION",
                  value: _destStation,
                  items: _selectedLine!.stations.map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => setState(() => _destStation = val),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropDown<T>({required String label, required T? value, required List<DropdownMenuItem<T>> items, required Function(T?) onChanged}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50, 
            borderRadius: BorderRadius.circular(15), 
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100)
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A), 
                fontWeight: FontWeight.bold, 
                fontSize: 15
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatrixCard(Map<String, dynamic> fares) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: isDark ? Theme.of(context).colorScheme.surfaceContainer : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Commuter Fare Matrix', 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.w900, 
                color: isDark ? Colors.white : const Color(0xFF0D1B3E)
              )
            ),
            const SizedBox(height: 24),
            
            // THE THREE REQUESTED FARE CATEGORIES
            _fareRow('Single Journey Card', 
              fares['isFreeRide'] == 1 ? 'FREE' : '₱${fares['sj_base']?.toStringAsFixed(2)}', 
              fares['isFreeRide'] == 1 ? Colors.green : Colors.orange
            ),
            const Divider(height: 32),

            _fareRow('Beep Card (with 20% discount)', 
              fares['isFreeRide'] == 1 ? 'FREE' : '₱${((fares['sv_base'] ?? 0) * 0.8).toStringAsFixed(2)}', 
              fares['isFreeRide'] == 1 ? Colors.green : Colors.blue
            ),
            const Divider(height: 32),

            _fareRow('Single Journey/White Beep Card (for PWD/Senior Citizen/Student with 50% discount)', 
              fares['isFreeRide'] == 1 ? 'FREE' : '₱${fares['sj50']?.toStringAsFixed(2)}', 
              fares['isFreeRide'] == 1 ? Colors.green : const Color(0xFF1E40AF)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.withOpacity(0.1))
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("WHITE BEEP POLICY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.blue, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                  "White Beep Cards provide the highest discount (50%) for eligible Philippine commuters.", 
                  style: TextStyle(
                    fontSize: 12, 
                    color: isDark ? Colors.blue.shade100 : Colors.blue.shade900, 
                    fontWeight: FontWeight.w500
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _fareRow(String title, String val, Color color) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 14, 
                color: isDark ? Colors.white70 : const Color(0xFF1F2937)
              )
            ),
          ),
          const SizedBox(width: 8),
          Text(
            val, 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)
          ),
        ],
      ),
    );
  }
}
