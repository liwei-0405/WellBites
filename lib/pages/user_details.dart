import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_home.dart';

class UserDetailsScreen extends StatefulWidget {
  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final TextEditingController genderController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController mainGoalsController = TextEditingController();
  final TextEditingController targetWeightController = TextEditingController();
  final TextEditingController goalDateController = TextEditingController();
  final TextEditingController dietaryRestrictionsController =
      TextEditingController();
  final TextEditingController healthConditionsController =
      TextEditingController();

  void saveUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'gender': genderController.text.trim(),
          'birthday': birthdayController.text.trim(),
          'height': double.tryParse(heightController.text.trim()),
          'weight': double.tryParse(weightController.text.trim()),
          'main_goals': mainGoalsController.text.trim(),
          'target_weight': double.tryParse(targetWeightController.text.trim()),
          'goal_date': goalDateController.text.trim(),
          'dietary_restrictions': dietaryRestrictionsController.text.trim(),
          'health_conditions': healthConditionsController.text.trim(),
          'status': 'verified',
        },
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Complete Your Profile")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: genderController,
                decoration: InputDecoration(labelText: "Gender"),
              ),
              TextField(
                controller: birthdayController,
                decoration: InputDecoration(labelText: "Birthday (YYYY-MM-DD)"),
              ),
              TextField(
                controller: heightController,
                decoration: InputDecoration(labelText: "Height (cm)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: weightController,
                decoration: InputDecoration(labelText: "Weight (kg)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: mainGoalsController,
                decoration: InputDecoration(labelText: "Main Goals"),
              ),
              TextField(
                controller: targetWeightController,
                decoration: InputDecoration(labelText: "Target Weight (kg)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: goalDateController,
                decoration: InputDecoration(
                  labelText: "Goal Date (YYYY-MM-DD)",
                ),
              ),
              TextField(
                controller: dietaryRestrictionsController,
                decoration: InputDecoration(labelText: "Dietary Restrictions"),
              ),
              TextField(
                controller: healthConditionsController,
                decoration: InputDecoration(labelText: "Health Conditions"),
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: saveUserDetails, child: Text("Save")),
            ],
          ),
        ),
      ),
    );
  }
}
