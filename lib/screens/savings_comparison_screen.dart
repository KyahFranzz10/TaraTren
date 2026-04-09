import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/station.dart';
import '../services/fare_service.dart';

class SavingsComparisonScreen extends StatefulWidget {
  const SavingsComparisonScreen({super.key});

  @override
  State<SavingsComparisonScreen> createState() => _SavingsComparisonScreenState();
}

class _SavingsComparisonScreenState extends State<SavingsComparisonScreen> {
  // --- Inputs ---
  TrainLine? _selectedLine;
  Station? _fromStation;
  Station? _toStation;
  String _userType = 'normal'; // 'normal' or 'student' (Senior included in student logic)
  
  double _distance = 15.0; // km
  double _fuelPrice = 65.0; // PHP/L
  double _fuelEfficiency = 10.0; // km/L
  double _parkingFee = 50.0; // PHP
  double _trainFare = 20.0; // Initial default

  @override
  void initState() {
    super.initState();
    _selectedLine = trainLines[0]; // Default LRT-1
    _fromStation = _selectedLine!.stations.first;
    _toStation = _selectedLine!.stations.last;
    _updateFare();
  }

  void _updateFare() {
    if (_fromStation != null && _toStation != null) {
      final res = FareService().getFareResult(_fromStation!, _toStation!, userType: _userType);
      setState(() {
        _trainFare = (res['sv'] ?? 20.0).toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Calculations ---
    final double fuelCost = (_distance / _fuelEfficiency) * _fuelPrice;
    final double totalCarCost = fuelCost + _parkingFee;
    final double dailySavings = (totalCarCost - _trainFare).clamp(0, double.infinity);
    final double weeklySavings = dailySavings * 5;
    final double monthlySavings = dailySavings * 22;
    
    final double co2Saved = _distance * 0.12;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Savings Comparison'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showPromoInfo(),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Hero Card
            _buildHeroCard(dailySavings),

            // 2. Journey Selection (NEW)
            _buildJourneySelector(),

            // 3. Comparison Chart
            _buildComparisonSection(totalCarCost),

            // 4. Car Inputs (Sliders)
            _buildInputSection(),

            // 5. Projections
            _buildProjectionSection(weeklySavings, monthlySavings),

            // 6. Impact
            _buildImpactSection(co2Saved),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _showPromoInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Fare & Promo Info", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _promoItem(Icons.celebration, "Holy Week / Holiday Promo", "50% Discount for ALL passengers on LRT-2 and MRT-3 today!"),
            _promoItem(Icons.person, "Concessionary Discount", "Students and Seniors receive a further 50% discount on regular rates."),
            _promoItem(Icons.credit_card, "Stored Value (Beep) Advantage", "Calculations assume Stored Value use for maximum savings."),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Got it"))),
          ],
        ),
      ),
    );
  }

  Widget _promoItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ])),
        ],
      ),
    );
  }

  Widget _buildHeroCard(double savings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 32, top: 16, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const Text('DAILY SAVINGS ESTIMATE', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text('₱${savings.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 56, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Based on your selected train route vs. driving', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildJourneySelector() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TRAIN JOURNEY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D1B3E))),
          const SizedBox(height: 16),
          // 1. Train Line (Only Operational Lines)
          _dropDown<TrainLine>(
            label: "Train Line",
            value: _selectedLine,
            items: trainLines
                .where((l) => ['LRT-1', 'LRT-2', 'MRT-3'].contains(l.name))
                .map((l) => DropdownMenuItem(value: l, child: Text(l.name)))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedLine = val;
                _fromStation = val!.stations.isNotEmpty ? val.stations.first : null;
                _toStation = val.stations.isNotEmpty ? val.stations.last : null;
              });
              _updateFare();
            },
          ),
          const SizedBox(height: 16),
          // 2. Stations
          Row(
            children: [
              Expanded(child: _dropDown<Station>(
                label: "From",
                value: _fromStation,
                items: _selectedLine!.stations.map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) { setState(() => _fromStation = val); _updateFare(); },
              )),
              const SizedBox(width: 12),
              Expanded(child: _dropDown<Station>(
                label: "To",
                value: _toStation,
                items: _selectedLine!.stations.map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) { setState(() => _toStation = val); _updateFare(); },
              )),
            ],
          ),
          const SizedBox(height: 16),
          // 3. User Type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Passenger Type", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'normal', label: Text('Normal', style: TextStyle(fontSize: 11))),
                  ButtonSegment(value: 'student', label: Text('20% Off', style: TextStyle(fontSize: 11))),
                ],
                selected: {_userType},
                onSelectionChanged: (val) { setState(() => _userType = val.first); _updateFare(); },
                showSelectedIcon: false,
                style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropDown<T>({required String label, required T? value, required List<DropdownMenuItem<T>> items, required Function(T?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonSection(double carCost) {
    final double trainRatio = _selectedLine == null ? 0.2 : (_trainFare / carCost).clamp(0.05, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cost/Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F2937))),
              _buildFareBadge(),
            ],
          ),
          const SizedBox(height: 20),
          _barItem('Average Car', carCost, Colors.redAccent, 1.0),
          const SizedBox(height: 16),
          _barItem('Tara Tren', _trainFare, Color(_selectedLine?.color ?? 0xFF3F51B5), trainRatio),
        ],
      ),
    );
  }

  Widget _buildFareBadge() {
    bool isPromo = _selectedLine?.name != 'LRT-1';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: isPromo ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPromo ? Icons.bolt : Icons.confirmation_number, size: 14, color: isPromo ? Colors.orange : Colors.blue),
          const SizedBox(width: 4),
          Text(isPromo ? "PROMO RATE" : "REGULAR FARE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isPromo ? Colors.orange : Colors.blue)),
        ],
      ),
    );
  }

  Widget _barItem(String label, double cost, Color color, double ratio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('₱${cost.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w900, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6))),
            FractionallySizedBox(
              widthFactor: ratio,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 12,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CAR TRAVEL INPUTS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          _sliderInput('Est. Driving Distance', _distance, 5, 100, 'km', (v) => setState(() => _distance = v)),
          const Divider(height: 32),
          _sliderInput('Fuel Price (Gasolinera)', _fuelPrice, 50, 90, 'PHP/L', (v) => setState(() => _fuelPrice = v)),
          const Divider(height: 32),
          _sliderInput('Daily Parking Fee', _parkingFee, 0, 300, 'PHP', (v) => setState(() => _parkingFee = v)),
        ],
      ),
    );
  }

  Widget _sliderInput(String title, double value, double min, double max, String unit, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13)),
            Text('${value.toStringAsFixed(1)} $unit', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          ],
        ),
        Slider(value: value, min: min, max: max, activeColor: const Color(0xFF475569), inactiveColor: Color(0xFFE2E8F0), onChanged: onChanged),
      ],
    );
  }

  Widget _buildProjectionSection(double weekly, double monthly) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _projectionCard('WEEKLY SAVINGS', weekly, Icons.calendar_view_week, Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _projectionCard('MONTHLY SAVINGS', monthly, Icons.calendar_month, Colors.green)),
        ],
      ),
    );
  }

  Widget _projectionCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('₱${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildImpactSection(double co2) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _impactTile(Icons.access_time_filled, "RECLAIM YOUR TIME", "Traffic in Manila is heavy. You save ~60-90 mins daily by skipping car jams.", Colors.amber.shade700),
          const SizedBox(height: 12),
          _impactTile(Icons.eco, "ENVIRONMENTAL IMPACT", "By choosing the train, you prevented ${co2.toStringAsFixed(1)}kg of CO2 today.", Colors.green.shade700),
        ],
      ),
    );
  }

  Widget _impactTile(IconData icon, String title, String body, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: color, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(body, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
          ])),
        ],
      ),
    );
  }
}
