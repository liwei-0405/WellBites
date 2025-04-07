import 'package:flutter/material.dart';
import '../pages/personal.dart';
import '../pages/about.dart';

class HomeDrawer extends StatelessWidget {
  final Function(BuildContext) logoutCallback;
  final VoidCallback refreshCallback;

  HomeDrawer({required this.logoutCallback, required this.refreshCallback});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
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
              title: Text('Profile', style: TextStyle(fontFamily: 'Actor')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PersonalPage()),
                ).then((_) {
                  refreshCallback(); // ✅ Refresh user image when returning
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('About', style: TextStyle(fontFamily: 'Actor')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout', style: TextStyle(fontFamily: 'Actor')),
              onTap: () => logoutCallback(context),
            ),
          ],
        ),
      ),
    );
  }
}
