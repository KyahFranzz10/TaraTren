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
  TrainLine? _fromLine;
  Station? _fromStation;
  TrainLine? _toLine;
  Station? _toStation;
  
  String _userType = 'normal'; // 'normal' or 'student' (Senior included in student logic)
  
  double _distance = 15.0; // km
  double _fuelPrice = 145.0; // PHP/L
  double _fuelEfficiency = 10.0; // km/L
  double _parkingFee = 50.0; // PHP
  double _trainFare = 20.0; // Initial default

  late TextEditingController _distController;
  late TextEditingController _fuelController;
  late TextEditingController _parkingController;

  @override
  void initState() {
    super.initState();
    _distController = TextEditingController(text: _distance.toStringAsFixed(1));
    _fuelController = TextEditingController(text: _fuelPrice.toStringAsFixed(1));
    _parkingController = TextEditingController(text: _parkingFee.toStringAsFixed(0));
    // Use only live lines for comparison defaults
    final liveLines = trainLines.where((l) => ['LRT-1', 'LRT-2', 'MRT-3'].contains(l.name)).toList();
    
    _fromLine = liveLines[0]; // LRT-1
    _toLine = liveLines[0];   // Same line by default
    
    final fromLive = _fromLine!.stations.where((s) => s.isExtension != true).toList();
    final toLive = _toLine!.stations.where((s) => s.isExtension != true).toList();

    _fromStation = fromLive.isNotEmpty ? fromLive.first : null;
    _toStation = toLive.isNotEmpty ? toLive.last : null;
    
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

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Savings Comparison'),
        backgroundColor: isDark ? Colors.black : const Color(0xFF0D1B3E),
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
            // 1. Summary Header
            _summaryHeader(dailySavings),

            // 2. Journey Selection
            _buildJourneySelector(),

            // 3. Comparison
            _buildComparisonCard(totalCarCost),

            // 4. Inputs
            _buildInputSection(),

            // 5. Projections
            _buildProjectionRow(weeklySavings, monthlySavings),

            // 6. Impacts
            _buildImpactSection(co2Saved),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _summaryHeader(double daily) {
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
        children: [
          const Text('DAILY SAVINGS ESTIMATE', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('₱${daily.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statItem(Icons.savings, 'Train vs Car'),
              const SizedBox(width: 30),
              _statItem(Icons.trending_up, 'High Value'),
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

  Widget _buildJourneySelector() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final liveLines = trainLines.where((l) => ['LRT-1', 'LRT-2', 'MRT-3'].contains(l.name)).toList();

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("TRAIN JOURNEY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.blueGrey, letterSpacing: 0.5)),
            const SizedBox(height: 20),
            
            _dropDown<TrainLine>(
              label: "ORIGIN LINE",
              value: _fromLine,
              items: liveLines.map((l) => DropdownMenuItem(value: l, child: Text(l.name))).toList(),
              onChanged: (val) {
                setState(() {
                  _fromLine = val;
                  final liveStations = (val?.stations ?? []).where((s) => s.isExtension != true).toList();
                  _fromStation = liveStations.isNotEmpty ? liveStations.first : null;
                });
                _updateFare();
              },
            ),
            const SizedBox(height: 12),
            _dropDown<Station>(
              label: "ORIGIN STATION",
              value: _fromStation,
              items: (_fromLine?.stations ?? [])
                  .where((s) => s.isExtension != true)
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: (val) { setState(() => _fromStation = val); _updateFare(); },
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1),
            ),

            _dropDown<TrainLine>(
              label: "DESTINATION LINE",
              value: _toLine,
              items: liveLines.map((l) => DropdownMenuItem(value: l, child: Text(l.name))).toList(),
              onChanged: (val) {
                setState(() {
                  _toLine = val;
                  final liveStations = (val?.stations ?? []).where((s) => s.isExtension != true).toList();
                  _toStation = liveStations.isNotEmpty ? liveStations.last : null;
                });
                _updateFare();
              },
            ),
            const SizedBox(height: 12),
            _dropDown<Station>(
              label: "DESTINATION STATION",
              value: _toStation,
              items: (_toLine?.stations ?? [])
                  .where((s) => s.isExtension != true)
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: (val) { setState(() => _toStation = val); _updateFare(); },
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TICKET TYPE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'normal', label: Text('Normal', style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'white_beep', label: Text('Discounted', style: TextStyle(fontSize: 11))),
                  ],
                  selected: {_userType == 'student' ? 'white_beep' : _userType},
                  onSelectionChanged: (val) { 
                    setState(() => _userType = val.first == 'white_beep' ? 'white_beep' : 'normal'); 
                    _updateFare(); 
                  },
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
                    selectedBackgroundColor: Colors.orange,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
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
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200)
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: items.any((item) => item.value == value) ? value : null,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A), 
                fontWeight: FontWeight.bold, 
                fontSize: 16
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCard(double carCost) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double trainRatio = (_trainFare / carCost).clamp(0.05, 1.0);

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('COST PER TRIP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.blueGrey, letterSpacing: 0.5)),
            const SizedBox(height: 24),
            _barItem('Average Car Service', carCost, Colors.redAccent, 1.0),
            const SizedBox(height: 20),
            _barItem('Tara Tren Commute', _trainFare, Colors.green, trainRatio),
          ],
        ),
      ),
    );
  }

  Widget _barItem(String label, double cost, Color color, double ratio) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : const Color(0xFF0F172A))),
            Text('₱${cost.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade100, borderRadius: BorderRadius.circular(5))),
            FractionallySizedBox(
              widthFactor: ratio,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                height: 10,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5), boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 4)]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputSection() {
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("DRIVING VARIABLES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.blueGrey, letterSpacing: 0.5)),
            const SizedBox(height: 16),
            _sliderInput('Driving Distance', _distance, 5, 100, 'km', _distController, (v) => setState(() => _distance = v)),
            const Divider(height: 32),
            _sliderInput('Fuel Rate', _fuelPrice, 50, 200, 'PHP/L', _fuelController, (v) => setState(() => _fuelPrice = v)),
            const Divider(height: 32),
            _sliderInput('Daily Parking', _parkingFee, 0, 300, 'PHP', _parkingController, (v) => setState(() => _parkingFee = v)),
          ],
        ),
      ),
    );
  }

  Widget _sliderInput(String title, double value, double min, double max, String unit, TextEditingController controller, Function(double) onChanged) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 14)),
            Text('${value.toStringAsFixed(1)} $unit', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 14)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: Colors.blue,
          inactiveColor: isDark ? Colors.white10 : Colors.grey.shade100,
          onChanged: (v) {
            onChanged(v);
            controller.text = v.toStringAsFixed(title.contains('Parking') ? 0 : 1);
          },
        ),
      ],
    );
  }

  Widget _buildProjectionRow(double weekly, double monthly) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _projectionBox('WEEKLY', weekly, Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _projectionBox('MONTHLY', monthly, Colors.green)),
        ],
      ),
    );
  }

  Widget _projectionBox(String title, double amount, Color color) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text('₱${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text('IN SAVINGS', style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildImpactSection(double co2) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _impactCard(Icons.eco, "ENVIRONMENTAL IMPACT", "By choosing the train, you prevented ${co2.toStringAsFixed(1)}kg of CO2 today.", Colors.green),
          const SizedBox(height: 12),
          _impactCard(Icons.history, "TIME RECLAIMED", "Skipping Manila traffic saves you ~60-90 minutes daily.", Colors.orange),
        ],
      ),
    );
  }

  Widget _impactCard(IconData icon, String title, String body, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: color.withOpacity(0.1))
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: color, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937), fontWeight: FontWeight.w500)),
          ])),
        ],
      ),
    );
  }

  void _showPromoInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Fare & Promo Info", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 16),
              _promoItem(context, Icons.celebration, "White Beep Benefit", "Seniors, Students, and PWDs enjoy a 50% flat discount on all train lines.", Colors.indigo),
              _promoItem(context, Icons.credit_card, "Stored Value (Beep) Advantage", "Fare calculations automatically prefer Stored Value rates where applicable.", Colors.blue),
              _promoItem(context, Icons.eco, "Eco-Savings", "Public transit is the most efficient way to reduce your carbon footprint in the city.", Colors.green),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.indigo : const Color(0xFF0D1B3E), 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () => Navigator.pop(context), 
                child: const Text("Got it")
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _promoItem(BuildContext context, IconData icon, String title, String desc, Color color) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0D1B3E))),
            Text(desc, style: TextStyle(color: isDark ? Colors.white60 : Colors.blueGrey, fontSize: 13)),
          ])),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _distController.dispose();
    _fuelController.dispose();
    _parkingController.dispose();
    super.dispose();
  }
}
