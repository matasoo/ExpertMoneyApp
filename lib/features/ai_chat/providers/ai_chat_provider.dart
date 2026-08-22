import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/chat_message.dart';
import '../services/gemini_ai_service.dart';
import '../../setup/providers/setup_provider.dart';
import '../../dashboard/providers/transactions_provider.dart';

class AiChatState {
  final List<ChatMessage> messages;
  final bool isTyping;

  AiChatState({required this.messages, this.isTyping = false});

  AiChatState copyWith({List<ChatMessage>? messages, bool? isTyping}) {
    return AiChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class AiChatNotifier extends Notifier<AiChatState> {
  final _uuid = const Uuid();
  late final GeminiAiService _aiService;

  @override
  AiChatState build() {
    final setup = ref.read(setupProvider);
    final transactions = ref.read(transactionsProvider);

    String context = "Monthly income: ${setup.monthlyIncome} RON.\n";
    context += "Total fixed costs: ${setup.totalFixedCosts} RON.\n";
    context += "Main goal: ${setup.mainGoal}.\n";
    
    if (transactions.isNotEmpty) {
      context += "Recent transactions:\n";
      for (int i = 0; i < (transactions.length > 15 ? 15 : transactions.length); i++) {
        final t = transactions[i];
        final type = t.isExpense ? "Expense" : "Income";
        context += "- $type of ${t.amount} RON for '${t.title}' (${t.category})\n";
      }
    } else {
      context += "No recent transactions.\n";
    }

    _aiService = GeminiAiService(context);
    return AiChatState(messages: [
      ChatMessage(
        id: const Uuid().v4(),
        text: 'Hello! I am ExpertMoney AI. I have analyzed your current financial situation. How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      )
    ]);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
    );

    // Get AI response
    try {
      final responseText = await _aiService.getResponse(text);
      
      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isTyping: false,
      );
    } catch (e) {
      final errorMsg = ChatMessage(
        id: _uuid.v4(),
        text: 'A apărut o eroare de conexiune. Te rugăm să încerci din nou.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isTyping: false,
      );
    }
  }
}

final aiChatProvider = NotifierProvider<AiChatNotifier, AiChatState>(() {
  return AiChatNotifier();
});
