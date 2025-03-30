import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
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

        print('Image uploaded successfully: $imageUrl');
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
          _imageUrl = snapshot.get('profileImage') ?? "";
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
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Stack(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 350,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/icons/profile_icon_background.png'),
                  fit: BoxFit.cover, // Ensures it covers the whole width
                ),
              ),
            ),
          ],
        ),
        Scaffold(
          backgroundColor:
              Colors.transparent, // Makes it blend with the background
          appBar: AppBar(
            backgroundColor: Colors.transparent, // Transparent App Bar
            elevation: 0, // Removes shadow for a clean look
            actions: [
              IconButton(
                onPressed: () {},
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              ),
            ],
          ),

          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 180),

                  Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Picture
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundImage:
                                  _imageUrl.isNotEmpty
                                      ? NetworkImage(_imageUrl)
                                      : const NetworkImage(
                                        'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png',
                                      ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: -10,
                              child: IconButton(
                                onPressed: selectImage,
                                icon: const Icon(Icons.add_a_photo_outlined),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          width: 30,
                        ), // Space between image and text
                        // User Info (Name & Email)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName.isNotEmpty ? _userName : "Loading...",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _userEmail.isNotEmpty ? _userEmail : "Loading...",
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                ProfileWidget(
                  title: 'Profile',
                  icon: Icons.account_box_outlined,
                  onPress: () {},
                ),
                ProfileWidget(
                  title: 'Favourite',
                  icon: Icons.star_border,
                  onPress: () {},
                ),
                ProfileWidget(
                  title: 'Privacy Policy',
                  icon: Icons.privacy_tip_outlined,
                  onPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),
                ProfileWidget(
                  title: 'Settings',
                  icon: Icons.settings,
                  onPress: () {},
                ),
              ],
            ),
          ),
        ),
      ],
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
