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
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  String? errorMessage; // Store Error Message

  bool _isFormFilled() {
    return usernameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        confirmPasswordController.text.trim().isNotEmpty;
  }

  void register() async {
    setState(() {
      errorMessage = null;
    });

    if (!_isFormFilled()) {
      setState(() {
        errorMessage = "Please fill in all fields.";
      });
      return;
    }

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      setState(() {
        errorMessage = "Passwords do not match.";
      });
      return;
    }

    String? error = await _authService.registerWithEmail(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (error == null) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': usernameController.text.trim(),
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
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your health\ndeserves better.',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: screenWidth * 0.08,
                      color: Color(0xFF30B0C7),
                      height: 1.2,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'Join WellBites Now. It\'s free!',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Color(0xFF5C5C5C),
                      height: 1.5,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: Color(0xFFE2E2E2), thickness: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Column(
                  children: [
                    _buildInputField(
                      usernameController,
                      "Username",
                      screenWidth,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    _buildInputField(emailController, "Email", screenWidth),
                    SizedBox(height: screenHeight * 0.02),
                    _buildInputField(
                      passwordController,
                      "Password",
                      screenWidth,
                      isPassword: true,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    _buildInputField(
                      confirmPasswordController,
                      "Confirm Password",
                      screenWidth,
                      isPassword: true,
                    ),

                    SizedBox(height: screenHeight * 0.01),

                    SizedBox(
                      height: screenHeight * 0.03,
                      child:
                          errorMessage != null
                              ? Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: screenWidth * 0.035,
                                ),
                              )
                              : SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),


            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.08,
                vertical: screenHeight * 0.03,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                        ),
                        backgroundColor: Color.fromARGB(255, 216, 222, 227),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: register,
                      child: Text(
                        "SIGN UP",
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          color: const Color.fromARGB(255, 9, 60, 154),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // **Already have an account?**
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                      TextButton(
                        onPressed:
                            () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                        child: Text(
                          "Login",
                          style: TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    double screenWidth, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      style: TextStyle(fontSize: screenWidth * 0.045),
      onChanged: (value) {
        setState(() {});
      },
    );
  }
}
