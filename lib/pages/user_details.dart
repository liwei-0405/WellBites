import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../widgets/height_selector.dart';
import '../widgets/weight_picker.dart';
import '../widgets/gender_option.dart';
import '../services/gemini_service.dart';
import 'dart:async';
import 'user_home.dart';

class UserDetailsScreen extends StatefulWidget {
  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController targetWeightController = TextEditingController();
  final TextEditingController goalDateController = TextEditingController();
  final TextEditingController dietaryRestrictionsController =
      TextEditingController();
  final TextEditingController healthConditionsController =
      TextEditingController();
  // get firestore user's details , if insert before
  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        setState(() {
          usernameController.text = userDoc['username'] ?? "";
          selectedGender = userDoc['gender'];
          selectedBirthday =
              userDoc['birthday'] != null
                  ? DateTime.parse(userDoc['birthday'])
                  : DateTime(2000, 1, 1);
          selectedHeight = userDoc['height']?.toDouble() ?? 165;
          selectedWeight = userDoc['weight']?.toDouble() ?? 45;
          selectedYear = selectedBirthday!.year;
          selectedMonth = selectedBirthday!.month;
          selectedDay = selectedBirthday!.day;
          selectedMainGoal = userDoc['main_goals'];
          targetWeightController.text =
              userDoc['target_weight']?.toString() ?? "";
          goalDateController.text = userDoc['goal_date'] ?? "";
          dietaryRestrictionsController.text =
              userDoc['dietary_restrictions'] ?? "";
          healthConditionsController.text = userDoc['health_conditions'] ?? "";
          initialweight = userDoc['weight']?.toDouble() ?? null;
          //means last time already checked by ai
          isTargetWeightValid = targetWeightController.text.isNotEmpty;
          isHealthConditionsValid = healthConditionsController.text.isNotEmpty;
          isDietaryRestrictionsValid =
              dietaryRestrictionsController.text.isNotEmpty;
        });
      }
    }
  }

  double selectedHeight = 165;
  double selectedWeight = 45;
  int selectedYear = 2000;
  int selectedMonth = 1;
  int selectedDay = 1;
  double initialweight = 0;
  String? selectedGender, selectedMainGoal;
  DateTime? selectedBirthday, selectedGoalDate;

  //select goal date
  Future<void> _selectGoalDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedGoalDate) {
      setState(() {
        goalDateController.text =
            "${picked.day}-${picked.month}-${picked.year}";
      });
    }
  }

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
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'username': usernameController.text.trim(),
          'gender': selectedGender,
          'birthday':
              selectedBirthday != null
                  ? selectedBirthday!.toIso8601String()
                  : null,
          'height': selectedHeight,
          'weight': selectedWeight,
          'main_goals': selectedMainGoal,
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

  // AI checking parts
  bool isTargetWeightValid = false;
  bool isHealthConditionsValid = false;
  bool isDietaryRestrictionsValid = false;
  bool isCheckingAI = false;
  bool isCheckingTargetWeight = false;
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

  // check is the weight meet the goals or possible to meet
  void checkTargetWeight() async {
    setState(() {
      isTargetWeightValid = false;
      isCheckingTargetWeight = true;
    });
    _debounce?.cancel();
    double? currentWeight = selectedWeight;
    double? targetWeight = double.tryParse(targetWeightController.text.trim());
    String? goal = selectedMainGoal;

    if (currentWeight == null || targetWeight == null) {
      setState(() {
        isTargetWeightValid = false;
        isCheckingTargetWeight = false;
      });
      return;
    }
    _debounce = Timer(Duration(seconds: 1), () async {
      bool result = await _geminiService.isValidTargetWeight(
        goal!,
        currentWeight,
        targetWeight,
      );

      setState(() {
        isTargetWeightValid = result;
        isCheckingTargetWeight = false;
      });
    });
  }

  void _checkWeightGoalReached() async {
    double? targetWeight = double.tryParse(targetWeightController.text.trim());
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
      _proceedToNextPage();
    }
  }

  void _showGoalReachedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("🎉 Congratulations!"),
            content: Text(
              "You have reached your target weight! It's time to set a new goal.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedMainGoal = null;
                    targetWeightController.text = "";
                    isTargetWeightValid = false;
                  });
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          ),
    );
  }

  void _proceedToNextPage() {
    setState(() {
      _currentPage++;
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
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
        return selectedHeight != null;
      case 5:
        return selectedMainGoal != null;
      case 6:
        return (isTargetWeightValid &&
            isValidNumber(targetWeightController.text.trim()));
      case 7:
        return goalDateController.text.trim().isNotEmpty;
      case 8:
        return isHealthConditionsValid;
      case 9:
        return isDietaryRestrictionsValid;
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
    return WillPopScope(
      onWillPop: () async {
        if (_currentPage == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserScreen()),
          );
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
            ("Let's Get to Know You!"),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              if (_currentPage == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => UserScreen()),
                );
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
                "What's Your Gender?",
                "We'll use this information to personalize your experience and help you reach your goals.",
                _buildGenderSelectionPage(),
              ),
              _buildPageContent(
                "Select your Birthday",
                "We'll use this information to calculate your age.",
                _buildBirthdayPicker(),
              ),
              _buildPageContent(
                "Enter your Height (cm)",
                "We'll use this information to calculate your BMI.",
                _buildHeightPicker(),
              ),
              _buildPageContent(
                "Enter your Weight (kg)",
                "We'll use this information to calculate your BMI.",
                _buildWeightPicker(),
              ),
              _buildPageContent(
                "Select Your Goal",
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
                "Enter your Target Weight (kg)",
                "Setting your target weight corresponds to your goals",
                Column(
                  children: [
                    TextField(
                      controller: targetWeightController,
                      decoration: InputDecoration(
                        labelText: "Target Weight (kg)",
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          isTargetWeightValid = false;
                        });
                        checkTargetWeight();
                      },
                    ),
                    if (isCheckingTargetWeight)
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: CircularProgressIndicator(),
                      ),
                    if (targetWeightController.text.isNotEmpty &&
                        !(isValidNumber(targetWeightController.text.trim())))
                      Text(
                        "❌ Wrong Format xxx.xx (only numerals)",
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      )
                    else if (targetWeightController.text.isNotEmpty &&
                        !isTargetWeightValid &&
                        !isCheckingTargetWeight)
                      Text(
                        "❌ Target weight does not match your goal. Please check again.",
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                  ],
                ),
              ),
              _buildPageContent(
                "Enter your Goal Date",
                "Set your target date to reach your goal",
                ElevatedButton(
                  onPressed: () => _selectGoalDate(context),
                  child: Text(
                    goalDateController.text.isEmpty
                        ? "Select Goal Date"
                        : goalDateController.text,
                  ),
                ),
              ),
              _buildPageContent(
                "Enter your Health Conditions",
                "We will personalize our recipes to suit your health conditions.",
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
                    if (!isHealthConditionsValid && !isCheckingHealthConditions)
                      Text(
                        "❌ Please enter valid health conditions.",
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                  ],
                ),
              ),
              _buildPageContent(
                "Enter your Dietary Restrictions",
                "We will personalize our recipes to suit your health conditions.",
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
                        !isCheckingDietaryRestrictions)
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
                  ? Color.fromARGB(255, 40, 37, 201)
                  : Color.fromARGB(255, 203, 202, 248),
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
                  : Color.fromARGB(255, 197, 175, 183),
          isSelected: selectedGender == "Female",
          icon: Icon(Icons.female, size: buttonSize * 0.5, color: Colors.white),
          onTap: () => setState(() => selectedGender = "Female"),
        ),
      ],
    );
  }

  Widget _buildPageContent(String title, String text, Widget field) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: screenHeight * 0.01),
        Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: screenHeight * 0.01),
        Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
        field,
        SizedBox(height: screenHeight * 0.01),
        ElevatedButton(
          onPressed: isCurrentPageValid() ? nextPage : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isCurrentPageValid() ? Color(0xFF3CA3DD) : Colors.grey,
            foregroundColor: Colors.white,
          ),
          child: Text(_currentPage == 9 ? "Done" : "Continue"),
        ),
      ],
    );
  }

  Widget _buildBirthdayPicker() {
    double screenWidth = MediaQuery.of(context).size.width;
    double wheelWidth = screenWidth * 0.20;
    double wheelHeight = 180;
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
                      initialItem: selectedDay - 1,
                    ),
                    itemExtent: 50,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedDay = index + 1;
                        selectedBirthday = DateTime(
                          selectedYear,
                          selectedMonth,
                          selectedDay,
                        );
                      });
                    },
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder:
                          (context, index) =>
                              Center(child: Text("${index + 1}")),
                      childCount:
                          DateTime(selectedYear, selectedMonth + 1, 0).day,
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
                      initialItem: selectedMonth - 1,
                    ),
                    itemExtent: 50,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedMonth = index + 1;
                        selectedBirthday = DateTime(
                          selectedYear,
                          selectedMonth,
                          selectedDay,
                        );
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
                        return Center(child: Text(months[index]));
                      },
                      childCount: 12,
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
                      initialItem: selectedYear - 1900,
                    ),
                    itemExtent: 50,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedYear = 1900 + index;
                        selectedBirthday = DateTime(
                          selectedYear,
                          selectedMonth,
                          selectedDay,
                        );
                      });
                    },
                    physics: FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder:
                          (context, index) =>
                              Center(child: Text("${1900 + index}")),
                      childCount: DateTime.now().year - 1900 + 1,
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

  Widget _buildWeightPicker() {
    double userWeight = selectedWeight;

    return Container(
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          WeightPicker(
            initialWeight: userWeight,
            onWeightSelected: (weight) {
              setState(() {
                userWeight = weight;
                selectedWeight = weight;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalOption(String goal) {
    bool isSelected = selectedMainGoal == goal;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMainGoal = goal;
          targetWeightController.clear();
          isTargetWeightValid = false;
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
