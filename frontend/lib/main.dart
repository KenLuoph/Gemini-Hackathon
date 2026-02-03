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

/// Main shell: bottom nav (Notes, Calendar, Planner FAB, Plans, Settings),
/// notification banner, demo mode banner, plan detail overlay
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 2; // Planner is center (index 2)
  TripPlan? _selectedPlan;
  bool _isDemoMode = false;
  ({String title, String msg, String type, String? source})? _notification;

  @override
  void initState() {
    super.initState();
    // Simulate notification after 8s (matching React)
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

  void _onOpenPlan(TripPlan plan) {
    setState(() => _selectedPlan = plan);
  }

  void _onClosePlanDetail() {
    setState(() => _selectedPlan = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: Stack(
        children: [
          // Content
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
              PlansScreen(onOpenPlan: _onOpenPlan),
              SettingsScreen(
                isDemoMode: _isDemoMode,
                onDemoModeChanged: (v) => setState(() => _isDemoMode = v),
              ),
            ],
          ),

          // Demo mode banner
          if (_isDemoMode)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: AppTheme.amber100,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Center(
                      child: Text(
                        '🎯 DEMO MODE ACTIVE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.amber800),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Notification banner
          if (_notification != null)
            Positioned(
              top: _isDemoMode ? 36 : 0,
              left: 0,
              right: 0,
              child: Material(
                color: _notification!.type == 'warning' ? Colors.amber : Colors.blue,
                elevation: 4,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _notification!.type == 'warning' ? Icons.warning_amber : Icons.info,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _notification!.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              if (_notification!.source != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Triggered by: ${_notification!.source}',
                                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                _notification!.msg,
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _notification = null),
                          icon: const Icon(Icons.close, size: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Plan detail overlay
          if (_selectedPlan != null)
            Positioned.fill(
              child: PlanDetailView(
                plan: _selectedPlan!,
                onClose: _onClosePlanDetail,
                isDemoMode: _isDemoMode,
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80,
        padding: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.slate100)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.edit_note,
              label: 'Notes',
              selected: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            _NavItem(
              icon: Icons.calendar_today,
              label: 'Calendar',
              selected: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            // Center FAB
            const SizedBox(width: 64),
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 2),
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.indigo500.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, size: 28, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 64),
            _NavItem(
              icon: Icons.assignment,
              label: 'Plans',
              selected: _currentIndex == 3,
              onTap: () => setState(() => _currentIndex = 3),
            ),
            _NavItem(
              icon: Icons.settings,
              label: 'Settings',
              selected: _currentIndex == 4,
              onTap: () => setState(() => _currentIndex = 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? AppTheme.indigo600 : AppTheme.slate400,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppTheme.indigo600 : AppTheme.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
