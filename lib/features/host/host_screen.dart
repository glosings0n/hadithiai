import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:hadithi_ai/features/features.dart';

import 'widgets/host_bottom_navigation_bar.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _currentIndex == 0
                  ? const HomeScreen(key: ValueKey('home-tab'))
                  : const LibraryScreen(key: ValueKey('library-tab')),
            ),
          ),
          HostBottomNavigationBar(
            currentIndex: _currentIndex,
            onDestinationSelected: (index) {
              if (_currentIndex == index) return;
              setState(() => _currentIndex = index);
            },
            onLiveTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LiveStoryScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
