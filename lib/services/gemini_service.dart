import 'package:google_generative_ai/google_generative_ai.dart';
import '../secrets.dart';

class GeminiService {
  final GenerativeModel model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: Secrets.geminiApiKey,
  );

  Future<String> getAIResponse(String userInput) async {
    try {
      final content = Content.text(userInput);
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


