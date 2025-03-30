import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../secrets.dart';

class GeminiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  Future<bool> isValidTargetWeight(
    String goal,
    double currentWeight,
    double targetWeight,
  ) async {
    String prompt =
        "A person wants to achieve the goal: '$goal'. Their current weight is $currentWeight kg. "
        "They set a target weight of $targetWeight kg. "
        "Does this target weight align logically with their goal? "
        "For example, if the goal is 'weight loss', the target weight should be lower. "
        "If the goal is 'muscle gain', the target weight should be higher. "
        "Respond only with 'true' or 'false'.";
    final content = Content.text(prompt);
    final response = await model.generateContent([content]);
    if (response.text != null &&
        response.text!.trim().toUpperCase() == "TRUE") {
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
    if (response.text != null &&
        response.text!.trim().toUpperCase() == "TRUE") {
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
    if (response.text != null &&
        response.text!.trim().toUpperCase() == "TRUE") {
      return true;
    } else {
      return false;
    }
  }

  Future<void> generateAndSaveRecipes(String extra) async {
    Map<String, dynamic>? userData = await getUserData();
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in.");
    }
    final String userId = user.uid;

    try {
      final DocumentSnapshot userRecipeSnapshot =
          await _firestore.collection('recipes').doc(userId).get();

      Set<String> existingRecipeNames = {};

      if (userRecipeSnapshot.exists) {
        Map<String, dynamic> existingData =
            userRecipeSnapshot.data() as Map<String, dynamic>;

        for (String mealType in ["Breakfast", "Lunch", "Dinner"]) {
          if (existingData.containsKey(mealType) &&
              existingData[mealType] is List) {
            List<dynamic> recipesList = existingData[mealType];
            for (var recipe in recipesList) {
              if (recipe is Map<String, dynamic> &&
                  recipe.containsKey('name')) {
                existingRecipeNames.add(recipe['name'].toString());
              }
            }
          }
        }
      }

      final String geminiPrompt = """
      Generate a list of 15 recipes: 5 for breakfast, 5 for lunch, and 5 for dinner.
      The recipes is for a  ${userData?['gender']} who wants to achieve the goal: ${userData?['main_goal']}. Their current weight is ${userData?['weight']}kg. 
      he/she set a target weight of  ${userData?['target_weight']} kg.
      The recipes generated should also take into account the following USER information:
      health conditions:  ${userData?['health_conditions']},
      dietary restrictions:  ${userData?['dietary_restrictions']},
      preference: ${extra !=""? extra: "no extra preference"}
      if preference is a food name like "cheese", generate the recipes that have more cheese, if preference is "no cheese" don't generate recipes that have cheese inside.
      IMPORTANT: Avoid generating recipes that have already been generated before: 
      ${existingRecipeNames.isNotEmpty ? existingRecipeNames.join(", ") : "No previous recipes"}.
      Structure the output as a single JSON object with three top-level keys: "Breakfast", "Lunch", and "Dinner".
      Each key should map to a JSON array containing exactly 5 recipe objects.
      Each recipe object within the arrays must have the following keys exactly:
      - "name": A string for the recipe's name.
      - "ingredient": A JSON array of strings, listing the ingredients.
      - "ingredient_amount": A JSON array of strings, listing the corresponding (amount/quantity/gram(g) or milliliters(ml)) for each ingredient. The order MUST match the "ingredient" array.
      - "guide": A JSON array of strings, where each string is a step in the cooking instructions.

      Ensure the output is ONLY the valid JSON object requested, with no surrounding text or markdown formatting like ```json ```.

      Example structure for one meal type:
      "Breakfast": [
        {
          "name": "Scrambled Eggs",
          "ingredient": ["Eggs", "Milk", "Butter", "Salt", "Pepper"],
          "ingredient_amount": ["2 large", "100ml", "20g", "4g", "5g"],
          "guide": [
            "Whisk eggs and milk.",
            "Melt butter in skillet.",
            "Pour eggs and scramble.",
            "Season."
          ]
        }
      ]
      """;
      final content = Content.text(geminiPrompt);
      final response = await model.generateContent([content]);

      if (response.text == null || response.text!.trim().isEmpty) {
        throw Exception("Gemini API returned an empty response.");
      }
      String jsonString = response.text!.trim();
      if (jsonString.startsWith("```json")) {
        jsonString = jsonString.substring(7);
      }
      if (jsonString.endsWith("```")) {
        jsonString = jsonString.substring(0, jsonString.length - 3);
      }
      jsonString = jsonString.trim();

      Map<String, dynamic> rawRecipes;
      try {
        rawRecipes = jsonDecode(jsonString);
      } catch (e) {
        throw Exception("Failed to parse JSON response from Gemini.");
      }
      final Map<String, List<Map<String, dynamic>>> enrichedRecipes = {};
      for (var mealTypeEntry in rawRecipes.entries) {
        final String mealType = mealTypeEntry.key;
        if (mealTypeEntry.value is! List) {
          enrichedRecipes[mealType] = [];
          continue;
        }

        final List<dynamic> recipesList = mealTypeEntry.value;
        final List<Map<String, dynamic>> enrichedRecipeListForMeal = [];

        for (var recipeDynamic in recipesList) {
          if (recipeDynamic is Map<String, dynamic>) {
            final Map<String, dynamic> recipe = recipeDynamic;

            // --- Data Validation and Type Casting ---
            final String recipeName =
                recipe['name'] as String? ??
                'Unnamed Recipe'; // Default if null
            final List<String> ingredients =
                (recipe['ingredient'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
            final List<String> amounts =
                (recipe['ingredient_amount'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
            final List<String> guide =
                (recipe['guide'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];

            // --- Build the final recipe map for Firestore ---
            final Map<String, dynamic> firestoreRecipe = {
              'name': recipeName,
              'ingredient': ingredients,
              'ingredient_amount': amounts,
              'guide': guide,
            };
            enrichedRecipeListForMeal.add(firestoreRecipe);
          }
        }
        enrichedRecipes[mealType] = enrichedRecipeListForMeal;
      }
      final DocumentReference userRecipeDoc = _firestore
          .collection('recipes')
          .doc(userId);

      await userRecipeDoc.set({
        'Breakfast': enrichedRecipes['Breakfast'] ?? [],
        'Lunch': enrichedRecipes['Lunch'] ?? [],
        'Dinner': enrichedRecipes['Dinner'] ?? [],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } on GenerativeAIException catch (e) {
      print("Gemini API Error: ${e.message}");
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
