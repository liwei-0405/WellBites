import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
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

  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController mainGoalsController = TextEditingController();
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
          nicknameController.text = userDoc['nickname'] ?? "";
          selectedGender = userDoc['gender'];
          selectedBirthday =
              userDoc['birthday'] != null
                  ? DateTime.parse(userDoc['birthday'])
                  : null;
          heightController.text = userDoc['height']?.toString() ?? "";
          weightController.text = userDoc['weight']?.toString() ?? "";
          mainGoalsController.text = userDoc['main_goals'] ?? "";
          targetWeightController.text =
              userDoc['target_weight']?.toString() ?? "";
          goalDateController.text = userDoc['goal_date'] ?? "";
          dietaryRestrictionsController.text =
              userDoc['dietary_restrictions'] ?? "";
          healthConditionsController.text = userDoc['health_conditions'] ?? "";


          //means last time already checked by ai
          isMainGoalValid = mainGoalsController.text.isNotEmpty;
          isTargetWeightValid = targetWeightController.text.isNotEmpty;
          isHealthConditionsValid = healthConditionsController.text.isNotEmpty;
          isDietaryRestrictionsValid =
          dietaryRestrictionsController.text.isNotEmpty;
        });
      }
    }
  }



  // details with selections parts (gender birthday goal date)
  String? selectedGender;
  DateTime? selectedBirthday, selectedGoalDate;

  //Select Birthday
  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedBirthday) {
      setState(() {
        selectedBirthday = picked;
      });
    }
  }

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

  // handle saving data to firestore => navigate to user home
  void saveUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'nickname': nicknameController.text.trim(),
          'gender': selectedGender,
          'birthday':
              selectedBirthday != null
                  ? selectedBirthday!.toIso8601String()
                  : null,
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

  // restate the page
  Widget _buildPageContent(String title, Widget field) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        field,
        SizedBox(height: 40),
        ElevatedButton(
          onPressed: isCurrentPageValid() ? nextPage : null,
          child: Text(_currentPage == 9 ? "Done" : "Next"),
        ),
      ],
    );
  }

  // AI checking parts
  bool isMainGoalValid = false;
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
    double? currentWeight = double.tryParse(weightController.text.trim());
    double? targetWeight = double.tryParse(targetWeightController.text.trim());
    String goal = mainGoalsController.text.trim().toLowerCase();

    if (currentWeight == null || targetWeight == null) {
      setState(() {
        isTargetWeightValid = false;
        isCheckingTargetWeight = false;
      });
      return;
    }
    _debounce = Timer(Duration(seconds: 1), () async {
      bool result = await _geminiService.isValidTargetWeight(
        goal,
        currentWeight,
        targetWeight,
      );

      setState(() {
        isTargetWeightValid = result;
        isCheckingTargetWeight = false;
      });
    });
  }

  // Check is the main goal logic?
  void onMainGoalChanged(String value) {
    setState(() {
      isMainGoalValid = false;
      isCheckingAI = true;
      targetWeightController.clear();
      isTargetWeightValid = false;
      targetWeightController.text = "";
    });
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        isCheckingAI = false;
      });
      return;
    }
    _debounce = Timer(Duration(seconds: 1), () async {
      bool result = await _geminiService.isValidGoal(value.trim());

      setState(() {
        isMainGoalValid = result;
        isCheckingAI = false;
      });
    });
  }

  // checking details valid or not
  bool isCurrentPageValid() {
    switch (_currentPage) {
      case 0:
        return nicknameController.text.trim().isNotEmpty;
      case 1:
        return selectedGender != null;
      case 2:
        return selectedBirthday != null;
      case 3:
        return isValidNumber(heightController.text.trim());
      case 4:
        return isValidNumber(weightController.text.trim());
      case 5:
        return isMainGoalValid;
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
          title: Text("Complete Your Profile"),
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
                "Enter your Nickname",
                TextField(
                  controller: nicknameController,
                  decoration: InputDecoration(labelText: "Nickname"),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              _buildPageContent(
                "Select your Gender",
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text("Male"),
                      selected: selectedGender == "Male",
                      onSelected:
                          (selected) => setState(
                            () => selectedGender = selected ? "Male" : null,
                          ),
                    ),
                    SizedBox(width: 10),
                    ChoiceChip(
                      label: Text("Female"),
                      selected: selectedGender == "Female",
                      onSelected:
                          (selected) => setState(
                            () => selectedGender = selected ? "Female" : null,
                          ),
                    ),
                  ],
                ),
              ),
              _buildPageContent(
                "Select your Birthday",
                ElevatedButton(
                  onPressed: () => _selectBirthday(context),
                  child: Text(
                    selectedBirthday == null
                        ? "Select Birthday"
                        : "${selectedBirthday!.day}-${selectedBirthday!.month}-${selectedBirthday!.year}",
                  ),
                ),
              ),
              _buildPageContent(
                "Enter your Height (cm)",
                TextField(
                  controller: heightController,
                  decoration: InputDecoration(labelText: "Height (cm)"),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              _buildPageContent(
                "Enter your Weight (kg)",
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(labelText: "Weight (kg)"),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              _buildPageContent(
                "Enter your Main Goals",
                Column(
                  children: [
                    TextField(
                      controller: mainGoalsController,
                      decoration: InputDecoration(labelText: "Main Goals"),
                      onChanged: (value) {
                        isMainGoalValid = false;
                        onMainGoalChanged(value);
                      },
                    ),
                    if (isCheckingAI) // show loading if checking by ai
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: CircularProgressIndicator(),
                      ),
                    if (!isMainGoalValid &&
                        !isCheckingAI &&
                        mainGoalsController.text.trim().isNotEmpty)
                      Text(
                        "❌ Your goal is not valid. Please enter a clear health-related goal.",
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                  ],
                ),
              ),
              _buildPageContent(
                "Enter your Target Weight (kg)",
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
                    if (targetWeightController.text.isNotEmpty && !(isValidNumber(targetWeightController.text.trim())))
                      Text(
                        "❌ Wrong Format xxx.xx (only numerals)",
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      )
                    else if (targetWeightController.text.isNotEmpty && !isTargetWeightValid && !isCheckingTargetWeight)
                      Text(
                        "❌ Target weight does not match your goal. Please check again.",
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                  ],
                ),
              ),
              _buildPageContent(
                "Enter your Goal Date",
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
                              healthConditionsController.text =
                                  "None";
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
}
