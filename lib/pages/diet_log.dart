import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../secrets.dart';

class DietLogScreen extends StatefulWidget {
  final String category;

  const DietLogScreen({Key? key, this.category = 'Uncategorized'}) : super(key: key);

  @override
  State<DietLogScreen> createState() => _DietLogScreenState();
}

class _DietLogScreenState extends State<DietLogScreen> {
  File? _imageFile;
  Uint8List? _imageBytes;
  final picker = ImagePicker();
  final TextEditingController _mealDetailsController = TextEditingController();
  final GenerativeModel model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: Secrets.geminiApiKey,
  );
  List<Map<String, dynamic>> todayMeals = [];

  late String _category;
  String? _analysisResult;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    loadTodayMeals();
  }

  void _showInputOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take a Photo'),
              onTap: () => _getImage(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo),
              title: Text('Upload a Photo'),
              onTap: () => _getImage(ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Insert Meal Details'),
              onTap: () {
                Navigator.pop(context); // Close modal before showing dialog
                _showTextInputDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    Navigator.pop(context);
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        if (!kIsWeb) _imageFile = File(pickedFile.path);
      });
      _analyzeImage(bytes);
    }
  }

  Future<void> _showTextInputDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Insert Meal Details'),
        content: TextField(
          controller: _mealDetailsController,
          decoration: InputDecoration(hintText: 'e.g. Chicken rice'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _analyzeText(_mealDetailsController.text);
            },
            child: Text('Submit'),
          )
        ],
      ),
    );
  }

  Future<void> _analyzeText(String input) async {
    final prompt = Content.text("""
      You are a nutritionist. Based on the meal name provided below, estimate the nutritional information:
      Meal: "$input"

      Respond in this format:
      Meal: <Meal Name>
      Description: <Short Description>
      Calories: <approximate number> kcal
      Fat: <approximate number> g
      Protein: <approximate number> g
      Carbs: <approximate number> g
    """);

    final response = await model.generateContent([prompt]);
    print("🔍 Gemini raw response (text): \${response.text}");

    if (response.text != null) {
      setState(() {
        _analysisResult = response.text;
      });

      final parsed = parseNutrition(response.text!);
      print("✅ Parsed nutrition: \$parsed");

      await saveToFirestore(parsed);
      await loadTodayMeals();
    }
  }

  Future<void> _analyzeImage(Uint8List imageBytes) async {
    final content = Content.multi([
      TextPart("""
        Please analyze this meal image and provide a nutritional estimation.
        Format your response exactly like this:
        Meal: <Meal Name>
        Description: <Brief Description>
        Calories: <approximate number> kcal
        Fat: <approximate number> g
        Protein: <approximate number> g
        Carbs: <approximate number> g
      """),
      DataPart('image/jpeg', imageBytes),
    ]);

    final response = await model.generateContent([content]);
    print("🔍 Gemini raw response (image): \${response.text}");

    if (response.text != null) {
      final parsed = parseNutrition(response.text!);
      print("✅ Parsed nutrition: \$parsed");

      setState(() {
        _analysisResult = response.text;
      });

      await saveToFirestore(parsed, imageBytes);
      await loadTodayMeals();
    }
  }

  Future<void> saveToFirestore(Map<String, String> parsed, [Uint8List? imageBytes]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = {
      'category': widget.category,
      'meal': parsed['meal'] ?? 'Unnamed Meal',
      'description': parsed['desc'] ?? '-',
      'calories': parsed['calories'] ?? '0 kcal',
      'fat': parsed['fat'] ?? '0 g',
      'protein': parsed['protein'] ?? '0 g',
      'carbs': parsed['carbs'] ?? '0 g',
      'timestamp': Timestamp.now(),
      if (imageBytes != null) 'image': imageBytes.toList(), 
    };

    await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('meals')
      .add(data);
  }

  Future<void> loadTodayMeals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final startOfDay = Timestamp.fromDate(DateTime(today.year, today.month, today.day));
    final endOfDay = Timestamp.fromDate(DateTime(today.year, today.month, today.day + 1));

    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('meals')
        .where('category', isEqualTo: widget.category)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      todayMeals = query.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    });
  }

  Future<void> deleteMeal(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _analysisResult = null; // Clear the preview card
    });

    print("🗑 Deleting document: $docId");

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('meals')
        .doc(docId)
        .delete();

    setState(() {
      todayMeals.removeWhere((meal) => meal['id'] == docId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Meal deleted')),
    );
  }

  Map<String, String> parseNutrition(String response) {
    final lines = response.split('\n');
    String meal = '', desc = '', cal = '', fat = '', protein = '', carbs = '';

    for (var line in lines) {
      final lower = line.toLowerCase();
      if (lower.startsWith('meal:')) meal = line.split(':').sublist(1).join(':').trim();
      if (lower.startsWith('description:')) desc = line.split(':').sublist(1).join(':').trim();
      if (lower.startsWith('calories:')) cal = line.split(':').sublist(1).join(':').trim();
      if (lower.startsWith('fat:')) fat = line.split(':').sublist(1).join(':').trim();
      if (lower.startsWith('protein:')) protein = line.split(':').sublist(1).join(':').trim();
      if (lower.startsWith('carbs:')) carbs = line.split(':').sublist(1).join(':').trim();
    }

    return {
      'meal': meal,
      'desc': desc,
      'calories': cal,
      'fat': fat,
      'protein': protein,
      'carbs': carbs,
    };
  }

  Widget _buildStructuredCard(String result) {
    final parsed = parseNutrition(result);
    return _buildMealCard(
      meal: parsed['meal'] ?? '-',
      description: parsed['desc'] ?? '-',
      calories: parsed['calories'] ?? '-',
      protein: parsed['protein'] ?? '-',
      carbs: parsed['carbs'] ?? '-',
      fat: parsed['fat'] ?? '-',
      imageBytes: _imageBytes,
      docId: '', 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${capitalizedCategory(widget.category)} Log'),
        actions: [
          IconButton(onPressed: _showInputOptions, icon: Icon(Icons.add))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_analysisResult != null) _buildStructuredCard(_analysisResult!),
          if (todayMeals.isEmpty && _analysisResult == null)
            Center(child: Text("No meals logged yet today."))
          else
            ...todayMeals.map((meal) => Column(
              children: [
                _buildMealCard(
                  meal: meal['meal'] ?? '-',
                  description: meal['description'] ?? '-',
                  calories: meal['calories'] ?? '-',
                  protein: meal['protein'] ?? '-',
                  carbs: meal['carbs'] ?? '-',
                  fat: meal['fat'] ?? '-',
                  imageBytes: meal['image'] != null ? Uint8List.fromList(List<int>.from(meal['image'])) : null,
                  docId: meal['id'], 
                ),
                const SizedBox(height: 20),
              ],
            ))
        ],
      ),
    );
  }

  Widget _buildMealCard({
    required String meal,
    required String description,
    required String calories,
    required String protein,
    required String carbs,
    required String fat,
    Uint8List? imageBytes,
    required String docId,
  }) {
    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                if (imageBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(Uint8List.fromList(imageBytes), width: 100, height: 100, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[700]))
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Meal?'),
                        content: Text('Are you sure you want to delete this meal?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (shouldDelete ?? false) {
                      await deleteMeal(docId);
                    }
                  },
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNutritionItem('Calories', calories),
                _buildNutritionItem('Protein', protein),
                _buildNutritionItem('Carbs', carbs),
                _buildNutritionItem('Fat', fat),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600]))
      ],
    );
  }

  String capitalizedCategory(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

}
