import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:main/pages/image.dart';

class PersonalPage extends StatefulWidget {
  const PersonalPage({super.key});

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  Uint8List? _image;

  void selectImage() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    setState(() {
      _image = img;
    });
  }

  @override
  Widget build(BuildContext context) {
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),

      body: Column(
        children: [
          Stack(
            children:[
                    _image != null
                        ? CircleAvatar(
                          radius: 50,
                          backgroundImage: MemoryImage(_image!),
                        )
                        : const CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(
                            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTM1jpW8OqjB88o2UY_aZUe6_i7HYC3fyAfIA&s',
                          ),
                        ),
        
            Positioned(
              bottom: -10,
              left: 60,
              child: IconButton(
                onPressed: selectImage,
                icon: const Icon(Icons.add_a_photo_outlined),
              ),
            ),
          ]),
            
          ListTile(
            leading: Icon(Icons.account_box, color: Colors.blue[300],),
            title: const Text('Personal'),
            subtitle: const Text('Edit Profile'),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue[300]),
          ),
        ],
      ),
    );
  }
}
