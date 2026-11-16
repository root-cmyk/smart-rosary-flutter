
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/home_screen.dart';
import '../screens/learn_screen.dart';
import '../screens/pray_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/kids_mode_screen.dart';
import '../widgets/liquid_navigation_bar.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  static const String _kidsModeKey = 'kids_mode_enabled';

  int currentIndex = 0;
  bool kidsModeEnabled = false;
  bool preferencesLoaded = false;

  // The selected child belonging to the signed-in parent.
  String? selectedChildParentUid;
  String? selectedChildProfileId;

  static const adultDestinations = [
    RosaryDestination(Icons.home_rounded, 'Home'),
    RosaryDestination(Icons.auto_stories_rounded, 'Learn'),
    RosaryDestination(Icons.favorite_rounded, 'Pray'),
    RosaryDestination(Icons.insights_rounded, 'Progress'),
    RosaryDestination(Icons.person_rounded, 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _loadKidsMode();
  }

  Future<void> _loadKidsMode() async {
    final preferences = await SharedPreferences.getInstance();

    if (!mounted) return;

    // Do not automatically reopen a parent's Kids Mode without
    // knowing which child was selected.
    final savedKidsMode = preferences.getBool(_kidsModeKey) ?? false;

    setState(() {
      kidsModeEnabled = false;
      preferencesLoaded = true;
    });

    if (savedKidsMode) {
      await preferences.setBool(_kidsModeKey, false);
    }
  }

  Future<void> _setKidsMode(bool enabled) async {
    if (enabled) {
      // A parent must select a child before entering Kids Mode.
      if (selectedChildParentUid == null ||
          selectedChildProfileId == null) {
        return;
      }
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_kidsModeKey, enabled);

    if (!mounted) return;

    setState(() {
      kidsModeEnabled = enabled;
      currentIndex = 0;

      if (!enabled) {
        selectedChildParentUid = null;
        selectedChildProfileId = null;
      }
    });
  }

  // Called by ProfileScreen after the parent selects a child.
  Future<void> _enterKidsModeForChild(String childProfileId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    selectedChildParentUid = user.uid;
    selectedChildProfileId = childProfileId;

    await _setKidsMode(true);
  }

  void _navigateToTab(int index) {
    if (index < 0 || index >= adultDestinations.length) return;

    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!preferencesLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (kidsModeEnabled) {
      return KidsModeScreen(
        onExitKidsMode: () => _setKidsMode(false),
        parentUid: selectedChildParentUid,
        childProfileId: selectedChildProfileId,
      );
    }

    final screens = <Widget>[
      HomeScreen(onNavigate: _navigateToTab),
      const LearnScreen(),
      const PrayScreen(),
      const ProgressScreen(),
      ProfileScreen(
        kidsModeEnabled: kidsModeEnabled,
        onKidsModeChanged: _setKidsMode,
        onChildSelected: _enterKidsModeForChild,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: LiquidNavigationBar(
        currentIndex: currentIndex,
        destinations: adultDestinations,
        onChanged: _navigateToTab,
      ),
    );
  }
}
