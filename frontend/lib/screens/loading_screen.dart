import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();

    // Auto navigate to dashboard after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C17),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            ScaleTransition(
              scale: _animation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF56612F),
                      const Color(0xFFBFCD8F),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF56612F)..withValues(alpha:0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.dashboard,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Loading text
            FadeTransition(
              opacity: _animation,
              child: Column(
                children: [
                  Text(
                    'SYSTEM_MONITOR_V1',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF56612F),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Initializing Node Interface...',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF46483C),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Progress indicator
            FadeTransition(
              opacity: _animation,
              child: SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _animation.value,
                  backgroundColor: const Color(0xFFE5E2DA)..withValues(alpha:0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF56612F)),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}