
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:assign_3/widget_tree.dart';
import 'package:assign_3/pages/home_page.dart';
import 'package:assign_3/pages/login_register_page.dart';
import 'package:assign_3/charts_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => WidgetTree(),
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/charts': (context) => ChartsPage(expenses: []),
      },
    );
  }
}


