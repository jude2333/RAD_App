import 'package:flutter/material.dart';
import 'patient_list.dart';
import 'session_manger.dart';
import 'welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isLoggedIn = await SessionManager.isLoggedIn();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Radiology App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: isLoggedIn ? '/patient_list' : '/welcome',
      routes: {
        '/welcome': (context) => Welcome(),
        '/patient_list': (context) => PatientList(),
      },
    );
  }
}
