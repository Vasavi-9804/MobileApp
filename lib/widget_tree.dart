import 'package:flutter/material.dart';
import 'package:assign_3/auth.dart';
import 'package:assign_3/pages/login_register_page.dart';
import 'package:assign_3/pages/home_page.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({Key? key}) : super(key: key);

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Auth().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return HomePage();  
          } else {
            return const LoginPage();
          }
        });
  }
}
