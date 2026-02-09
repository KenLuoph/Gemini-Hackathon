import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../ui/app_theme.dart';

/// Planner screen with card-based layout and smooth animations
class PlannerScreen extends StatefulWidget {
  final void Function(String intent, {double? budgetLimit, List<String>? preferences, bool? sensitiveToRain}) onGenerate;

  const PlannerScreen({super.key, required this.onGenerate});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> with TickerProviderStateMixin {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sensitiveToRain = false;
  bool _wheelchairAccessible = false;
  int _budget = 200;
  final List<String> _preferences = [];

  // Scroll position for parallax effect
  double _scrollOffset = 0;

  static const _prefOptions = ['Food', 'Art', 'Nature', 'Nightlife', 'Shopping'];

  @override
  void initState() {
    super.initState();
    
    // Listen to scroll for parallax
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomNavHeight = 80.0;
    final availableHeight = screenHeight - MediaQuery.of(context).padding.top - bottomNavHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        bottom: false, // Allow content to extend behind bottom nav
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: availableHeight,
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120), // Extra bottom padding
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Transform.translate(
                  offset: Offset(0, -_scrollOffset * 0.3),
                  child: _buildMainCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.95, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 40,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero Header
            _buildAnimatedHeader(),

            // Content Area
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // What's the plan label
                  const Text(
                    "What's the plan?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Input field
                  _buildInputField(),

                  const SizedBox(height: 20),

                  // Advanced Options label
                  const Text(
                    'Advanced Options',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Option chips row
                  Row(
                    children: [
                      Expanded(
                        child: _OptionChip(
                          icon: Icons.umbrella,
                          label: 'Rain',
                          subtitle: 'sensitive',
                          selected: _sensitiveToRain,
                          onTap: () => setState(() => _sensitiveToRain = !_sensitiveToRain),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _OptionChip(
                          icon: Icons.accessible,
                          label: 'Wheelchair',
                          subtitle: null,
                          selected: _wheelchairAccessible,
                          onTap: () => setState(() => _wheelchairAccessible = !_wheelchairAccessible),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Generate button
                  _buildGenerateButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Animated icon with rotation
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * math.pi * 2,
                child: Transform.scale(
                  scale: 0.5 + (value * 0.5),
                  child: child,
                ),
              );
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          const Text(
            'Gemini Life\nAssistant',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            'AI-Powered Planning',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Text input
          TextField(
            controller: _inputController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe what you want to do...',
              hintStyle: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
          
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          
          // Quick suggestions with horizontal scroll
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                _QuickChip(
                  icon: '🌹',
                  label: 'Plan a date',
                  onTap: () => setState(() => _inputController.text = 'Plan a romantic date'),
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  icon: '🏖️',
                  label: 'Weekend trip',
                  onTap: () => setState(() => _inputController.text = 'Plan a weekend trip'),
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  icon: '🍽️',
                  label: 'Dinner',
                  onTap: () => setState(() => _inputController.text = 'Plan a dinner'),
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  icon: '🎭',
                  label: 'Show',
                  onTap: () => setState(() => _inputController.text = 'Plan a show'),
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  icon: '🎨',
                  label: 'Museum',
                  onTap: () => setState(() => _inputController.text = 'Visit museums'),
                ),
                const SizedBox(width: 8),
                // Mic button
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.mic, size: 16),
                    color: const Color(0xFF94A3B8),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      tween: Tween(begin: 1.0, end: 1.03),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () {
            final intent = _inputController.text.trim();
            if (intent.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please describe what you want to do'),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppTheme.indigo600,
                ),
              );
              return;
            }
            widget.onGenerate(
              intent,
              budgetLimit: _budget.toDouble(),
              preferences: _preferences.isEmpty ? null : _preferences,
              sensitiveToRain: _sensitiveToRain,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.auto_awesome, size: 20),
              SizedBox(width: 10),
              Text(
                'Generate Smart Plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Widgets

/// Quick suggestion chip with press animation
class _QuickChip extends StatefulWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickChip> createState() => _QuickChipState();
}

class _QuickChipState extends State<_QuickChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isPressed ? const Color(0xFFE2E8F0) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: _isPressed ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Option chip with selection state and animation
class _OptionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_OptionChip> createState() => _OptionChipState();
}

class _OptionChipState extends State<_OptionChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.selected
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                  )
                : null,
            color: widget.selected ? null : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.selected ? Colors.transparent : const Color(0xFFE2E8F0),
              width: widget.selected ? 0 : 1,
            ),
            boxShadow: widget.selected ? [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.selected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                        color: widget.selected ? Colors.white : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.selected 
                              ? Colors.white.withOpacity(0.8) 
                              : const Color(0xFF94A3B8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}