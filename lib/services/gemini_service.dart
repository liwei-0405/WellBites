import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../secrets.dart';

class GeminiService {
  final GenerativeModel model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: Secrets.geminiApiKey,
  );

Future<Map<String, dynamic>?> getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }
    return null;
  }

Future<String> getAIResponse(String userInput) async {
    try {
      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      Map<String, dynamic>? userData = await getUserData();
      if (userData == null) {
        return "I couldn't retrieve your profile data. Please make sure you're logged in.";
      }

      String systemPrompt = """
      Today’s date is **$todayDate**.
      Please use this information when answering time-sensitive questions.
      
      You are an intelligent health assistant. The user has the following data:
      - Name: ${userData['username']}
      - Birthday: ${userData['birthday']}
      - Gender: ${userData['gender']}
      - Height: ${userData['height']} cm
      - Weight: ${userData['weight']} kg
      - Target weight: ${userData['target_weight']} kg
      - Target date: ${userData['goal_date']}
      - Main goals: ${userData['main_goals']}
      - Health conditions: ${userData['health_conditions']}
      - Dietary restrictions: ${userData['dietary_restrictions']}

      Please answer user questions based on the given data in a natural and helpful way.
      Do not modify any data. Just provide insights and suggestions.
      But the way, if you wish user to change their data, or if user ask to change data, you may tell them to modify in their profile page, theres a function to modify.
      """;

      final content = Content.text("$systemPrompt\nUser Input: $userInput");
      final response = await model.generateContent([content]);

      return response.text ?? "AI could not generate a response.";
    } catch (e) {
      return "Error: $e";
    }
  }
  

  Future<bool> isValidGoal(String goal) async {
    if (goal.trim().isEmpty) return false;
    final prompt = """
      You are a Nutritional Health AI, determine if the goal entered by the user is related to health, exercise, weight loss, muscle gain.
      - If the goal is health-related (e.g. 'I want to lose weight', 'I want to gain muscle'), return 'YES'.
      - Returns 'NO' if the input is a meaningless word (e.g. 'hahaha', 'apple').
      - Only return 'YES' or 'NO', no other explanation is needed.
      User input: '$goal'
    """;
    final content = Content.text(prompt);
    final response = await model.generateContent([content]);
    if (response.text != null && response.text!.trim().toUpperCase() == "YES") {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> isValidTargetWeight(String goal, double currentWeight, double targetWeight) async {
    String prompt = "A person wants to achieve the goal: '$goal'. Their current weight is $currentWeight kg. "
        "They set a target weight of $targetWeight kg. "
        "Does this target weight align logically with their goal? "
        "For example, if the goal is 'weight loss', the target weight should be lower. "
        "If the goal is 'muscle gain', the target weight should be higher. "
        "Respond only with 'true' or 'false'.";
    final content = Content.text(prompt);
    final response = await model.generateContent([content]);
    if (response.text != null && response.text!.trim().toUpperCase() == "TRUE") {
      return true;
    } else {
      return false;
    }
  }

    Future<bool> isValidHealthConditions(String healthConditions) async {
    if (healthConditions.isEmpty) return true; 
    String prompt =
        "Is this a valid health condition? '$healthConditions'. "
        "Examples of valid conditions: Diabetes, High Blood Pressure, Asthma. "
        "Respond only with 'true' or 'false'.";
    final content = Content.text(prompt);
    final response = await model.generateContent([content]);
    if (response.text != null && response.text!.trim().toUpperCase() == "TRUE") {
      return true;
    } else {
      return false;
    }
  }


  Future<bool> isValidDietaryRestrictions(String dietaryRestrictions) async {
    if (dietaryRestrictions.isEmpty) return true;
    String prompt =
        "Is this a valid dietary restriction? '$dietaryRestrictions'. "
        "Examples of valid dietary restrictions: Vegan, Nut Allergy, Lactose Intolerance. "
        "Respond only with 'true' or 'false'.";

    final content = Content.text(prompt);
    final response = await model.generateContent([content]);
    if (response.text != null && response.text!.trim().toUpperCase() == "TRUE") {
      return true;
    } else {
      return false;
    }
  }

}


