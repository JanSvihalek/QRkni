import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final String userId;
  final bool isWorkerMode;

  const MainScreen({
    super.key,
    required this.userId,
    this.isWorkerMode = false,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(userId: widget.userId, isWorkerMode: widget.isWorkerMode),
    if (!widget.isWorkerMode) SettingsScreen(userId: widget.userId),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.white.withValues(alpha: 0.85),
                  selectedIndex: _currentIndex,
                  height: 70,
                  onDestinationSelected: (i) =>
                      setState(() => _currentIndex = i),
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.qr_code_2_outlined),
                      selectedIcon: Icon(Icons.qr_code_2),
                      label: 'QR platby',
                    ),
                    if (!widget.isWorkerMode)
                      const NavigationDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: 'Nastavení',
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
