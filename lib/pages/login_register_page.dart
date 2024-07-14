import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assign_3/auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = '';
  bool isLogin = true;

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  bool _isPasswordVisible = false;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> forgotPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _controllerEmail.text,
      );
      setState(() {
        errorMessage = 'Password reset link sent to your email.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      await Auth().createUserWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Widget _forgotPasswordButton() {
    if (isLogin) {
      return TextButton(
        onPressed: forgotPassword,
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 15,
            color: Colors.deepPurple[500],
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _errorMessage() {
    return Text(errorMessage == '' ? '' : 'Hmm ? $errorMessage');
  }

  Widget _submitButton() {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStatePropertyAll(Colors.deepPurple[500]),
        foregroundColor: MaterialStatePropertyAll(Colors.white),
      ),
      onPressed:
          isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword,
      child: Text(isLogin ? 'Login' : 'Register'),
    );
  }

  Widget _loginOrRegisterButton() {
    return TextButton(
      style: ButtonStyle(
        backgroundColor: MaterialStatePropertyAll(Colors.deepPurple[500]),
        foregroundColor: MaterialStatePropertyAll(Colors.white),
      ),
      onPressed: () {
        setState(() {
          isLogin = !isLogin;
        });
      },
      child: Text(isLogin ? 'Register instead' : 'Login instead'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Budget Tracker',
          style: TextStyle(
            color: Colors.deepPurple[700],
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 30,
          ),
        ),
        backgroundColor: Colors.deepPurple[300],
        centerTitle: true,
        elevation: 0.0,
      ),
      backgroundColor: Colors.deepPurple[300],
      body: Container(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _controllerEmail,
              decoration: InputDecoration(
                labelText: 'email',
              ),
            ),
            TextField(
              obscureText: !_isPasswordVisible,
              controller: _controllerPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.black,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
            ),
            _errorMessage(),
            _submitButton(),
            _loginOrRegisterButton(),
            _forgotPasswordButton(),
          ],
        ),
      ),
    );
  }
}
