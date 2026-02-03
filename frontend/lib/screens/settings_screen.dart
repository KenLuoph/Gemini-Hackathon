import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

/// Settings screen: Demo mode toggle, system info (when demo mode on)
class SettingsScreen extends StatelessWidget {
  final bool isDemoMode;
  final ValueChanged<bool> onDemoModeChanged;

  const SettingsScreen({
    super.key,
    required this.isDemoMode,
    required this.onDemoModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.slate800,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.slate100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.terminal, size: 20, color: AppTheme.indigo600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Demo Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.slate800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Show technical architecture',
                            style: TextStyle(fontSize: 12, color: AppTheme.slate500),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isDemoMode,
                      onChanged: onDemoModeChanged,
                      activeTrackColor: AppTheme.indigo600,
                    ),
                  ],
                ),
              ),
              if (isDemoMode) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.slate100),
                  ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, size: 12, color: AppTheme.slate500),
                            SizedBox(width: 4),
                            Text('System Ver:', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.slate500)),
                            Spacer(),
                            Text('v3.2.0-rc1', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.slate500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Agent Core:', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.slate500)),
                            const Spacer(),
                            Text('Active', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.green.shade600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('WebSocket:', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.slate500)),
                            const Spacer(),
                            Text('Connected', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.green.shade600)),
                          ],
                        ),
                      ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.slate600),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.dns, size: 14, color: AppTheme.slate400),
                          SizedBox(width: 8),
                          Text('System Architecture', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'User Input\n    ↓\nOrchestrator\n    ↓\nScout | Simulator | Validator',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.slate400, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
