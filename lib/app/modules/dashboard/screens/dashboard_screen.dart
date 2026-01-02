import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:appwrite_user_app/app/modules/categories/screens/category_screen.dart';
import 'package:appwrite_user_app/app/modules/coupons/screens/coupons_screen.dart';



class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _chartAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _chartAnimation;

  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _chartAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _animationController.forward();
    // Delay chart animation to start after page fade in
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _chartAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }

}
