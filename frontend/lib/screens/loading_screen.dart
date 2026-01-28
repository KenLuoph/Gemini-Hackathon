import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plan_provider.dart';
import 'plan_detail_screen.dart';

/// Loading screen shown while plan is being generated
/// 
/// Displays:
/// - Loading animation
/// - Progress indicator
/// - Automatic navigation on completion
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _listenForCompletion();
  }

  void _listenForCompletion() {
    // Listen for plan generation completion
    final provider = context.read<PlanProvider>();

    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.addListener(_onPlanUpdated);
    });
  }

  void _onPlanUpdated() {
    final provider = context.read<PlanProvider>();

    if (!provider.isLoading) {
      // Remove listener
      provider.removeListener(_onPlanUpdated);

      if (provider.hasPlan) {
        // Success - navigate to detail screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PlanDetailScreen(),
          ),
        );
      } else if (provider.hasError) {
        // Error - show dialog and go back
        _showErrorDialog(provider.errorMessage ?? 'Unknown error');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    final provider = context.read<PlanProvider>();
    provider.removeListener(_onPlanUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generating Plan'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading Indicator
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
              ),
            ),
            const SizedBox(height: 32),

            // Loading Text
            const Text(
              'Creating your perfect trip...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Sub-text
            Text(
              'AI is analyzing your preferences',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Progress Steps
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressStep('Gathering environment data', true),
                  const SizedBox(height: 8),
                  _buildProgressStep('Generating scenarios', true),
                  const SizedBox(height: 8),
                  _buildProgressStep('Validating constraints', true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(String text, bool isActive) {
    return Row(
      children: [
        Icon(
          isActive ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 20,
          color: isActive ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isActive ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }
}