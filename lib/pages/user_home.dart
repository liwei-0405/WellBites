import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'user_details.dart';
import '../main.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  bool isChecking = true;
  bool isUnverified = false;

  @override
  void initState() {
    super.initState();
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
        isUnverified = true;
        showUnverifiedDialog();
      }
    }
    setState(() {
      isChecking = false;
    });
  }

  void showUnverifiedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // disable close dialog
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: Text("Incomplete Details"),
              content: Text(
                "You haven't completed your details. Please update your profile.",
              ),
              actions: [
                TextButton(
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
                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => MainPage()),
                      (route) => false,
                    );
                  },
                  child: Text("Logout"),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool exitApp = await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text("Exit App"),
                content: Text("Are you sure you want to exit?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text("Exit"),
                  ),
                ],
              ),
        );
        return exitApp ?? false;
      },

      child:
          isChecking
              ? Scaffold(body: Center(child: CircularProgressIndicator()))
              : Scaffold(
                appBar: AppBar(
                  title: Text("User Page"),
                  automaticallyImplyLeading: false,
                ),
                body:
                    isUnverified
                        ? Center(
                          child: Text(
                            "Please complete your details before using the app.",
                          ),
                        )
                        : Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MainPage(),
                                ),
                                (route) => false,
                              );
                            },
                            child: Text("Logout"),
                          ),
                        ),
                floatingActionButton:
                    isUnverified
                        ? null // Hide Floating Button (if user havent complete details)
                        : FloatingActionButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(),
                              ),
                            );
                          },
                          child: Icon(Icons.chat),
                          backgroundColor: Colors.blue,
                        ),
              ),
    );
  }
}
