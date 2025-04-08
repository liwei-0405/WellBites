import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PastRecordsPage extends StatefulWidget {
  @override
  _PastRecordsPageState createState() => _PastRecordsPageState();
}

class _PastRecordsPageState extends State<PastRecordsPage> {
  DateTime? selectedDate;
  List<Map<String, dynamic>> meals = [];
  int totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0;

  final List<String> categoryOrder = ["Breakfast", "Lunch", "Dinner", "Extra Meal"];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      await _fetchMealsForDate(picked);
    }
  }

  Future<void> _fetchMealsForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final startOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day));
    final endOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 23, 59, 59));

    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('meals')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThanOrEqualTo: endOfDay)
        .get();

    if (query.docs.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("No Records"),
          content: Text("There are no meals logged on this date."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );

      setState(() {
        meals = [];
        totalCalories = totalProtein = totalCarbs = totalFat = 0;
      });
    } else {
      int cal = 0, pro = 0, carb = 0, fat = 0;
      final results = query.docs.map((doc) {
        final data = doc.data();
        cal += _parse(data['calories']);
        pro += _parse(data['protein']);
        carb += _parse(data['carbs']);
        fat += _parse(data['fat']);
        return data;
      }).toList();

      setState(() {
        meals = results;
        totalCalories = cal;
        totalProtein = pro;
        totalCarbs = carb;
        totalFat = fat;
      });
    }
  }

  int _parse(String? value) {
    if (value == null) return 0;
    return int.tryParse(value.split(' ').first) ?? 0;
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final imageUrl = meal['imageUrl'] as String?;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl, width: 90, height: 90, fit: BoxFit.cover),
              ),
              SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['meal'] ?? '-',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  SizedBox(height: 4),
                  Text(
                    meal['description'] ?? '-',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _nutrientChip("Protein", meal['protein']),
                      _nutrientChip("Carbs", meal['carbs']),
                      _nutrientChip("Fat", meal['fat']),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            meal['calories'] ?? '0 kcal',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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

  Widget _nutrientChip(String label, String? value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      constraints: BoxConstraints(minWidth: 60),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          "$label: ${value ?? '0'}",
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Map<String, dynamic>>> groupedMeals = {
      for (var cat in categoryOrder) cat: []
    };
    for (var meal in meals) {
      final category = meal['category'] ?? 'Uncategorized';
      if (groupedMeals.containsKey(category)) {
        groupedMeals[category]!.add(meal);
      } else {
        groupedMeals[category] = [meal];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Past Records Viewer"),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedDate != null)
              Text(
                "Records for: ${selectedDate!.toLocal().toString().split(' ')[0]}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 8),
            if (meals.isNotEmpty)
              Text("Total: $totalCalories kcal, $totalProtein g protein, $totalCarbs g carbs, $totalFat g fat"),
            const SizedBox(height: 20),
            Expanded(
              child: groupedMeals.values.every((list) => list.isEmpty)
                  ? Center(child: Text("No data available."))
                  : ListView(
                      children: categoryOrder.where((cat) => groupedMeals[cat]!.isNotEmpty).map((category) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("🍽 $category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            ...groupedMeals[category]!.map((meal) => _buildMealCard(meal)),
                            const SizedBox(height: 20),
                          ],
                        );
                      }).toList(),
                    ),
            )
          ],
        ),
      ),
    );
  }
}
