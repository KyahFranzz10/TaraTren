import 'package:flutter/material.dart';
import '../services/test_simulation_service.dart';
import '../services/location_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class DeveloperTestScreen extends StatefulWidget {
  const DeveloperTestScreen({super.key});

  @override
  State<DeveloperTestScreen> createState() => _DeveloperTestScreenState();
}

class _DeveloperTestScreenState extends State<DeveloperTestScreen> {
  int _speedMultiplier = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Developer Console (v0.2.1)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader('SIMULATION OVERRIDE'),
          const SizedBox(height: 16),
          _buildLineCard('LRT-1 (Green Line)', Colors.green, 'LRT1'),
          _buildLineCard('LRT-2 (Purple Line)', Colors.purple, 'LRT2'),
          _buildLineCard('MRT-3 (Yellow Line)', Colors.yellow, 'MRT3'),
          
          const SizedBox(height: 24),
          _buildHeader('UI COMPONENT TESTS'),
          const SizedBox(height: 12),
          _buildTestButton(
            'Simulate Arrival Alert',
            Icons.notification_important,
            Colors.orange,
            () {
              LocationService().isArrivalAlert.value = true;
              LocationService().islandBodyText.value = "Arriving at Legarda Station • Doors opening on the right";
            },
          ),
          _buildTestButton(
            'Clear Island Alerts',
            Icons.notifications_off,
            Colors.blueGrey,
            () {
              LocationService().isArrivalAlert.value = false;
              LocationService().islandBodyText.value = null;
            },
          ),
          _buildTestButton(
            'Force Boarding State',
            Icons.directions_subway,
            Colors.indigo,
            () {
              LocationService().isOnboard.value = true;
              LocationService().onboardLine.value = "LRT2";
              LocationService().currentStationOnboard.value = "Recto";
              LocationService().nextStationName.value = "Legarda";
            },
          ),

          const SizedBox(height: 24),
          _buildHeader('SIMULATION SPEED'),
          Card(
            color: Colors.white10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Column(
                children: [
                  Slider(
                    value: _speedMultiplier.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    activeColor: Colors.indigo,
                    label: '${_speedMultiplier}x Speed',
                    onChanged: (val) => setState(() => _speedMultiplier = val.toInt()),
                  ),
                  Text(
                    'Current Speed: ${_speedMultiplier}x Normal',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              TestSimulationService().stopSimulation();
              LocationService().isArrivalAlert.value = false;
              LocationService().islandBodyText.value = null;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All Simulations Terminated')),
              );
            },
            icon: const Icon(Icons.stop_circle),
            label: const Text('EMERGENCY STOP'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.8),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              LocationService().isOnboard.value = false;
              LocationService().onboardLine.value = null;
              LocationService().isArrivalAlert.value = false;
              LocationService().islandBodyText.value = null;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Boarding State Reset')),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              foregroundColor: Colors.white70,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('FORCE UNBOARD & CLEAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTestButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.3)),
          foregroundColor: color,
          minimumSize: const Size(double.infinity, 50),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildLineCard(String name, Color color, String lineCode) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          radius: 12,
          child: Text(
            lineCode[0],
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_fill, color: Colors.indigoAccent),
          onPressed: () => _startSim(lineCode),
        ),
      ),
    );
  }

  Future<void> _startSim(String line) async {
    if (!(await FlutterOverlayWindow.isPermissionGranted())) {
      await FlutterOverlayWindow.requestPermission();
    }
    
    await TestSimulationService().startStationToStationSimulation(line, speedMultiplier: _speedMultiplier);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Simulating $line Trip...'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.indigo,
        ),
      );
    }
  }
}
