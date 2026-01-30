import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dumppi/src/features/map/ui/map_screen_v2.dart';
import 'package:dumppi/src/features/resorts/ui/resort_list_screen.dart';
import 'package:dumppi/src/features/resorts/logic/resort_provider.dart';

/// App layout with bottom navigation.
class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const MapScreen(),
          ResortListScreen(
            onResortSelected: (resort) {
              context.read<ResortProvider>().selectResort(resort);
              setState(() => _currentIndex = 0);
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF12121A),
        selectedItemColor: const Color(0xFF0DB9F2),
        unselectedItemColor: Colors.white24,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Resorts',
          ),
        ],
      ),
    );
  }
}
