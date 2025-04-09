import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:main/pages/user_details.dart';
import 'image.dart';
import 'privacy.dart';

class PersonalPage extends StatefulWidget {
  const PersonalPage({super.key});

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  String _imageUrl = "";
  String _userName = "";
  String _userEmail = "";
  double? weight;
  String mainGoal = "";
  double? targetWeight;
  double? height;
  String gender = "";
  String restrictions = "";
  String healthCondition = "";
  DateTime? birthday;
  DateTime? goalDate;

  void selectImage() async {
    Uint8List? img = await pickImage(ImageSource.gallery);

    if (img != null) {
      String? imageUrl = await uploadImageToCloudinary(img);

      if (imageUrl != null) {
        User? user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .update({'profileImage': imageUrl});

        setState(() {
          _imageUrl = imageUrl;
        });
      }
    }
  }

  void getImageFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

    if (snapshot.exists && snapshot.get('profileImage') != null) {
      setState(() {
        _imageUrl = snapshot.get('profileImage');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getImageFromFirestore();
    getUserData();
  }

  void getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (snapshot.exists) {
        print("Firestore Data: ${snapshot.data()}"); // Debugging Step

        setState(() {
          _userName = snapshot.get('username') ?? "No Name"; // Default if null
          _userEmail = snapshot.get('email') ?? "No Email"; // Default if null
          weight = snapshot.get('weight');
          mainGoal = snapshot.get('main_goals') ?? "";
          targetWeight = snapshot.get('target_weight');
          height = snapshot.get('height');
          gender = snapshot.get('gender') ?? "";
          restrictions = snapshot.get('dietary_restrictions') ?? "";
          healthCondition = snapshot.get('health_conditions') ?? "";

          String? birthdayString = snapshot.get('birthday');
          String? goalDateString = snapshot.get('goal_date');
           birthday =
              birthdayString != null ? DateTime.parse(birthdayString) : null;
          goalDate =
              goalDateString != null ? DateTime.parse(goalDateString) : null;
        });

        print("User Name: $_userName");
        print("User Email: $_userEmail");
      } else {
        print("No user data found in Firestore.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final dateFormat = DateFormat('d MMM y');
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final Color scaffoldBackgroundColor =
        Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: scaffoldBackgroundColor,),Container(
          width: double.infinity,
          height: screenHeight*0.4,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icons/profile_icon_background.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold( 
          backgroundColor: Colors.transparent, // Keep Scaffold transparent
          appBar: AppBar(
            backgroundColor: Colors.transparent, // Keep AppBar transparent
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () {
                  /* Theme toggle logic */
                },
                icon: Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.15),
                // --- Profile Header Section ---
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Picture
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: screenWidth * 0.12,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage:
                                _imageUrl.isNotEmpty
                                    ? NetworkImage(_imageUrl)
                                    : const NetworkImage(
                                          'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png',
                                        )
                                        as ImageProvider,
                          ),
                          Positioned(
                            bottom: -5,
                            right: -15,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                              ),

                              child: IconButton(
                                onPressed: selectImage,
                                icon: Icon(
                                  Icons.add_a_photo_outlined,
                                  size: screenWidth * 0.05,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: screenWidth * 0.05),
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName.isNotEmpty ? _userName : "Loading...",
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),

                            Text(
                              _userEmail.isNotEmpty ? _userEmail : "Loading...",
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    
                    children: [
                      ProfileInfoTile(
                        label: 'Weight',
                        value: weight != null ? '$weight Kg' : 'Not set',
                        icon: Icons.monitor_weight,
                      ),
                      ProfileInfoTile(
                        label: 'Main Goal',
                        value: mainGoal,
                        icon: Icons.flag_outlined,
                      ),
                      ProfileInfoTile(
                        label: 'Target Weight',
                        value:
                            targetWeight != null
                                ? '$targetWeight Kg'
                                : 'Not set',
                        icon: Icons.task_alt_rounded,
                      ),
                      ProfileInfoTile(
                        label: 'Height',
                        value: height != null ? '$height cm' : 'Not set',
                        icon: Icons.height,
                      ),
                      ProfileInfoTile(
                        label: 'Gender',
                        value: gender,
                        icon: Icons.person_outline,
                      ),
                      ProfileInfoTile(
                        label: 'Restrictions',
                        value: restrictions,
                        icon: Icons.no_food,
                      ),
                      ProfileInfoTile(
                        label: 'Health Condition',
                        value: healthCondition,
                        icon: Icons.local_hospital_outlined,
                      ),
                     
                      if (birthday != null)
                        ProfileInfoTile(
                          label: 'Birthday',
                          value: dateFormat.format(birthday!),
                          icon: Icons.cake_outlined,
                        ),

                      if (goalDate != null)
                        ProfileInfoTile(
                          label: 'Goal Date',
                          value: dateFormat.format(goalDate!),
                          icon: Icons.event_available_outlined,
                        ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),
                // --- Menu Items ---
                                ProfileWidget(title: 'Profile', icon: Icons.account_box_outlined, onPress: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserDetailsScreen(sourceScreen: "Profile")))),
                ProfileWidget(title: 'Favourite', icon: Icons.star_border, onPress: () {}),
                ProfileWidget(title: 'Privacy Policy', icon: Icons.privacy_tip_outlined, onPress: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyPage()))),
                ProfileWidget(title: 'Settings', icon: Icons.settings_outlined, onPress: () {}),

                SizedBox(height: screenHeight * 0.02),
                // --- Rating Widget ---
                RatingWidget(),
                SizedBox(height: screenHeight * 0.02), // Bottom padding
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const ProfileInfoTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Color tileColor = Theme.of(context).brightness == Brightness.dark
        ? const Color.fromARGB(255, 29, 29, 29)!
        : Colors.white;
    final Color labelColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[400]!
        : Colors.grey.shade600;
    final Color valueColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final Color iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.tealAccent[100]!
        : Colors.blue.shade400;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(

        crossAxisAlignment:
            CrossAxisAlignment.start, // Align tops when text wraps
        children: [
          // --- Icon ---
          if (icon != null)
            Padding(
              // Add padding to align icon better with first line of text
              padding: const EdgeInsets.only(top: 3.0),
              child: Icon(
                icon,
                size: 22,
                color: iconColor,
              ), // Slightly smaller icon
            ),
          if (icon != null)
            const SizedBox(width: 14), // Increased spacing after icon
          // --- Label ---
          // Expanded allows label to take available space and wrap if needed
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3.0), // Match icon padding
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15, // Slightly adjusted size
                  fontWeight: FontWeight.w500, // Medium weight for label
                  color: labelColor,
                ),
                softWrap: true, // Allow label to wrap
                // No overflow property - will wrap by default
              ),
            ),
          ),

          // Add a flexible gap before the value
          const SizedBox(width: 10),

          // --- Value ---
          // Flexible allows value to wrap without causing overflow
          Flexible(
            // flex: 2, // Uncomment if you want value to tend towards taking more space
            child: Padding(
              padding: const EdgeInsets.only(
                top: 3.0,
              ), // Match icon/label padding
              child: Text(
                value.isNotEmpty ? value : "Not set",
                style: TextStyle(
                  fontSize: 15, // Match label size
                  fontWeight:
                      FontWeight
                          .w500, // Medium weight for value too, or bold if preferred
                  color: valueColor,
                ),
                textAlign: TextAlign.right, // Keep value right-aligned
                softWrap: true, // Ensure value wraps
                // No overflow property
              ),
            ),
          ),
        ],
        
      ),
    );
    
  }
}

class ProfileWidget extends StatelessWidget {
  const ProfileWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.onPress,
  });

  final String title;
  final IconData icon;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPress,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(70),
          color: Colors.blue[300],
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(100)),
        child: Icon(Icons.arrow_right, color: Colors.blue),
      ),
    );
  }
}

class RatingWidget extends StatefulWidget {
  const RatingWidget({super.key});

  @override
  _RatingWidgetState createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  double _rating = 5.0;
  bool _showSlider = false;

  void _saveRating() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('ratings')
            .doc(user.uid)
            .set({
              'rating': _rating,
              'timestamp': FieldValue.serverTimestamp(),
            });

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Success'),
              content: Text('Thank you for rating $_rating ⭐'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _showSlider = false; // Hide slider after submission
                    });
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        print("Error saving rating: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        Text(
          'Enjoy Using This App?',
          style: TextStyle(
            fontSize: screenHeight * 0.02,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: screenHeight * 0.01),

        ElevatedButton(
          onPressed: () {
            if (_showSlider) {
              _saveRating();
            } else {
              setState(() {
                _showSlider = true;
              });
            }
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600], // Change to your desired color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded button
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
          ),

          child: Text(
            _showSlider ? 'Submit' : 'Rate Us 5 ⭐',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Text color
            ),
          ),
        ),

        if (_showSlider)
          Column(
            children: [
              Slider(
                value: _rating,
                min: 0,
                max: 5,
                divisions: 5,
                label: _rating.toString(),
                onChanged: (value) {
                  setState(() {
                    _rating = value;
                  });
                },
              ),
            ],
          ),
      ],
    );
  }
}
