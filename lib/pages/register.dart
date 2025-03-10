import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? errorMessage; // Store Error Message

  void register() async {
    setState(() {
      errorMessage = null;
    });

    String? error = await _authService.registerWithEmail(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (error == null) {
      Navigator.pushReplacementNamed(context, '/user'); // 注册成功
    } else {
      setState(() {
        errorMessage = error; // 显示 Firebase 错误信息
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            if (errorMessage != null) // 🔥 显示错误信息
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(errorMessage!,style: TextStyle(color: Colors.red, fontSize: 14)),
              ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: Text("Register")),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
