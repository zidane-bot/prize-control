import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingScreenV2 extends StatefulWidget {
  final String message;
  final VoidCallback? onComplete;
  
  const LoadingScreenV2({
    super.key, 
    this.message = "Memproses Data...",
    this.onComplete,
  });

  @override
  State<LoadingScreenV2> createState() => _LoadingScreenV2State();
}

class _LoadingScreenV2State extends State<LoadingScreenV2> with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _rotateController;
  
  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Auto complete after 6 seconds to match AuthWrapper logic
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Geometric Background (Tech Theme)
          ...List.generate(3, (index) => _buildCircle(index, colorScheme)),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular Scanning Animation
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Rotating Ring
                    RotationTransition(
                      turns: _rotateController,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              left: 80,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Inner Pulse Logo
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withValues(alpha: 0.05),
                      ),
                      child: Icon(
                        Icons.biotech_rounded,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                    ),

                    // Scanning Line
                    AnimatedBuilder(
                      animation: _scanController,
                      builder: (context, child) {
                        return Positioned(
                          top: 40 + (_scanController.value * 100),
                          child: Container(
                            width: 120,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary.withValues(alpha: 0),
                                  colorScheme.primary,
                                  colorScheme.primary.withValues(alpha: 0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 60),
                
                // Text Feedback
                Text(
                  "BIO-ANALYSIS",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.message.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 48),

                // Percentage Indicator
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 6),
                  builder: (context, value, child) {
                    return Column(
                      children: [
                        SizedBox(
                          width: 250,
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 2,
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.05),
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "ESTIMATING: ${(value * 100).toInt()}%",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Technical Overlay
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "PRECISION DATA SYNC",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(int index, ColorScheme colorScheme) {
    return Positioned(
      top: index == 0 ? -100 : (index == 1 ? 500 : 200),
      left: index == 0 ? -100 : (index == 1 ? 250 : -50),
      child: Opacity(
        opacity: 0.03,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
