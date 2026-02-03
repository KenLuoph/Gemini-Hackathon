import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/activity_item.dart';

/// Reusable activity card widget
/// 
/// Displays activity information in a card format with:
/// - Activity name and description
/// - Time slot
/// - Location with map link
/// - Budget breakdown
/// - Risk indicator
class ActivityCard extends StatelessWidget {
  final ActivityItem activity;
  final bool isAlternative;

  const ActivityCard({
    super.key,
    required this.activity,
    this.isAlternative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isAlternative ? 1 : 2,
      color: isAlternative ? Colors.grey[100] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Type Icon
                Text(
                  activity.type.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),

                // Activity Name
                Expanded(
                  child: Text(
                    activity.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Risk Indicator
                if (activity.riskScore > 0.6)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse('0xff${activity.riskColorHex.substring(1)}'),
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 14,
                          color: Color(
                            int.parse('0xff${activity.riskColorHex.substring(1)}'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity.riskLevel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(
                              int.parse('0xff${activity.riskColorHex.substring(1)}'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Time Slot
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  activity.timeSlot,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Location
            InkWell(
              onTap: () => _openMap(activity.location.googleMapsUrl),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity.location.address,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Icon(Icons.open_in_new, size: 14, color: Colors.blue),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Budget
            Row(
              children: [
                const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  activity.budget.formatted,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  activity.budget.categoryLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            // Description
            if (activity.description != null) ...[
              const SizedBox(height: 12),
              Text(
                activity.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
            ],

            // Constraints
            if (activity.constraints != null &&
                activity.constraints!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: activity.constraints!.entries.map((entry) {
                  return Chip(
                    label: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],

            // Alternative badge
            if (isAlternative)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Backup Option',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

