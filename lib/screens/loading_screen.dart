import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class LoadingScreen extends StatefulWidget {
  final String message;
  const LoadingScreen({super.key, this.message = "Menginisialisasi Sistem..."});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _leafController;
  late Animation<double> _pulseAnimation;
  
  final List<String> _loadingMessages = [
    "Menyiapkan Sensor...",
    "Menganalisa Hak Akses...",
    "Menghubungkan ke Cloud...",
    "Sinkronisasi Data Tanaman...",
    "Hampir Selesai..."
  ];
  
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _leafController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startMessageCycle();
  }

  void _startMessageCycle() async {
    for (int i = 0; i < _loadingMessages.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 1800));
      setState(() {
        _currentMessageIndex = (i + 1) % _loadingMessages.length;
      });
    }
  }


  @override
  void dispose() {
    _pulseController.dispose();
    _leafController.dispose();
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
          // Floating Leaves Background
          ...List.generate(6, (index) => _buildFloatingLeaf(index, colorScheme)),

          // Bottom Wave Decoration (Inspired by user image)
          Positioned(
            bottom: -20,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.waves_rounded, size: 400, color: colorScheme.primary),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Plant Growth Animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 5),
                  builder: (context, value, child) {
                    IconData plantIcon;
                    if (value < 0.3) {
                      plantIcon = Icons.radio_button_unchecked_rounded; // Seed
                    } else if (value < 0.6) {
                      plantIcon = Icons.spa_rounded; // Sprout
                    } else {
                      plantIcon = Icons.eco_rounded; // Full leaf
                    }

                    return ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Icon(
                          plantIcon,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Title Section
                Text(
                  "BITANIC",
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  "PRECISION CONTROL",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Staggered Progress Bar
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 6), // Match with AuthWrapper timer
                  curve: Curves.easeOutCubic,


                  builder: (context, value, child) {
                    return Column(
                      children: [
                        Container(
                          width: 220,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [colorScheme.primary, colorScheme.secondary],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "${(value * 100).toInt()}%",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Cycling Messages
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    _loadingMessages[_currentMessageIndex],
                    key: ValueKey(_currentMessageIndex),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Branding Footer
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 2,
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "PT. Makerindo Prima Solusi",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingLeaf(int index, ColorScheme colorScheme) {
    final random = math.Random(index);
    final size = 20.0 + random.nextDouble() * 30;
    final startX = random.nextDouble() * 400;
    
    return AnimatedBuilder(
      animation: _leafController,
      builder: (context, child) {
        final progress = (_leafController.value + (index / 6)) % 1.0;
        return Positioned(
          top: -100 + (progress * 800),
          left: startX + (math.sin(progress * 5) * 50),
          child: Transform.rotate(
            angle: progress * math.pi * 4,
            child: Icon(
              Icons.spa_rounded,
              size: size,
              color: colorScheme.primary.withValues(alpha: 0.05),
            ),
          ),
        );
      },
    );
  }
}
