import '../../features/profile/providers/ai_configuration_provider.dart';
import 'llm_service.dart';
import 'gemini_service.dart';
import 'openai_service.dart';

class LLMServiceFactory {
  static LLMService getService(AIProvider provider) {
    switch (provider) {
      case AIProvider.gemini:
        return GeminiService();
      case AIProvider.openai:
        return OpenAIService();
    }
  }
}
