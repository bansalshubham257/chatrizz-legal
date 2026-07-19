import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatrizz/app/theme/app_colors.dart';
import 'package:chatrizz/services/api_service.dart';
import 'package:chatrizz/features/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await context.read<ApiService>().refreshCredits();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Image.asset(
          'assets/splash.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
