import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'fare_calculator_screen.dart';
import '../widgets/app_drawer.dart';
import '../services/navigation_controller.dart';

import 'news_feed_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = NavigationController().selectedIndex.value;

  @override
  void initState() {
    super.initState();
    NavigationController().selectedIndex.addListener(_onNavigationChanged);
  }

  @override
  void dispose() {
    NavigationController().selectedIndex.removeListener(_onNavigationChanged);
    super.dispose();
  }

  void _onNavigationChanged() {
    if (mounted) {
      setState(() {
        _selectedIndex = NavigationController().selectedIndex.value;
      });
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const NewsFeedScreen(),
  ];

  void _onItemTapped(int index) {
    NavigationController().setTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tara ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const Text('Tren', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.orange)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FareCalculatorScreen()),
              );
            },
          ),
        ],
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0D1B3E),
          elevation: 0,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: 'News',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFFFF6B35), // Brand Orange
          unselectedItemColor: Colors.white60,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
