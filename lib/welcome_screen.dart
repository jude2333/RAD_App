import 'package:flutter/material.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'login_screen.dart';

class Welcome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FlutterSplashScreen.scale(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white],
        ),
        childWidget: SizedBox(
          height: 200,
          child: Image.asset("assets/anderson-logo.png"),
        ),
        duration: const Duration(seconds: 4),
        animationDuration: const Duration(seconds: 3),
        nextScreen: const Contact(), // Navigate to Contact screen
      ),
    );
  }
}
