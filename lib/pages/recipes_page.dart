import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gemini_service.dart';
import '../widgets/recipe_options.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot>? _recipeStream;
  bool _isGenerating = false;
  final TextEditingController _restrictionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupRecipeStream();
  }

  void _setupRecipeStream() {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _recipeStream =
            _firestore.collection('recipes').doc(user.uid).snapshots();
      });
    } else {
      setState(() {
        _recipeStream = null;
      });
    }
  }

  Future<void> _triggerRecipeGeneration() async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
    });

    try {
      String restrictions = _restrictionController.text.trim();
      await GeminiService().generateAndSaveRecipes(restrictions);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Recipes updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error generating recipes: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Daily Suggestion')
      ),
      body:
          user == null
              ? const Center(child: Text("Please log in to view recipes."))
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _restrictionController,
                            decoration: InputDecoration(
                              labelText: "Enter dietary preferences...",
                              border: OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isGenerating ? null : _triggerRecipeGeneration,
                          child:
                              _isGenerating
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                  : const Text("Generate"),
                        ),
                      ],
                    ),
                  ),

                  Expanded(child: _buildRecipeContent()),
                ],
              ),
    );
  }

  Widget _buildRecipeContent() {
    if (_recipeStream == null) {
      return const Center(child: Text("Login required to load recipes."));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _recipeStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading recipes: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No recipes found for you yet.'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isGenerating ? null : _triggerRecipeGeneration,
                  child:
                      _isGenerating
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          )
                          : const Text('Generate My Recipes'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null) {
          return const Center(child: Text('Recipe data is empty or invalid.'));
        }

        final List<Map<String, dynamic>> breakfastRecipes = _parseRecipeList(
          data['Breakfast'],
        );
        final List<Map<String, dynamic>> lunchRecipes = _parseRecipeList(
          data['Lunch'],
        );
        final List<Map<String, dynamic>> dinnerRecipes = _parseRecipeList(
          data['Dinner'],
        );

        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            _buildMealSection('Breakfast', breakfastRecipes),
            _buildMealSection('Lunch', lunchRecipes),
            _buildMealSection('Dinner', dinnerRecipes),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _parseRecipeList(dynamic listData) {
    if (listData is List) {
      return listData.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Widget _buildMealSection(String title, List<Map<String, dynamic>> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 8.0),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (recipes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 10.0,
            ),
            child: Text(
              'No $title recipes available.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    recipes.map((recipe) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 180,
                          child: RecipeCard(recipe: recipe),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
