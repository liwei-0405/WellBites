import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/gemini_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final GeminiService geminiService = GeminiService();
  List<Map<String, String>> chatMessages = [];
  final ScrollController _scrollController = ScrollController();

  //initial message
  @override
  void initState() {
    super.initState();
    _introduceAI();
  }

  void _introduceAI() async {
    setState(() {
      chatMessages.add({
        "bot":
            "👋 Hello! I'm Gemini, your personal health assistant. Let me check your data... 🔍",
      });
    });

    Map<String, dynamic>? userData = await geminiService.getUserData();
    if (userData != null) {
      double height =
          double.tryParse(userData["height"]?.toString() ?? "0") ?? 0;
      double weight =
          double.tryParse(userData["weight"]?.toString() ?? "0") ?? 0;
      double bmi =
          (height > 0) ? weight / ((height / 100) * (height / 100)) : 0;
      String bmiCategory = _getBMICategory(bmi);

      String introMessage = """
✅ Here is your basic health data:
- **Height:** ${userData['height']} cm
- **Weight:** ${userData['weight']} kg
- **BMI:** ${bmi.toStringAsFixed(1)} ($bmiCategory)
- **Main Goal:** ${userData['main_goals']}
- **Dietary Restrictions:** ${userData['dietary_restrictions']}
- **Health Conditions:** ${userData['health_conditions']}

💡 Feel free to ask me anything about your health or nutrition!
""";

      setState(() {
        chatMessages.add({"bot": introMessage});
      });
    } else {
      setState(() {
        chatMessages.add({
          "bot":
              "❌ I couldn't fetch your data. Please check if your profile is complete.",
        });
      });
    }

    _scrollToBottom();
  }

  String _getBMICategory(double bmi) {
    if (bmi == 0) return "Unknown";
    if (bmi < 18.5) return "Underweight";
    if (bmi < 24.9) return "Normal weight";
    if (bmi < 29.9) return "Overweight";
    return "Obese";
  }

  void sendMessage() async {
    String message = messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        chatMessages.add({"user": message});
        messageController.clear();
        chatMessages.add({"bot": "Processing..."});
      });
      _scrollToBottom();
      String response = await geminiService.getAIResponse(message);
      setState(() {
        chatMessages.removeLast();
        chatMessages.add({"bot": response});
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gemini AI")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                String sender = chatMessages[index].keys.first;
                String text = chatMessages[index][sender]!;
                bool isUser = sender == "user";

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.lightBlue[200] : Colors.blue[700],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                      bottomLeft:
                          isUser ? Radius.circular(15) : Radius.circular(0),
                      bottomRight:
                          isUser ? Radius.circular(0) : Radius.circular(15),
                    ),
                  ),
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: MarkdownBody(
                    data: text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser ? Colors.blue[900] : Colors.white,
                        fontSize: 16,
                      ),
                      strong: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                    onSubmitted: (text) {
                      sendMessage();
                    },
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
