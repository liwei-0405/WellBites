import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserScreen extends StatelessWidget {
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
                    onPressed: () => Navigator.of(context).pop(false), // ❌ 不退出
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true), // ✅ 退出
                    child: Text("Exit"),
                  ),
                ],
              ),
        );
        return exitApp ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("User Page"),
          automaticallyImplyLeading: false, // ❌ 隐藏 AppBar 返回按钮
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context,'/main');
            },
            child: Text("Logout"),
          ),
        ),
      ),
    );
  }
}
