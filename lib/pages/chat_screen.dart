import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final GeminiService geminiService = GeminiService();
  List<Map<String, String>> chatMessages = [];

  void sendMessage() async {
    String message = messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        chatMessages.add({"user": message});
        chatMessages.add({
          "bot": "Processing...",
        });
      });
      String response = await geminiService.getAIResponse(message);
      setState(() {
        chatMessages.removeLast();
        chatMessages.add({"bot": response});
      });
      messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gemini AI")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                String sender = chatMessages[index].keys.first;
                String text = chatMessages[index][sender]!;
                return ListTile(
                  title: Text(
                    text,
                    textAlign:
                        sender == "user" ? TextAlign.right : TextAlign.left,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(labelText: "Type a message..."),
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
