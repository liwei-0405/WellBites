import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'pages/login.dart';
import 'pages/register.dart';
import 'pages/user_home.dart';
import 'pages/diet_log.dart';
import 'pages/past_records.dart';
import 'pages/recipes_page.dart';
import 'pages/chat_screen.dart';
import 'widgets/custom_dialog.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      home: AuthCheck(), // Check Authentication
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/user': (context) => UserScreen(),
        '/main': (context) => MainPage(),
        '/dietLog': (context) => DietLogScreen(),
        '/pastRecords': (context) => PastRecordsPage(),
        '/recipe': (context) => RecipesPage(),
        '/chatpage': (context) => ChatScreen(),
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance.authStateChanges(), // Check did user logged in
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          ); // Waiting for checking firebase
        }
        if (!snapshot.hasData) {
          return MainPage();
        }
        return UserScreen();
      },
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return WillPopScope(
      onWillPop: () async {
        bool exitApp = await showDialog(
          context: context,
          builder:
              (context) => ConfirmationDialog(
                message: "Are you sure you want to exit?",
                confirmText: "Exit",
                cancelText: "Cancel",
                onConfirm: () => Navigator.of(context).pop(true),
                onCancel: () => Navigator.of(context).pop(false),
              ),
        );
        return exitApp ?? false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF8FECD),
                      Color(0xFFFCD6C6),
                      Color(0x7AC4A5CC),
                      Color(0x96967DD0),
                    ],
                    stops: [0.1638, 0.5879, 0.7654, 0.9084],
                  ),
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: screenWidth * 0.8,
                    height: screenHeight * 0.3,
                    child: Image.asset(
                      'assets/icons/adaptive_icon_foreground.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1,
                    ),
                    child: Text(
                      'Your Body, Your Choice, Your Wellness',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF534C90),
                        fontFamily: 'Caudex',
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),

                  Column(
                    children: [
                      SizedBox(
                        width: screenWidth * 0.6,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed:
                              () => Navigator.pushNamed(context, '/login'),
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: Color(0xFF007AFF),
                              fontSize: screenWidth * 0.05,
                              fontFamily: 'B612',
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      SizedBox(
                        width: screenWidth * 0.6,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed:
                              () => Navigator.pushNamed(context, '/register'),
                          child: Text(
                            "Signup",
                            style: TextStyle(
                              color: Color(0xFF007AFF),
                              fontSize: screenWidth * 0.05,
                              fontFamily: 'B612',
                            ),
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
}
