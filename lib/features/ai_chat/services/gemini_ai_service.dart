import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiAiService {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  GeminiAiService(String userContext) {
    // Read from .env file
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    
    if (apiKey.isEmpty) {
      print('Warning: GEMINI_API_KEY is missing in .env!');
    }

    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
      systemInstruction: Content.system(
        "You are ExpertMoney AI, an intelligent financial assistant integrated into a budgeting app. "
        "Your role is to offer financial advice, help users save and manage their money. "
        "Always answer in a friendly, short, and concise manner. Do not provide advice on topics other than money, finance, budgets, and savings.\n\n"
        "Here is the real financial context of the user you are talking to now:\n"
        "$userContext"
      ),
    );

    _chatSession = _model.startChat();
  }

  Future<String> getResponse(String message) async {
    try {
      final response = await _chatSession.sendMessage(Content.text(message));
      return response.text ?? "I'm sorry, I couldn't generate a response.";
    } catch (e) {
      return "Connection error to the AI server. Please try again.";
    }
  }
}
