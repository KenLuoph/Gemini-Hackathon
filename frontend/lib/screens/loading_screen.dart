import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/app_theme.dart';
import '../providers/plan_provider.dart';
import 'plan_detail_view.dart';

/// Loading screen with 3-agent phases (Scout, Simulator, Validator)
/// Calls PlanProvider.createPlan and navigates to PlanDetailView on success
class LoadingScreen extends StatefulWidget {
  final String intent;
  final double? budgetLimit;
  final List<String>? preferences;
  final bool? sensitiveToRain;
  /// Called when user confirms plan on detail view; e.g. switch main tab to Plans.
  final VoidCallback? onConfirmThenGoToPlans;

  const LoadingScreen({
    super.key,
    required this.intent,
    this.budgetLimit,
    this.preferences,
    this.sensitiveToRain,
    this.onConfirmThenGoToPlans,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  int _phase = 0; // 0: Scout, 1: Simulator, 2: Validator
  double _progress = 0;
  bool _apiCalled = false;
  Timer? _progressTimer;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startFlow());
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  void _startFlow() async {
    if (_apiCalled) return;
    _apiCalled = true;

    final provider = context.read<PlanProvider>();

    // Phase 0: Scout (2.5s)
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    setState(() => _phase = 1);

    // Animate progress during phase 1
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_progress < 100) _progress += 2;
        if (_progress >= 100) t.cancel();
      });
    });

    // Phase 1: Simulator - call API
    await provider.createPlan(
      intent: widget.intent,
      budgetLimit: widget.budgetLimit,
      preferences: widget.preferences,
      sensitiveToRain: widget.sensitiveToRain,
    );

    _progressTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _phase = 2;
      _progress = 100;
    });

    // Phase 2: Validator (2s)
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;
    if (provider.hasPlan) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PlanDetailView(
            plan: provider.currentPlan!,
            onClose: () => Navigator.pop(context),
            isDemoMode: false,
            onConfirmSuccess: widget.onConfirmThenGoToPlans,
          ),
        ),
      );
    } else if (provider.hasError) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text(provider.errorMessage ?? 'Unknown error'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  static const _phases = [
    (title: 'Data Scout', icon: Icons.visibility, color: Color(0xFF0891B2), details: ['Weather: Clear, 72°F', 'Traffic: Light (3.5/10)', 'Venues: 12 Open']),
    (title: 'Simulator', icon: Icons.casino, color: Color(0xFF9333EA), details: ['Analyzing 100+ venues', 'Optimizing routes', 'Creating alternatives']),
    (title: 'Validator', icon: Icons.balance, color: Color(0xFF059669), details: ['Budget check: OK', 'Constraints: Verified', 'Scoring quality...']),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Spinning orb
              AnimatedBuilder(
                animation: _spinController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _spinController.value * 2 * 3.14159,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: const [
                          Positioned(top: 8, child: Icon(Icons.visibility, size: 16, color: Color(0xFF0891B2))),
                          Positioned(bottom: 12, left: 12, child: Icon(Icons.casino, size: 16, color: Color(0xFF9333EA))),
                          Positioned(bottom: 12, right: 12, child: Icon(Icons.balance, size: 16, color: Color(0xFF059669))),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Orchestrating Plan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.slate800),
              ),
              const SizedBox(height: 8),
              const Text(
                '3-Agent Architecture Active',
                style: TextStyle(fontSize: 14, color: AppTheme.slate500),
              ),
              const SizedBox(height: 32),
              ...List.generate(3, (i) {
                final p = _phases[i];
                final isActive = _phase == i;
                final isDone = _phase > i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? AppTheme.indigo500 : AppTheme.slate200,
                        width: isActive ? 2 : 1,
                      ),
                      boxShadow: isActive
                          ? [BoxShadow(color: AppTheme.indigo500.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.slate100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(p.icon, size: 18, color: p.color),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              p.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.slate700),
                            ),
                            const Spacer(),
                            if (isDone)
                              const Icon(Icons.check, color: Color(0xFF059669), size: 20),
                            if (isActive)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        if (isActive) ...[
                          const SizedBox(height: 12),
                          ...p.details.map((d) => Padding(
                                padding: const EdgeInsets.only(left: 44, bottom: 4),
                                child: Text('• $d', style: const TextStyle(fontSize: 12, color: AppTheme.slate500)),
                              ),),
                          if (i == 1) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 44),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _progress / 100,
                                  minHeight: 6,
                                  backgroundColor: AppTheme.slate100,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9333EA)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
