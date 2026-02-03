import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plan_provider.dart';
import '../models/plan_status.dart';
import '../models/validation_result.dart';
import '../widgets/activity_card.dart';
import '../widgets/alert_banner.dart';

/// Plan detail screen
/// 
/// Displays:
/// - Trip plan details
/// - Activity timeline
/// - Validation results
/// - Real-time alerts (via WebSocket)
class PlanDetailScreen extends StatelessWidget {
  const PlanDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Trip Plan'),
        actions: [
          // Clear plan button
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              context.read<PlanProvider>().clearPlan();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Consumer<PlanProvider>(
        builder: (context, provider, child) {
          final plan = provider.currentPlan;
          final validation = provider.validation;

          if (plan == null) {
            return const Center(
              child: Text('No plan available'),
            );
          }

          return Column(
            children: [
              // Alert banner (if any)
              if (provider.hasAlerts)
                AlertBanner(
                  alerts: provider.alerts,
                  onDismiss: (alert) => provider.dismissAlert(alert),
                ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Plan Header
                      _buildPlanHeader(plan),
                      const SizedBox(height: 16),

                      // Validation Score (if available)
                      if (validation != null)
                        _buildValidationCard(validation),

                      const SizedBox(height: 16),

                      // AI Reasoning (if available)
                      if (plan.reasoningPath != null)
                        _buildReasoningCard(plan.reasoningPath!),

                      const SizedBox(height: 24),

                      // Activities Section
                      const Text(
                        'Itinerary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Activity List
                      ...plan.mainItinerary.map((activity) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ActivityCard(activity: activity),
                        );
                      }),

                      // Alternatives Section
                      if (plan.hasAlternatives) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Backup Options',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...plan.alternatives.map((activity) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ActivityCard(
                              activity: activity,
                              isAlternative: true,
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button
              if (plan.status == PlanStatus.verified)
                _buildConfirmButton(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlanHeader(plan) {
    return Card(
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
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(plan.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${plan.activityCount} activities',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '\$${plan.totalBudget.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(PlanStatus status) {
    return Chip(
      label: Text(
        status.label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Color(
        int.parse('0xff${status.colorHex.substring(1)}'),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildValidationCard(ValidationResult validation) {
    return Card(
      color: validation.isValid ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  validation.isValid ? Icons.check_circle : Icons.warning,
                  color: validation.isValid ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  validation.isValid ? 'Validation Passed' : 'Validation Issues',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(validation.score * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Star Rating
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < validation.starRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),

            // Violations
            if (validation.violations.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                '❌ Issues:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...validation.violations.map((v) => Padding(
                    padding: const EdgeInsets.only(top: 4, left: 16),
                    child: Text('• $v'),
                  ),),
            ],

            // Warnings
            if (validation.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                '⚠️ Warnings:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...validation.warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(top: 4, left: 16),
                    child: Text(
                      '• $w',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReasoningCard(String reasoning) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.psychology),
        title: const Text('AI Decision Explanation'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              reasoning,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, PlanProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: FilledButton.icon(
          onPressed: () async {
            await provider.confirmPlan();
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Plan activated! Monitoring started.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          icon: const Icon(Icons.check_circle),
          label: const Text(
            'Confirm Plan',
            style: TextStyle(fontSize: 16),
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }
}