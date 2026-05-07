import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final String userId;
  const MainScreen({super.key, required this.userId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(userId: widget.userId),
    SettingsScreen(userId: widget.userId),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.qr_code_2_outlined),
                selectedIcon: Icon(Icons.qr_code_2),
                label: 'QR platby',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Nastavení',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
