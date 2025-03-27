import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'user_details.dart';
import '../main.dart';
import 'personal.dart';
import 'about.dart';
import '../widgets/custom_dialog.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  bool isChecking = true;
  bool isUnverified = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    checkUserStatus();
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

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () async {
        bool exitApp = await showDialog(
          context: context,
          builder:
              (context) => ConfirmationDialog(
                message: "Are you sure you want to exit?",
                confirmText: "Exit",
                cancelText: "Cancel",
                onConfirm:  () => Navigator.of(context).pop(true),
                onCancel:  () => Navigator.of(context).pop(false),
              ),
        );
        return exitApp ?? false;
      },

      child:
          isChecking
              ? Scaffold(body: Center(child: CircularProgressIndicator()))
              : Scaffold(
                key: _scaffoldKey,
                drawer: SizedBox(
                  width: screenWidth * 0.75,
                  child: Drawer(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        DrawerHeader(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFEBF0C4), Color(0xFFF4CBB9)],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/icons/adaptive_icon_foreground.png',
                                width: 80,
                                height: 80,
                              ),
                            ],
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.person),
                          title: Text(
                            'Profile',
                            style: TextStyle(fontFamily: 'Actor'),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PersonalPage(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text(
                            'About',
                            style: TextStyle(fontFamily: 'Actor'),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AboutScreen(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.logout),
                          title: Text(
                            'Logout',
                            style: TextStyle(fontFamily: 'Actor'),
                          ),
                          onTap: () => _logout(context),
                        ),
                      ],
                    ),
                  ),
                ),
                body: Stack(
                  children: [
                    Container(
                      height: screenHeight * 0.2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFF8FECD), Color(0xFFFCD6C6)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: screenHeight * 0.1,
                      left: 10,
                      child: IconButton(
                        icon: Icon(Icons.menu, size: 30),
                        onPressed:
                            () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                    ),
                    Positioned(
                      top: screenHeight * 0.1,
                      right: 20,
                      child: Image.asset(
                        'assets/icons/adaptive_icon_foreground.png',
                        width: 100,
                        height: 100,
                      ),
                    ),
                    Positioned.fill(
                      top: screenHeight * 0.2,
                      child: Container(),
                    ),
                    Center(
                      child:
                          isUnverified
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Please complete your details\n before using the app.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => UserDetailsScreen(),
                                        ),
                                      );
                                    },
                                    child: Text("Complete Details"),
                                  ),
                                ],
                              )
                              : Container(),
                    ),
                  ],
                ),
                floatingActionButton:
                    isUnverified
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
                          backgroundColor: const Color.fromARGB(
                            255,
                            255,
                            207,
                            231,
                          ),
                        ),
              ),
    );
  }
}
