import 'package:google_generative_ai/google_generative_ai.dart';
import '../secrets.dart';

class GeminiService {
  final GenerativeModel model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: Secrets.geminiApiKey,
  );

  Future<String> getAIResponse(String userInput) async {
    try {
      final content = Content.text(userInput);
      final response = await model.generateContent([content]);
      return response.text ?? "AI could not generate a response.";
    } catch (e) {
      return "Error: $e";
    }
  }
}
