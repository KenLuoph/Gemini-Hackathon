import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'ui/app_theme.dart';
import 'providers/plan_provider.dart';
import 'models/trip_plan.dart';
import 'screens/notes_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/plans_screen.dart';
import 'screens/plan_detail_view.dart';
import 'screens/loading_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 2; // Default to Planner
  TripPlan? _selectedPlan;
  bool _isDemoMode = false;
  ({String title, String msg, String type, String? source})? _notification;

  @override
  void initState() {
    super.initState();
    // Simulate a background alert update after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _notification = (
            title: 'Plan Auto-Updated',
            msg: 'Rain detected. Outdoor Concert → Jazz Club.',
            type: 'warning',
            source: 'Scout Agent',
          );
        });
      }
    });
  }

  void _onGeneratePlan(String intent, {double? budgetLimit, List<String>? preferences, bool? sensitiveToRain}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingScreen(
          intent: intent,
          budgetLimit: budgetLimit,
          preferences: preferences,
          sensitiveToRain: sensitiveToRain,
          onConfirmThenGoToPlans: () => setState(() => _currentIndex = 3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              const NotesScreen(),
              const CalendarScreen(),
              PlannerScreen(
                onGenerate: (intent, {budgetLimit, preferences, sensitiveToRain}) {
                  _onGeneratePlan(intent, budgetLimit: budgetLimit, preferences: preferences, sensitiveToRain: sensitiveToRain);
                },
              ),
              PlansScreen(onOpenPlan: (plan) => setState(() => _selectedPlan = plan)),
              SettingsScreen(
                isDemoMode: _isDemoMode,
                onDemoModeChanged: (v) => setState(() => _isDemoMode = v),
              ),
            ],
          ),

          // Demo Mode Indicator
          if (_isDemoMode) _buildDemoBanner(),

          // Notification Alert Overlay
          if (_notification != null) _buildNotificationBanner(),

          // Detail View Overlay
          if (_selectedPlan != null)
            Positioned.fill(
              child: PlanDetailView(
                plan: _selectedPlan!,
                onClose: () => setState(() => _selectedPlan = null),
                isDemoMode: _isDemoMode,
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDemoBanner() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Material(
        color: AppTheme.amber100,
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            child: const Text(
              '🎯 DEMO MODE ACTIVE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.amber800),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBanner() {
    return Positioned(
      top: _isDemoMode ? 36 : 0, left: 0, right: 0,
      child: Material(
        color: _notification!.type == 'warning' ? Colors.amber : Colors.blue,
        elevation: 8,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(_notification!.type == 'warning' ? Icons.warning_amber : Icons.info, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_notification!.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(_notification!.msg, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _notification = null),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 85,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.slate100)),
      ),
      child: Row(
        // Distribute space equally using Expanded to prevent layout overflow
        children: [
          Expanded(child: _NavItem(icon: Icons.edit_note, label: 'Notes', selected: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0))),
          Expanded(child: _NavItem(icon: Icons.calendar_today, label: 'Calendar', selected: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1))),
          
          // Smart Planning FAB Center Space
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -20,
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = 2),
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
                      child: const Icon(Icons.auto_awesome, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(child: _NavItem(icon: Icons.assignment, label: 'Plans', selected: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3))),
          Expanded(child: _NavItem(icon: Icons.settings, label: 'Settings', selected: _currentIndex == 4, onTap: () => setState(() => _currentIndex = 4))),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? AppTheme.indigo600 : AppTheme.slate400),
          Text(label, style: TextStyle(fontSize: 10, color: selected ? AppTheme.indigo600 : AppTheme.slate400)),
        ],
      ),
    );
  }
}