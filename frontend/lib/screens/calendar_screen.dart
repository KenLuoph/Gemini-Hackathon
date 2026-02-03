import 'package:flutter/material.dart';
import '../ui/app_theme.dart';
import '../ui/badge_widget.dart';

final _weekDays = [
  {'day': 'Mon', 'date': '27', 'active': false},
  {'day': 'Tue', 'date': '28', 'active': false},
  {'day': 'Wed', 'date': '29', 'active': false},
  {'day': 'Thu', 'date': '30', 'active': false},
  {'day': 'Fri', 'date': '31', 'active': true},
  {'day': 'Sat', 'date': '1', 'active': false},
  {'day': 'Sun', 'date': '2', 'active': false},
];

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _viewMode = 'day'; // day | week | month
  String? _selectedEventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: Stack(
        children: [
          SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.chevron_left, size: 20),
                      ),
                      const Text(
                        'January 2026',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.slate800,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.chevron_right, size: 20),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.indigo600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // View toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.slate100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: ['Day', 'Week', 'Month'].map((m) {
                    final isSelected = _viewMode == m.toLowerCase();
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _viewMode = m.toLowerCase()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: isSelected
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
                                : null,
                          ),
                          child: Text(
                            m,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.indigo600 : AppTheme.slate500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Week strip
              SizedBox(
                height: 88,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _weekDays.length,
                  itemBuilder: (context, i) {
                    final d = _weekDays[i];
                    final active = d['active'] as bool;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 48,
                        decoration: BoxDecoration(
                          gradient: active ? AppTheme.primaryGradient : null,
                          color: active ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: active
                              ? [BoxShadow(color: AppTheme.indigo500.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              d['day'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: active ? Colors.white : AppTheme.slate400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d['date'] as String,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: active ? Colors.white : AppTheme.slate400,
                              ),
                            ),
                            if (active) const SizedBox(height: 4),
                            if (active)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Timeline
              Expanded(
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time markers
                      SizedBox(
                        width: 48,
                        child: Column(
                          children: ['09:00', '12:00', '15:00', '18:00']
                              .map((t) => Padding(
                                    padding: const EdgeInsets.only(bottom: 80),
                                    child: Text(
                                      t,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.slate400,
                                      ),
                                    ),
                                  ),)
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            // Work block
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.slate100,
                                borderRadius: BorderRadius.circular(16),
                                border: const Border(
                                  left: BorderSide(color: AppTheme.slate200, width: 4),
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('09:00 - 17:00', style: TextStyle(fontSize: 12, color: AppTheme.slate500)),
                                  SizedBox(height: 4),
                                  Text('Work', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.slate700)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // AI Plan block
                            GestureDetector(
                              onTap: () => setState(() => _selectedEventId = 'e1'),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      AppTheme.indigo500.withValues(alpha: 0.1),
                                      AppTheme.purple500.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: const Border(
                                    left: BorderSide(color: AppTheme.indigo500, width: 4),
                                  ),
                                ),
                                child: Stack(
                                  children: const [
                                    const Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Icon(Icons.auto_awesome, size: 14, color: AppTheme.indigo600),
                                    ),
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('18:00 - 22:00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.indigo600)),
                                          SizedBox(height: 4),
                                          Text('SF Art & Food Evening', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.slate800)),
                                          SizedBox(height: 8),
                                          Row(children: [
                                            Icon(Icons.location_on, size: 12, color: AppTheme.slate500),
                                            SizedBox(width: 4),
                                            Text('San Francisco, CA', style: TextStyle(fontSize: 12, color: AppTheme.slate500)),
                                          ],),
                                          SizedBox(height: 8),
                                          Row(children: [
                                            BadgeWidget(color: BadgeColor.green, child: Text('\$180')),
                                            SizedBox(width: 8),
                                            SizedBox(
                                              width: 8,
                                              height: 8,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: AppTheme.indigo500,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ],),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
          if (_selectedEventId != null)
            Positioned.fill(
              child: Material(
                color: Colors.black.withValues(alpha: 0.2),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedEventId = null),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: _EventPopup(
                        onClose: () => setState(() => _selectedEventId = null),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventPopup extends StatelessWidget {
  final VoidCallback onClose;

  const _EventPopup({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.075),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SF Art & Food Evening', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.slate800)),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: AppTheme.slate400)),
              ],
            ),
            const SizedBox(height: 12),
            const Row(children: [Icon(Icons.access_time, size: 16, color: AppTheme.indigo500), SizedBox(width: 8), Text('18:00 - 22:00', style: TextStyle(fontSize: 14, color: AppTheme.slate600))]),
            const Row(children: [Icon(Icons.location_on, size: 16, color: AppTheme.indigo500), SizedBox(width: 8), Text('San Francisco, CA', style: TextStyle(fontSize: 14, color: AppTheme.slate600))]),
            const Row(children: [Icon(Icons.attach_money, size: 16, color: AppTheme.indigo500), SizedBox(width: 8), Text('\$180 • Active', style: TextStyle(fontSize: 14, color: AppTheme.slate600))]),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Full Details'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
