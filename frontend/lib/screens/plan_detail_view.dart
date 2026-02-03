import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/app_theme.dart';
import '../ui/glass_card.dart';
import '../ui/badge_widget.dart';
import '../models/trip_plan.dart';
import '../models/plan_status.dart';
import '../providers/plan_provider.dart';

/// Full-screen plan detail overlay matching React PlanDetailView
/// Shows plan summary, quality score, agent reasoning, activity timeline,
/// Confirm & Start Monitoring, Monitoring modal, Regenerate modal
class PlanDetailView extends StatefulWidget {
  final TripPlan plan;
  final VoidCallback onClose;
  final bool isDemoMode;
  /// Called after Confirm & Start Monitoring succeeds; then close (e.g. pop and switch to Plans tab).
  final VoidCallback? onConfirmSuccess;

  const PlanDetailView({
    super.key,
    required this.plan,
    required this.onClose,
    this.isDemoMode = false,
    this.onConfirmSuccess,
  });

  @override
  State<PlanDetailView> createState() => _PlanDetailViewState();
}

class _PlanDetailViewState extends State<PlanDetailView> {
  bool _showAgentDetails = false;
  bool _showMonitoring = false;
  bool _showRegenerate = false;
  String? _activeActivityForRegenerate;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final provider = context.watch<PlanProvider>();
    final validation = provider.currentPlan?.planId == plan.planId ? provider.validation : null;
    final score = (validation?.score ?? 0.0) * 100;

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: Stack(
        children: [
          SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                border: const Border(bottom: BorderSide(color: AppTheme.slate200)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.arrow_back, color: AppTheme.slate700),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.slate800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showMonitoring = true),
                          child: Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.emerald50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.monitor_heart, size: 10, color: AppTheme.emerald600),
                                SizedBox(width: 4),
                                Text('Live Monitoring', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.emerald600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert, color: AppTheme.slate700),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.indigo500.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Icon(Icons.auto_awesome, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Quality Score', style: TextStyle(fontSize: 14, color: Color(0xFFC7D2FE), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${score.toInt()}',
                                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const Text(' / 100', style: TextStyle(fontSize: 18, color: Colors.white70)),
                                  const SizedBox(width: 8),
                                  Icon(Icons.info_outline, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text('Activities', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                                      Text('${plan.activityCount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text('Budget', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                                      Text('\$${plan.totalBudget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text('Status', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                                      Text(plan.status.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Agent breakdown
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _showAgentDetails = !_showAgentDetails),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.memory, size: 16, color: AppTheme.indigo500),
                                  const SizedBox(width: 8),
                                  const Text('AI Reasoning Path', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
                                  const Spacer(),
                                  Icon(
                                    _showAgentDetails ? Icons.expand_less : Icons.expand_more,
                                    size: 20,
                                    color: AppTheme.slate400,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_showAgentDetails && plan.reasoningPath != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              color: const Color(0xFFFAF5FF),
                              child: Text(
                                plan.reasoningPath!,
                                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.slate600, height: 1.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Timeline
                    ...plan.mainItinerary.asMap().entries.map((entry) {
                      final index = entry.key;
                      final activity = entry.value;
                      final isLast = index == plan.mainItinerary.length - 1;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [AppTheme.indigo500, AppTheme.slate200],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            activity.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.slate800),
                                          ),
                                        ),
                                        BadgeWidget(color: BadgeColor.gray, child: Text(activity.type.label)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(activity.timeSlot, style: const TextStyle(fontSize: 12, color: AppTheme.slate500)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: AppTheme.indigo600),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            activity.location.address,
                                            style: const TextStyle(fontSize: 14, color: AppTheme.indigo600, decoration: TextDecoration.underline),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (activity.description != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        activity.description!,
                                        style: const TextStyle(fontSize: 14, color: AppTheme.slate600, height: 1.4),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _activeActivityForRegenerate = activity.name;
                                          _showRegenerate = true;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.slate50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.slate100),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.auto_awesome, size: 10, color: AppTheme.purple500),
                                            SizedBox(width: 6),
                                            Text('AI Actions', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.purple500)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Row(
                                      children: [
                                        Icon(Icons.refresh, size: 14, color: AppTheme.slate400),
                                        SizedBox(width: 6),
                                        Text('Regenerate Step', style: TextStyle(fontSize: 14, color: AppTheme.slate700)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                border: const Border(top: BorderSide(color: AppTheme.slate200)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (provider.currentPlan?.planId == plan.planId && plan.status == PlanStatus.verified) {
                        await provider.confirmPlan();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Confirm & Start Monitoring'), backgroundColor: Colors.green),
                        );
                        widget.onConfirmSuccess?.call();
                        widget.onClose();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.indigo600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('✅ Confirm & Start Monitoring', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
          if (_showMonitoring)
            Positioned.fill(
              child: Material(
                color: Colors.black.withValues(alpha: 0.4),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _MonitoringModal(onClose: () => setState(() => _showMonitoring = false)),
                  ),
                ),
              ),
            ),
          if (_showRegenerate)
            Positioned.fill(
              child: Material(
                color: Colors.black.withValues(alpha: 0.4),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _RegenerateModal(
                    activityName: _activeActivityForRegenerate ?? '',
                    onClose: () => setState(() {
                      _showRegenerate = false;
                      _activeActivityForRegenerate = null;
                    }),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonitoringModal extends StatelessWidget {
  final VoidCallback onClose;

  const _MonitoringModal({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate600),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.monitor_heart, size: 18, color: Color(0xFF34D399)),
                    SizedBox(width: 8),
                    Text('Real-Time Monitoring', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF34D399))),
                  ],
                ),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: AppTheme.slate400)),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('System Status', style: TextStyle(fontSize: 14, color: AppTheme.slate400)),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Color(0xFF34D399)),
                    SizedBox(width: 8),
                    Text('Active', style: TextStyle(fontSize: 14, fontFamily: 'monospace', color: Color(0xFF34D399))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Scout Agent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF22D3EE))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.slate600),
              ),
              child: const Text(
                'Polling: 5m interval\nLast check: 30s ago',
                style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.slate400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegenerateModal extends StatelessWidget {
  final String activityName;
  final VoidCallback onClose;

  const _RegenerateModal({required this.activityName, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 48,
              height: 6,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.slate200,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.auto_awesome, size: 20, color: AppTheme.indigo600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Regenerate with AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.slate800)),
                      Text('Optimizing: $activityName', style: const TextStyle(fontSize: 14, color: AppTheme.slate500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('What should change?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate800)),
            const SizedBox(height: 12),
            CheckboxListTile(title: const Text('Find better location'), value: true, onChanged: (_) {}),
            CheckboxListTile(title: const Text('Adjust time slot'), value: true, onChanged: (_) {}),
            CheckboxListTile(title: const Text('Change budget range'), value: false, onChanged: (_) {}),
            CheckboxListTile(title: const Text('Switch indoor/outdoor'), value: false, onChanged: (_) {}),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onClose,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.indigo600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('✨ Regenerate'),
            ),
          ],
        ),
      ),
    );
  }
}
