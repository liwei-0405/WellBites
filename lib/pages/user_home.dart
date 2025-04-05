import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:main/main.dart';
import 'package:main/pages/diet_log.dart';
import 'chat_screen.dart';
import 'user_details.dart';
import 'recipes_page.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/home_drawer.dart';


class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> with SingleTickerProviderStateMixin {
  int totalCalories = 0;

  bool isChecking = true;
  bool isUnverified = false;

  Map<String, bool> mealCompleted = {
    'Breakfast': false,
    'Lunch': false,
    'Dinner': false,
    'Extra Meal': false,
  };

  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _fetchTodayMealStatus();
    checkUserStatus(); 

    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    checkUserStatus();
  }

  void checkUserStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userDoc.exists && userDoc['status'] == 'unverified') {
        setState(() {
          isUnverified = true;
        });
      }
    }
    setState(() {
      isChecking = false;
    });
  }

  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          message: "Are you sure you want to log out?",
          confirmText: "Logout",
          cancelText: "Cancel",
          onConfirm: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pop();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainPage()),
              (route) => false,
            );
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _fetchTodayMealStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final startOfDay = Timestamp.fromDate(DateTime(today.year, today.month, today.day));
    final endOfDay = Timestamp.fromDate(DateTime(today.year, today.month, today.day, 23, 59, 59));

    for (var category in mealCompleted.keys) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('meals')
          .where('category', isEqualTo: category)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .get();

      setState(() {
        mealCompleted[category] = snapshot.docs.isNotEmpty;
      });
    }
  }

  void _navigateToDietLog(String category) {
    Navigator.pushNamed(context, '/dietLog', arguments: category).then((_) => _fetchTodayMealStatus());
  }

  void _navigateToSuggestions() {
    Navigator.pushNamed(context, '/suggestions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      endDrawer: HomeDrawer(logoutCallback: _logout),
      body: isChecking
          ? Center(child: CircularProgressIndicator())
          : isUnverified
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Please complete your details\n before using the app.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailsScreen(),
                            ),
                          );
                        },
                        child: Text("Complete Details"),
                      ),
                    ],
                  ),
                )
        : Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(236, 234, 194, 1),
                Color.fromRGBO(245, 219, 206, 1),
                Color.fromRGBO(255, 251, 255, 1),
                Color.fromRGBO(255, 251, 255, 1),
                Color.fromRGBO(255, 251, 255, 1),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildProgressCard(),
                  const SizedBox(height: 20),
                  _buildDietLog(),
                  const SizedBox(height: 20),
                  _buildRecommendationSection(),
                  const SizedBox(height: 20),
                  _buildPastRecords(),
                ],
              ),
            ),
          ),
        ),
      floatingActionButton: isUnverified
      ? null
      : FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(),
              ),
            );
          },
          child: Icon(Icons.face),
          backgroundColor: const Color.fromARGB(255, 255, 207, 231),
        ),
      );
    }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset('assets/icons/adaptive_icon_foreground.png', height: 40),
        Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
      ],
    );
  }


  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(76, 163, 220, 1),
            Color.fromRGBO(149, 154, 238, 1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Progress", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("Calories", style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text("$totalCalories", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroCircle("21%", "Fat", Color.fromRGBO(254, 198,53, 1)),
              _buildMacroCircle("63%", "Pro", Color.fromRGBO(138, 71, 235, 1)),
              _buildMacroCircle("85%", "Carb", Color.fromRGBO(250, 74, 12, 1)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 14, backgroundImage: AssetImage('assets/icons/default_user_icon.png')),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("🎉 Keep the pace! You're doing great.", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMacroCircle(String percent, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: double.tryParse(percent.replaceAll('%', ''))! / 100,
                backgroundColor: Colors.white24,
                color: color,
                strokeWidth: 5,
              ),
              Text(percent, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildDietLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Diet Log", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _mealIcon("Breakfast", 'assets/icons/breakfast.png'),
              _mealIcon("Lunch", 'assets/icons/lunch.png'),
              _mealIcon("Dinner", 'assets/icons/dinner.png'),
              _mealIcon("Extra Meal", 'assets/icons/extra_meal.png'),
            ],
          ),
        )
      ],
    );
  }

  Widget _mealIcon(String label, String asset) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DietLogScreen(category: label),
                  ),
                );
              },
              child: Icon(Icons.add_circle_outline, size: 16, color: Colors.grey.shade700),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "WellBites’s Recommendation",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecipesPage()),
            );
          },
          child: Container(
            width: double.infinity,
            height: 260,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/icons/healthy_illustration.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment.center, 
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: Stack(
              children: [
                // Optional overlay for better text visibility
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withOpacity(0.25),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, size: 35, color: const Color.fromARGB(255, 255, 255, 255)),
                      const SizedBox(height: 6),
                      ScaleTransition(
                        scale: _breathAnimation,
                        child: Text(
                          "Tap to see recommended healthy recipes!",
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildTagChip("😋 Helps Digestion"),
                        _buildTagChip("🍊 Rich in Vitamins A, B & K"),
                        _buildTagChip("🌱 High in Fiber"),
                        _buildTagChip("💧 Hydrating Meals"),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }


  Widget _buildTagChip(String label) {
    return Chip(
      label: Text(label),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: Colors.white.withOpacity(0.9),
      shape: StadiumBorder(),
      labelStyle: TextStyle(
        color: Colors.deepOrange.shade700,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPastRecords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Past Records", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () {}, child: Text("View more")),
          ],
        ),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: 0.25,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                Text("Total Burned - 500 kcal", style: TextStyle(fontSize: 14)),
                Text("Monthly Goal", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
