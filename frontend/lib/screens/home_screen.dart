import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plan_provider.dart';
import '../config/app_config.dart';
import 'loading_screen.dart';

/// Home screen for user input
/// 
/// Allows users to:
/// - Enter trip planning intent
/// - Set budget and preferences
/// - Configure constraints
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _intentController = TextEditingController();
  final _budgetController = TextEditingController(text: '200');

  // Preferences
  bool _sensitiveToRain = false;
  final Set<String> _selectedPreferences = {};
  final Set<String> _dietaryRestrictions = {};

  // Available options
  final List<String> _availablePreferences = [
    'food',
    'art',
    'nature',
    'shopping',
    'nightlife',
    'culture',
    'sports',
    'relaxation',
  ];

  final List<String> _availableDietary = [
    'vegan',
    'vegetarian',
    'halal',
    'kosher',
    'gluten_free',
  ];

  @override
  void dispose() {
    _intentController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _submitPlan() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<PlanProvider>();

    // Parse budget
    final budget = double.tryParse(_budgetController.text);

    // Navigate to loading screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoadingScreen(),
      ),
    );

    // Create plan
    provider.createPlan(
      intent: _intentController.text,
      budgetLimit: budget,
      preferences: _selectedPreferences.toList(),
      sensitiveToRain: _sensitiveToRain,
      dietaryRestrictions: _dietaryRestrictions.isNotEmpty
          ? _dietaryRestrictions.toList()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✨ Gemini Life Planner'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Text(
                  'Plan Your Perfect Trip',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Powered by Google Gemini AI',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Intent Input
                TextFormField(
                  controller: _intentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'What do you want to do?',
                    hintText: 'e.g., Plan a romantic date in San Francisco this Friday evening',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lightbulb_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please describe your trip plan';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Budget Input
                TextFormField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Budget (USD)',
                    hintText: '200',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your budget';
                    }
                    final budget = double.tryParse(value);
                    if (budget == null || budget <= 0) {
                      return 'Please enter a valid budget';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Preferences Section
                const Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Preference Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availablePreferences.map((pref) {
                    final isSelected = _selectedPreferences.contains(pref);
                    return FilterChip(
                      label: Text(pref),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPreferences.add(pref);
                          } else {
                            _selectedPreferences.remove(pref);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Rain Sensitivity Switch
                SwitchListTile(
                  title: const Text('Sensitive to Rain'),
                  subtitle: const Text(
                    'Prioritize indoor activities even in good weather',
                  ),
                  value: _sensitiveToRain,
                  onChanged: (value) {
                    setState(() {
                      _sensitiveToRain = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Dietary Restrictions
                const Text(
                  'Dietary Restrictions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableDietary.map((diet) {
                    final isSelected = _dietaryRestrictions.contains(diet);
                    return FilterChip(
                      label: Text(diet),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _dietaryRestrictions.add(diet);
                          } else {
                            _dietaryRestrictions.remove(diet);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Submit Button
                FilledButton.icon(
                  onPressed: _submitPlan,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'Generate Plan',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),

                // Backend Info
                Center(
                  child: Text(
                    'Backend: ${AppConfig.baseUrl}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}