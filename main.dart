import 'package:digishop/pages/Testpage.dart';
import 'package:digishop/pages/add_shop_page.dart';
import 'package:digishop/pages/login_page.dart';
import 'package:digishop/pages/owner_dashboard.dart';
import 'package:digishop/pages/splash_screen.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:digishop/pages/owner_dashboard.dart';
import 'package:digishop/pages/splash_screen.dart';
import 'package:digishop/pages/map_picker_page.dart';
import 'package:digishop/pages/category_shops_page.dart';

// ✅ Import Home Page File Only Once
import 'package:digishop/pages/Homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase Initialize
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "DigiShop",

      theme: ThemeData(primarySwatch: Colors.blue),

      home: const SplashScreen(),
    );
  }
}
