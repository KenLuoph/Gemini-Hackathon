import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/app_theme.dart';
import '../ui/glass_card.dart';
import '../ui/badge_widget.dart';
import '../providers/plan_provider.dart';
import '../models/trip_plan.dart';
import '../models/plan_status.dart';

/// Plans list screen: shows displayPlans from PlanProvider (API + mock)
/// Opens PlanDetailScreen when user taps a plan
class PlansScreen extends StatefulWidget {
  final void Function(TripPlan plan) onOpenPlan;

  const PlansScreen({super.key, required this.onOpenPlan});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  String _filter = 'All';
  String _searchTerm = '';

  static const _filters = ['All', 'Active', 'Completed', 'Draft'];

  @override
  Widget build(BuildContext context) {
    return Consumer<PlanProvider>(
      builder: (context, provider, _) {
        var plans = provider.displayPlans;
        if (_filter != 'All') {
          plans = plans.where((p) => p.status.value == _filter.toLowerCase()).toList();
        }
        if (_searchTerm.isNotEmpty) {
          plans = plans.where((p) => p.name.toLowerCase().contains(_searchTerm.toLowerCase())).toList();
        }

        return Scaffold(
          backgroundColor: AppTheme.slate50,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📋 My Plans',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.slate800,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => _StatsSheet(
                                  onClose: () => Navigator.pop(ctx),
                                ),
                              );
                            },
                            icon: const Icon(Icons.bar_chart, size: 20, color: AppTheme.slate600),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.filter_list, size: 20, color: AppTheme.slate600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.slate100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchTerm = v),
                      decoration: InputDecoration(
                        hintText: 'Find a plan...',
                        hintStyle: const TextStyle(color: AppTheme.slate400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.slate400),
                        suffixIcon: _searchTerm.isNotEmpty
                            ? IconButton(
                                onPressed: () => setState(() => _searchTerm = ''),
                                icon: const Icon(Icons.close, size: 16, color: AppTheme.slate400),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Filter chips
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _filters.map((f) {
                        final selected = _filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f + (f == 'Active' ? ' (1)' : '')),
                            selected: selected,
                            onSelected: (_) => setState(() => _filter = f),
                            backgroundColor: Colors.white,
                            selectedColor: AppTheme.indigo500,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : AppTheme.slate600,
                              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: plans.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppTheme.slate100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.assignment, size: 32, color: AppTheme.slate400),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No plans found',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.slate700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters or search term',
                                  style: const TextStyle(fontSize: 14, color: AppTheme.slate500),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _filter = 'All';
                                    _searchTerm = '';
                                  }),
                                  child: const Text('Clear Filters', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.indigo600)),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: plans.length,
                            itemBuilder: (context, index) {
                              final plan = plans[index];
                              final isActive = plan.status == PlanStatus.active;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: IntrinsicHeight(
                                  child: GlassCard(
                                    onTap: () => widget.onOpenPlan(plan),
                                    padding: EdgeInsets.zero,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                      Container(
                                        width: 6,
                                        decoration: BoxDecoration(
                                          color: plan.status == PlanStatus.active
                                              ? Colors.blue
                                              : plan.status == PlanStatus.completed
                                                  ? Colors.green
                                                  : plan.status == PlanStatus.draft
                                                      ? AppTheme.slate200
                                                      : Colors.red,
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      plan.name,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 18,
                                                        color: AppTheme.slate800,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isActive)
                                                    Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.blue.withValues(alpha: 0.5),
                                                            blurRadius: 4,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today, size: 14, color: AppTheme.slate500),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    plan.createdAt != null
                                                        ? '${plan.createdAt!.month}/${plan.createdAt!.day}'
                                                        : '—',
                                                    style: const TextStyle(fontSize: 14, color: AppTheme.slate500),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  const Icon(Icons.access_time, size: 14, color: AppTheme.slate500),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${plan.activityCount} activities',
                                                    style: const TextStyle(fontSize: 14, color: AppTheme.slate500),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  BadgeWidget(
                                                    color: isActive ? BadgeColor.blue : BadgeColor.gray,
                                                    child: Text('\$${plan.totalBudget.toStringAsFixed(0)}'),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (provider.currentPlan?.planId == plan.planId && provider.validation != null)
                                                    Text(
                                                      'Score: ${(provider.validation!.score * 100).toInt()}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.indigo600,
                                                      ),
                                                    ),
                                                  const Spacer(),
                                                  IconButton(
                                                    onPressed: () {},
                                                    icon: const Icon(Icons.more_vert, size: 16, color: AppTheme.slate400),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatsSheet extends StatelessWidget {
  final VoidCallback onClose;

  const _StatsSheet({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.slate50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📊 Your Stats', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.slate800)),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.slate100),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plans', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                        SizedBox(height: 4),
                        Text('12', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.slate800)),
                        SizedBox(height: 4),
                        Text('↑ 2 this week', style: TextStyle(fontSize: 12, color: Colors.green)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.slate100),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Spent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                        SizedBox(height: 4),
                        Text('\$1.2k', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.slate800)),
                        SizedBox(height: 4),
                        Text('Avg \$100/plan', style: TextStyle(fontSize: 12, color: AppTheme.slate400)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
