import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:foodshare/screens/home_page.dart';
import 'package:foodshare/screens/home_screen.dart';
import 'package:foodshare/screens/login.dart';
import 'package:foodshare/screens/start.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foodshare App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.yellow.shade800,
        accentColor: Color(0xFFFEF9EB),
      ),
      home: HomePage(),
    );
  }
}
