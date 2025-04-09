import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/height_selector.dart';
import '../widgets/weight_picker.dart';
import '../widgets/gender_option.dart';
import '../services/gemini_service.dart';
import 'dart:async';
import 'user_home.dart';

class UserDetailsScreen extends StatefulWidget {
  final String sourceScreen;

  const UserDetailsScreen({super.key, this.sourceScreen = "Profile"});

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController dietaryRestrictionsController =
      TextEditingController();
  final TextEditingController healthConditionsController =
      TextEditingController();

  bool _isLoading = true;
  // get firestore user's details , if insert before

  void _triggerRebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    usernameController.addListener(_triggerRebuild);
    // Call the async initialization function
    _initializeScreen();
  }

  // New async initialization function
  Future<void> _initializeScreen() async {
    // Determine initial page
    int initialPage = 0;
    if (widget.sourceScreen == "Weight") {
      initialPage = 4;
    }
    _currentPage = initialPage;
    // Initialize PageController here
    _pageController = PageController(initialPage: initialPage);

    // Load user data and wait for it to complete BEFORE building the main UI
    await loadUserData();

    // Set loading to false after data is loaded (or failed to load)
    // Note: loadUserData now handles setting _isLoading to false inside setState
    // If loadUserData might complete without calling setState (e.g., if !mounted early),
    // ensure _isLoading is set false here too, but it's cleaner within loadUserData.
  }

  Future<void> loadUserData() async {
    // Keep _isLoading true until data is processed or an error occurs
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (mounted && userDoc.exists) {
          // Check mounted BEFORE setState
          final data = userDoc.data() as Map<String, dynamic>; // Safer access
          setState(() {
            usernameController.text = data['username'] ?? "";
            selectedGender = data['gender'];
            selectedBirthday =
                data['birthday'] != null
                    ? DateTime.parse(data['birthday'])
                    : DateTime(2000, 1, 1);
            selectedHeight = data['height']?.toDouble() ?? 165;
            selectedWeight =
                data['weight']?.toDouble() ?? 45; // Assign Firestore weight
            selectedYear = selectedBirthday!.year;
            selectedMonth = selectedBirthday!.month;
            selectedDay = selectedBirthday!.day;
            selectedMainGoal = data['main_goals'];
            selectedTargetWeight = data['target_weight']?.toDouble();
            selectedGoalDate =
                data['goal_date'] != null
                    ? DateTime.parse(data['goal_date'])
                    : DateTime.now();
            selectedGoalYear = selectedGoalDate!.year;
            selectedGoalMonth = selectedGoalDate!.month;
            selectedGoalDay = selectedGoalDate!.day;
            dietaryRestrictionsController.text =
                data['dietary_restrictions'] ?? "";
            healthConditionsController.text = data['health_conditions'] ?? "";
            // Use '?? 0' for initialweight if it must be non-nullable double
            initialweight = data['weight']?.toDouble() ?? 0;
            isHealthConditionsValid =
                healthConditionsController.text.isNotEmpty;
            isDietaryRestrictionsValid =
                dietaryRestrictionsController.text.isNotEmpty;

            _isLoading = false; // Data loaded, stop loading
          });
        } else if (mounted) {
          // Document doesn't exist or component unmounted before getting data
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Error loading user data: $e");
        if (mounted) {
          // Check mounted before setState on error
          setState(() {
            _isLoading = false;
          }); // Stop loading on error
        }
      }
    } else {
      // No user logged in
      if (mounted) {
        // Check mounted before setState
        setState(() {
          _isLoading = false;
        }); // Stop loading if no user
      }
    }
  }

  double selectedHeight = 165;
  double selectedWeight = 45;
  double? selectedTargetWeight;
  int selectedYear = 2000;
  int selectedMonth = 1;
  int selectedDay = 1;
  int selectedGoalYear = DateTime.now().year;
  int selectedGoalMonth = DateTime.now().month;
  int selectedGoalDay = DateTime.now().day;
  double initialweight = 0;
  String? selectedGender, selectedMainGoal;
  DateTime? selectedBirthday, selectedGoalDate;

  //navigate to next detail
  void nextPage() {
    if (_currentPage == 4) {
      _checkWeightGoalReached();
    } else {
      if (_currentPage < 9) {
        setState(() {
          _currentPage++;
          _pageController.nextPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        });
      } else {
        saveUserDetails();
      }
    }
  }

  // handle saving data to firestore => navigate to user home
  void saveUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final now = DateTime.now();
      final todayString =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'username': usernameController.text.trim(),
            'gender': selectedGender,
            'birthday':
                selectedBirthday != null
                    ? selectedBirthday!.toIso8601String()
                    : null,
            'height': selectedHeight,
            'weight': selectedWeight,
            'main_goals': selectedMainGoal,
            'target_weight': selectedTargetWeight,
            'goal_date':
                selectedGoalDate != null
                    ? selectedGoalDate!.toIso8601String()
                    : null,
            'dietary_restrictions': dietaryRestrictionsController.text.trim(),
            'health_conditions': healthConditionsController.text.trim(),
            'status': 'verified',
            'lastWeightUpdate': FieldValue.serverTimestamp(),
          });
      final weightRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('weight_records');

      final existingRecords =
          await weightRef.where('date', isEqualTo: todayString).limit(1).get();

      if (existingRecords.docs.isNotEmpty) {
        await weightRef.doc(existingRecords.docs.first.id).update({
          'weight': selectedWeight,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        await weightRef.add({
          'weight': selectedWeight,
          'date': todayString,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (widget.sourceScreen == "Profile" || widget.sourceScreen == "Weight") {
        // If started from profile, pop back to it
        Navigator.pop(context);
      } else {
        // Otherwise (e.g., first setup), go to the main UserScreen (Home)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserScreen()),
        );
      }
    }
  }

  // AI checking parts
  bool isHealthConditionsValid = false;
  bool isDietaryRestrictionsValid = false;
  bool isCheckingHealthConditions = false;
  bool isCheckingDietaryRestrictions = false;

  final GeminiService _geminiService = GeminiService();
  Timer? _debounce;
  // check for any healthconditions
  void checkHealthConditions() async {
    setState(() {
      isHealthConditionsValid = false;
      isCheckingHealthConditions = true;
    });
    _debounce?.cancel();
    if (healthConditionsController.text.trim().isEmpty) {
      setState(() {
        isCheckingHealthConditions = false;
      });
      return;
    }
    _debounce = Timer(Duration(seconds: 1), () async {
      bool result = await _geminiService.isValidHealthConditions(
        healthConditionsController.text.trim(),
      );

      setState(() {
        isHealthConditionsValid = result;
        isCheckingHealthConditions = false;
      });
    });
  }

  // check for allegic or vegan?
  void checkDietaryRestrictions() async {
    setState(() {
      isDietaryRestrictionsValid = false;
      isCheckingDietaryRestrictions = true;
    });
    _debounce?.cancel();
    if (dietaryRestrictionsController.text.trim().isEmpty) {
      setState(() {
        isCheckingDietaryRestrictions = false;
      });
      return;
    }
    _debounce = Timer(Duration(seconds: 1), () async {
      bool result = await _geminiService.isValidDietaryRestrictions(
        dietaryRestrictionsController.text.trim(),
      );

      setState(() {
        isDietaryRestrictionsValid = result;
        isCheckingDietaryRestrictions = false;
      });
    });
  }

  Future<void> saveCurrentWeight() async {
    User? user = FirebaseAuth.instance.currentUser;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day); // 去掉时分秒
      final todayString =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      final weightRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('weight_records');

      final existingRecords =
          await weightRef.where('date', isEqualTo: todayString).limit(1).get();

      if (existingRecords.docs.isNotEmpty) {
        await weightRef.doc(existingRecords.docs.first.id).update({
          'weight': selectedWeight,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        await weightRef.add({
          'weight': selectedWeight,
          'date': todayString,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .update({
            'weight': selectedWeight,
            'lastWeightUpdate': FieldValue.serverTimestamp(),
          });
      initialweight = selectedWeight;
    } catch (e) {
      print("Error saving weight: $e");
    }
  }

  void _checkWeightGoalReached() async {
    double? targetWeight = selectedTargetWeight;
    bool isGainingWeight = false;
    bool isLosingWeight = false;
    if (targetWeight == null) {
      _proceedToNextPage();
      return;
    }
    if (selectedMainGoal == "Weight Gain") {
      isGainingWeight = selectedWeight > targetWeight;
    } else if (selectedMainGoal == "Weight Loss") {
      isLosingWeight = selectedWeight < targetWeight;
    }

    if (isGainingWeight || isLosingWeight) {
      _showGoalReachedDialog();
    } else {
      if (widget.sourceScreen == "Weight") {
        await saveCurrentWeight(); // Save just the weight
        if (mounted) {
          // Check if widget is still mounted before popping
          Navigator.pop(context);
        }
      } else {
        _proceedToNextPage();
      }
    }
  }

  void _showGoalReachedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text("🎉 Congratulations!"),
            content: Text(
              "You have reached your target weight! It's time to set a new goal.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    selectedMainGoal = null;
                    selectedTargetWeight = null;
                    selectedGoalDate = DateTime.now();
                    selectedGoalYear = selectedGoalDate!.year;
                    selectedGoalMonth = selectedGoalDate!.month;
                    selectedGoalDay = selectedGoalDate!.day;
                  });
                  _proceedToNextPage();
                },
                child: Text("Set New Goal"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _proceedToNextPage() {
    if (_currentPage < 9) {
      setState(() {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      });
    } else {
      saveUserDetails();
    }
  }

  // checking details valid or not
  bool isCurrentPageValid() {
    switch (_currentPage) {
      case 0:
        return usernameController.text.trim().isNotEmpty;
      case 1:
        return selectedGender != null;
      case 2:
        return selectedBirthday != null;
      case 3:
        return selectedHeight != null;
      case 4:
        return selectedWeight != null;
      case 5:
        return selectedMainGoal != null;
      case 6:
        return selectedTargetWeight != null;
      case 7:
        return selectedGoalDate != null;
      case 8:
        return isHealthConditionsValid && healthConditionsController.text != "";
      case 9:
        return isDietaryRestrictionsValid &&
            dietaryRestrictionsController.text != "";
      default:
        return false;
    }
  }

  // for weight and height format xxx.xx (2decimal places)
  bool isValidNumber(String value) {
    if (value.isEmpty) return false;
    final regex = RegExp(r'^\d+(\.\d{1,2})?$');
    return regex.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF3CA3DD),
          title: Text(
            widget.sourceScreen == "User_Home"
                ? "Let's Get to Know You!"
                : "Update Details",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          // Provide a basic back button during loading if appropriate
          leading:
              (widget.sourceScreen == "Profile" ||
                      widget.sourceScreen == "Weight")
                  ? IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  )
                  : null,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return WillPopScope(
      onWillPop: () async {
        if (_currentPage == 0 ||
            (widget.sourceScreen == "Weight" && _currentPage == 4)) {
          Navigator.pop(
            context,
          ); // Always pop back if coming from Profile or Weight
          return false;
        } else {
          setState(() {
            _currentPage--;
            _pageController.previousPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
          return false;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF3CA3DD),
          title: Text(
            widget.sourceScreen == "User_Home"
                ? "Let's Get to Know You!"
                : "Update Details",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              if (_currentPage == 0 ||
                  (widget.sourceScreen == "Weight" && _currentPage == 4)) {
                if (widget.sourceScreen == "Profile" ||
                    widget.sourceScreen == "Weight") {
                  // If started from profile, pop back to it
                  Navigator.pop(context);
                } else {
                  // Otherwise (e.g., first setup), go to the main UserScreen (Home)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => UserScreen()),
                  );
                }
              } else {
                setState(() {
                  _currentPage--;
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                });
              }
            },
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildPageContent(
                "What's Your Name",
                "",
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(labelText: "username"),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              _buildPageContent(
                "What is Your Gender?",
                "We'll use this information to personalize your experience and help you reach your goals.",
                _buildGenderSelectionPage(),
              ),
              _buildPageContent(
                "Select your Birthday",
                "We'll use this information to calculate your age.",
                _buildDatePicker("Birthday"),
              ),
              _buildPageContent(
                "What is Your Height? (cm)",
                "We'll use this information to calculate your BMI.",
                _buildHeightPicker(),
              ),
              _buildPageContent(
                "What is Your Weight? (kg)",
                "We'll use this information to calculate your BMI.",
                _buildWeightPicker("Weight"),
              ),
              _buildPageContent(
                "What is Your Goal?",
                "Choose your main health objective.",
                Column(
                  children: [
                    _buildGoalOption("Weight Loss"),
                    _buildGoalOption("Improved Health"),
                    _buildGoalOption("Weight Gain"),
                  ],
                ),
              ),
              _buildPageContent(
                "What is Your Target Weight? (kg)",
                "Setting your target weight corresponds to your goals",
                _buildWeightPicker("TargetWeight"),
              ),
              _buildPageContent(
                "When to Achieve Your Goal?",
                "Set your target date to reach your goal",
                _buildDatePicker("GoalDate"),
              ),
              _buildPageContent(
                "Your Health Conditions?",
                "Will be use to personalize our recipes to suit your health conditions.",
                Column(
                  children: [
                    TextField(
                      controller: healthConditionsController,
                      decoration: InputDecoration(
                        labelText: "Health Conditions",
                        hintText:
                            "Example: Diabetes, High Blood Pressure, None",
                      ),
                      onChanged: (value) {
                        setState(() {
                          isHealthConditionsValid = false;
                        });
                        checkHealthConditions();
                      },
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              healthConditionsController.text = "None";
                              isHealthConditionsValid = true;
                            });
                          },
                          child: Text("None"),
                        ),
                      ],
                    ),
                    if (isCheckingHealthConditions)
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: CircularProgressIndicator(),
                      ),
                    if (!isHealthConditionsValid &&
                        !isCheckingHealthConditions &&
                        healthConditionsController.text != "")
                      Text(
                        "❌ Please enter valid health conditions.",
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                  ],
                ),
              ),
              _buildPageContent(
                "Any Dietary Restrictions?",
                "Will be use to personalize our recipes to suit your health conditions.",
                Column(
                  children: [
                    TextField(
                      controller: dietaryRestrictionsController,
                      decoration: InputDecoration(
                        labelText: "Dietary Restrictions",
                        hintText:
                            "Example: Vegan, Nut Allergy, No Restrictions",
                      ),
                      onChanged: (value) {
                        setState(() {
                          isDietaryRestrictionsValid = false;
                        });
                        checkDietaryRestrictions();
                      },
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              dietaryRestrictionsController.text =
                                  "No Restrictions";
                              isDietaryRestrictionsValid = true;
                            });
                          },
                          child: Text("No Restrictions"),
                        ),
                      ],
                    ),
                    if (isCheckingDietaryRestrictions)
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: CircularProgressIndicator(),
                      ),
                    if (!isDietaryRestrictionsValid &&
                        !isCheckingDietaryRestrictions &&
                        dietaryRestrictionsController.text != "")
                      Text(
                        "❌ Please enter valid dietary restrictions.",
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Gender part
  Widget _buildGenderSelectionPage() {
    double screenWidth = MediaQuery.of(context).size.width;
    double buttonSize = screenWidth * 0.4;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GenderOption(
          gender: "Male",
          backgroundColor:
              selectedGender == "Male"
                  ? Color.fromARGB(255, 19, 15, 255)
                  : Color.fromARGB(255, 185, 184, 247),
          isSelected: selectedGender == "Male",
          icon: Icon(Icons.male, size: buttonSize * 0.5, color: Colors.white),
          onTap: () => setState(() => selectedGender = "Male"),
        ),
        SizedBox(height: 10),
        GenderOption(
          gender: "Female",
          backgroundColor:
              selectedGender == "Female"
                  ? Color.fromARGB(255, 138, 25, 183)
                  : Color.fromARGB(255, 177, 152, 187),
          isSelected: selectedGender == "Female",
          icon: Icon(Icons.female, size: buttonSize * 0.5, color: Colors.white),
          onTap: () => setState(() => selectedGender = "Female"),
        ),
      ],
    );
  }

  Widget _buildPageContent(String title, String text, Widget field) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Center(
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
              field,
              SizedBox(height: screenHeight * 0.01),
              ElevatedButton(
                onPressed: isCurrentPageValid() ? nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCurrentPageValid() ? Color(0xFF3CA3DD) : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  (_currentPage == 9 ||
                          (widget.sourceScreen == "Weight" &&
                              (_currentPage == 4 || _currentPage == 7)))
                      ? "Done"
                      : "Continue",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String field) {
    double screenWidth = MediaQuery.of(context).size.width;
    double wheelWidth = screenWidth * 0.20;
    double wheelHeight = 180;
    DateTime now = DateTime.now();
    int startYear = (field == "GoalDate") ? now.year : 1900;
    int endYear = (field == "GoalDate") ? now.year + 50 : now.year;

    int minMonth = 1;
    int maxMonth = 12;
    int minDay = 1;
    int maxDay = 31;

    if (field == "Birthday") {
      if (selectedYear == now.year) {
        maxMonth = now.month;
        if (selectedMonth == now.month) {
          maxDay = now.day;
        }
      }
    } else if (field == "GoalDate") {
      if (selectedGoalYear == now.year) {
        minMonth = now.month;
        if (selectedGoalMonth == now.month) {
          minDay = now.day;
        }
      }
    }
    return Container(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black,
                  Colors.black.withOpacity(0.1),
                ],
                stops: [0.2, 0.5, 0.8],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: wheelWidth,
                  height: wheelHeight,
                  child: ListWheelScrollView.useDelegate(
                    controller: FixedExtentScrollController(
                      initialItem:
                          (field == "GoalDate")
                              ? selectedGoalDay - minDay
                              : selectedDay - minDay,
                    ),
                    itemExtent: 50,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        if (field == "GoalDate") {
                          selectedGoalDay = minDay + index;
                          selectedGoalDate = DateTime(
                            selectedGoalYear,
                            selectedGoalMonth,
                            selectedGoalDay,
                          );
                        } else {
                          selectedDay = minDay + index;
                          selectedBirthday = DateTime(
                            selectedYear,
                            selectedMonth,
                            selectedDay,
                          );
                        }
                      });
                    },
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder:
                          (context, index) =>
                              Center(child: Text("${minDay + index}")),
                      childCount:
                          ((field == "Birthday" &&
                                  selectedYear == now.year &&
                                  selectedMonth == now.month)
                              ? now.day
                              : DateTime(
                                (field == "GoalDate")
                                    ? selectedGoalYear
                                    : selectedYear,
                                (field == "GoalDate")
                                    ? selectedGoalMonth + 1
                                    : selectedMonth + 1,
                                0,
                              ).day) -
                          minDay +
                          1,
                    ),
                  ),
                ),
                SizedBox(width: 10),

                // Month Picker
                SizedBox(
                  width: wheelWidth,
                  height: wheelHeight,
                  child: ListWheelScrollView.useDelegate(
                    controller: FixedExtentScrollController(
                      initialItem:
                          (field == "GoalDate")
                              ? selectedGoalMonth - minMonth
                              : selectedMonth - minMonth,
                    ),
                    itemExtent: 50,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        if (field == "GoalDate") {
                          selectedGoalMonth = minMonth + index;
                          int newMaxDay =
                              DateTime(
                                selectedGoalYear,
                                selectedGoalMonth + 1,
                                0,
                              ).day;
                          if (selectedGoalDay > newMaxDay) {
                            selectedGoalDay = newMaxDay;
                          }
                          selectedGoalDate = DateTime(
                            selectedGoalYear,
                            selectedGoalMonth,
                            selectedGoalDay,
                          );
                        } else {
                          selectedMonth = minMonth + index;
                          int newMaxDay =
                              (selectedYear == now.year &&
                                      selectedMonth == now.month)
                                  ? now.day
                                  : DateTime(
                                    selectedYear,
                                    selectedMonth + 1,
                                    0,
                                  ).day;

                          if (selectedDay > newMaxDay) {
                            selectedDay = newMaxDay;
                          }

                          selectedBirthday = DateTime(
                            selectedYear,
                            selectedMonth,
                            selectedDay,
                          );
                        }
                      });
                    },
                    physics: FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        List<String> months = [
                          "Jan",
                          "Feb",
                          "Mar",
                          "Apr",
                          "May",
                          "Jun",
                          "Jul",
                          "Aug",
                          "Sep",
                          "Oct",
                          "Nov",
                          "Dec",
                        ];
                        return Center(
                          child: Text(months[minMonth - 1 + index]),
                        );
                      },
                      childCount: maxMonth - minMonth + 1,
                    ),
                  ),
                ),
                SizedBox(width: 15),

                // Year Picker
                SizedBox(
                  width: wheelWidth,
                  height: wheelHeight,
                  child: ListWheelScrollView.useDelegate(
                    controller: FixedExtentScrollController(
                      initialItem:
                          (field == "GoalDate")
                              ? selectedGoalYear - startYear
                              : selectedYear - startYear,
                    ),
                    itemExtent: 50,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        if (field == "GoalDate") {
                          selectedGoalYear = startYear + index;
                          selectedGoalDate = DateTime(
                            selectedGoalYear,
                            selectedGoalMonth,
                            selectedGoalDay,
                          );
                        } else {
                          selectedYear = startYear + index;
                          maxMonth =
                              (selectedYear == now.year) ? now.month : 12;
                          maxDay =
                              (selectedYear == now.year &&
                                      selectedMonth == now.month)
                                  ? now.day
                                  : DateTime(
                                    selectedYear,
                                    selectedMonth + 1,
                                    0,
                                  ).day;

                          if (selectedMonth > maxMonth)
                            selectedMonth = maxMonth;
                          if (selectedDay > maxDay) selectedDay = maxDay;

                          selectedBirthday = DateTime(
                            selectedYear,
                            selectedMonth,
                            selectedDay,
                          );
                        }
                      });
                    },
                    physics: FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder:
                          (context, index) =>
                              Center(child: Text("${startYear + index}")),
                      childCount: (endYear - startYear) + 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightPicker() {
    double userHeight = selectedHeight;

    return Container(
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          HeightPicker(
            initialHeight: userHeight,
            onHeightSelected: (height) {
              setState(() {
                userHeight = height;
                selectedHeight = height;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeightPicker(String field) {
    double initial_Weight = selectedWeight;
    double minWeight = 30;
    double maxWeight = 200;
    double heightInMeters = selectedHeight / 100;
    double BMIminWeight = 18.5 * (heightInMeters * heightInMeters);
    double BMImaxWeight = 24.9 * (heightInMeters * heightInMeters);

    if (field != "Weight") {
      if (selectedMainGoal == "Weight Gain") {
        minWeight = selectedWeight + 0.1;
        if (selectedTargetWeight != null) {
          initial_Weight = selectedTargetWeight!.clamp(minWeight, maxWeight);
        } else {
          initial_Weight = minWeight;
        }
      } else if (selectedMainGoal == "Weight Loss") {
        maxWeight = selectedWeight - 0.1;
        if (selectedTargetWeight != null) {
          initial_Weight = selectedTargetWeight!.clamp(minWeight, maxWeight);
        } else {
          initial_Weight = maxWeight;
        }
      } else if (selectedMainGoal == "Improved Health") {
        minWeight = BMIminWeight.clamp(30, 200);
        maxWeight = BMImaxWeight.clamp(30, 200);
        if (selectedTargetWeight != null) {
          initial_Weight = selectedTargetWeight!.clamp(minWeight, maxWeight);
        } else {
          initial_Weight = (minWeight + maxWeight) / 2;
        }
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              WeightPicker(
                initialWeight: initial_Weight,
                minWeight: minWeight,
                maxWeight: maxWeight,
                onWeightSelected: (weight) {
                  setState(() {
                    initial_Weight = weight;
                    if (field == "Weight") {
                      selectedWeight = weight;
                    } else if (field == "TargetWeight") {
                      selectedTargetWeight = weight;
                    }
                  });
                },
              ),
            ],
          ),
        ),
        if (field == "TargetWeight") ...[
          SizedBox(height: 8),
          Text(
            "Suggested range of weight based on BMI: ${BMIminWeight.toStringAsFixed(1)} - ${BMImaxWeight.toStringAsFixed(1)} kg",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _buildGoalOption(String goal) {
    bool isSelected = selectedMainGoal == goal;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMainGoal = goal;
          selectedTargetWeight = null;
        });
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF3CA3DD) : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Color(0xFF3CA3DD) : Colors.grey,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            goal,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
