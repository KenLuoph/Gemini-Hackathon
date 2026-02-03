import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

/// Planner screen: hero, input, advanced options, Generate Smart Plan
/// Calls backend POST /plan/generate on "Generate Smart Plan"
class PlannerScreen extends StatefulWidget {
  /// Called when user taps Generate Smart Plan. Passes intent, budget, preferences.
  final void Function(String intent, {double? budgetLimit, List<String>? preferences, bool? sensitiveToRain}) onGenerate;

  const PlannerScreen({super.key, required this.onGenerate});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _inputController = TextEditingController();
  bool _showAdvanced = false;
  int _budget = 200;
  final List<String> _preferences = [];

  static const _prefOptions = ['Food', 'Art', 'Nature', 'Nightlife', 'Shopping'];

  void _togglePref(String p) {
    setState(() {
      if (_preferences.contains(p)) {
        _preferences.remove(p);
      } else {
        _preferences.add(p);
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: Stack(
        children: [
          Column(
            children: [
              // Hero
              Container(
                height: MediaQuery.of(context).size.height * 0.40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.indigo500, AppTheme.purple600],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome, size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Gemini Life Assistant',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI-Powered Planning',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content card (use Transform.translate instead of negative margin)
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -32),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                    decoration: const BoxDecoration(
                      color: AppTheme.slate50,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "What's the plan?",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.slate700,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _inputController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: '✨ Describe what you want to do...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Row(
                                children: [
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.mic, size: 18, color: AppTheme.slate500),
                                  ),
                                ],
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: ['📅 Plan a date', '🏖️ Weekend trip', '🍽️ Dinner']
                                      .map((tag) => Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: TextButton(
                                              onPressed: () => _inputController.text = tag,
                                              child: Text(
                                                tag,
                                                style: const TextStyle(fontSize: 12, color: AppTheme.slate600),
                                              ),
                                            ),
                                          ),)
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Advanced Options',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.slate700,
                                ),
                              ),
                              Icon(
                                _showAdvanced ? Icons.expand_less : Icons.expand_more,
                                size: 20,
                                color: AppTheme.slate400,
                              ),
                            ],
                          ),
                        ),
                        if (_showAdvanced) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.slate100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Budget Limit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate500)),
                                    Text('\$$_budget', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.indigo600)),
                                  ],
                                ),
                                Slider(
                                  value: _budget.toDouble(),
                                  min: 0,
                                  max: 1000,
                                  divisions: 100,
                                  activeColor: AppTheme.indigo600,
                                  onChanged: (v) => setState(() => _budget = v.toInt()),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _prefOptions.map((p) {
                              final selected = _preferences.contains(p);
                              return GestureDetector(
                                onTap: () => _togglePref(p),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: selected ? AppTheme.primaryGradientHorizontal : null,
                                    color: selected ? null : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: selected ? Colors.transparent : AppTheme.slate200,
                                    ),
                                  ),
                                  child: Text(
                                    p,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: selected ? Colors.white : AppTheme.slate600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            final intent = _inputController.text.trim();
                            if (intent.isEmpty) return;
                            widget.onGenerate(
                              intent,
                              budgetLimit: _budget.toDouble(),
                              preferences: _preferences.isEmpty ? null : _preferences,
                              sensitiveToRain: null,
                            );
                          },
                          icon: const Icon(Icons.auto_awesome, size: 20),
                          label: const Text('Generate Smart Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.indigo600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
