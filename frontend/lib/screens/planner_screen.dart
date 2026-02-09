import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../ui/app_theme.dart';

/// Planner screen with smooth animations and elastic scrolling
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(), // ✅ iOS 风格弹性滚动
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Main Card with parallax effect
                          Transform.translate(
                            offset: Offset(0, -_scrollOffset * 0.3), // ✅ 视差效果
                            child: _buildMainCard(),
                          ),
                          
                          const SizedBox(height: 80), // ✅ 底部留白，增强滚动感
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.95, end: 1.0),
      curve: Curves.easeOutBack, // ✅ 回弹曲线
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "What's the plan?"
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

                  const SizedBox(height: 24),

                  // Advanced Options
                  const Text(
                    'Advanced Options',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Option chips
                  Row(
                    children: [
                      Expanded(
                        child: _OptionChip(
                          icon: Icons.umbrella,
                          label: 'Rain sensitive',
                          selected: _sensitiveToRain,
                          onTap: () => setState(() => _sensitiveToRain = !_sensitiveToRain),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _OptionChip(
                          icon: Icons.accessible,
                          label: 'Wheelchair',
                          selected: _wheelchairAccessible,
                          onTap: () => setState(() => _wheelchairAccessible = !_wheelchairAccessible),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

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
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
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
            curve: Curves.elasticOut, // ✅ 弹性动画
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * math.pi * 2, // 旋转一圈
                child: Transform.scale(
                  scale: 0.5 + (value * 0.5), // 从小到大
                  child: child,
                ),
              );
            },
            child: Container(
              width: 80,
              height: 80,
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
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          const Text(
            'Gemini Life Assistant',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            'AI-Powered Planning',
            style: TextStyle(
              fontSize: 16,
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
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '✨ Describe what you want to do...',
              hintStyle: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
          
          // ✅ 可横向滚动的 Quick suggestions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
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
                  label: 'Night out',
                  onTap: () => setState(() => _inputController.text = 'Plan a night out'),
                ),
                const SizedBox(width: 8),
                // Mic button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.mic, size: 18),
                    color: const Color(0xFF94A3B8),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                  ),
                ),
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
      tween: Tween(begin: 1.0, end: 1.05),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      onEnd: () {
        // Restart animation
        if (mounted) {
          setState(() {});
        }
      },
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            final intent = _inputController.text.trim();
            if (intent.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please describe what you want to do'),
                  behavior: SnackBarBehavior.floating,
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
            elevation: 4,
            shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.auto_awesome, size: 20),
              SizedBox(width: 8),
              Text(
                'Generate Smart Plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Helper Widgets ====================

/// Quick suggestion chip
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

/// Option chip (Rain sensitive, Wheelchair)
class _OptionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.icon,
    required this.label,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.selected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
                    color: widget.selected ? Colors.white : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}