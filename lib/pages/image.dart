import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

Future<Uint8List?> pickImage(ImageSource source) async {
  final ImagePicker imagePicker = ImagePicker();
  XFile? file = await imagePicker.pickImage(source: source);
  if (file != null) {
    return await file.readAsBytes();
  }
  print('No Image Selected');
  return null;
}

Future<String?> uploadImageToCloudinary(Uint8List imageBytes) async {
  try {
    String cloudName =
        "dhonymxt5"; // 🔹 Replace with your Cloudinary cloud name
    String uploadPreset = "g4dunglr"; // 🔹 Replace with your Upload Preset

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload"),
    );

    // 🔹 Correct way to attach image file
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(
      http.MultipartFile.fromBytes('file', imageBytes, filename: "image.jpg"),
    );

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var jsonResponse = jsonDecode(responseData);

    if (response.statusCode == 200) {
      return jsonResponse["secure_url"]; // 🔹 Get the uploaded image URL
    } else {
      print("Failed to upload image: $jsonResponse");
      return null;
    }
  } catch (e) {
    print("Error uploading image: $e");
    return null;
  }
}
