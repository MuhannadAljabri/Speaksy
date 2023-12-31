import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:speak_iq/Screens/Onboarding.dart';
import 'package:speak_iq/style/route_animation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 2),
      () {
        // Navigate to the main screen after 2 seconds
        Navigator.of(context).pushReplacement(slidingFromLeft(OnboardingScreen()));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return  SafeArea(
        child: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SvgPicture.asset(
            'assets/speaksy_blue_with_slogan.svg',),
      ),
    ));
  }
}
