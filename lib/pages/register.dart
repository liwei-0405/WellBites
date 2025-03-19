import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'status': 'unverified',
          'gender': null,
          'birthday': null,
          'height': null,
          'weight': null,
          'main_goals': null,
          'target_weight': null,
          'goal_date': null,
          'dietary_restrictions': null,
          'health_conditions': null,
        });

        Navigator.pushNamedAndRemoveUntil(context, '/user', (route) => false);
      }
    } else {
      setState(() {
        errorMessage = error;
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
            if (errorMessage != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: Text("Register")),
            TextButton(
              onPressed:
                  () => Navigator.pushReplacementNamed(context, '/login'),
              child: Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
