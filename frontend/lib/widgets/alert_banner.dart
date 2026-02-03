import 'package:flutter/material.dart';

import '../models/alert_signal.dart';
import '../models/alert_severity.dart';

/// Alert banner widget for displaying real-time notifications
/// 
/// Shows at the top of the screen when alerts are received via WebSocket.
class AlertBanner extends StatelessWidget {
  final List<AlertSignal> alerts;
  final void Function(AlertSignal)? onDismiss;

  const AlertBanner({
    super.key,
    required this.alerts,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show most recent critical alert, or latest alert
    final displayAlert = alerts.firstWhere(
      (alert) => alert.severity == AlertSeverity.critical,
      orElse: () => alerts.first,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(
          int.parse('0xff${displayAlert.severity.colorHex.substring(1)}'),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Icon
            Text(
              displayAlert.severity.icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayAlert.changeTypeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayAlert.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Dismiss Button
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => onDismiss!(displayAlert),
              ),
          ],
        ),
      ),
    );
  }
}