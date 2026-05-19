import 'package:dart_openai/dart_openai.dart';
import 'llm_service.dart';

class OpenAIService implements LLMService {
  @override
  Future<String> getFinancialInsights(String casJson, String apiKey) async {
    OpenAI.apiKey =apiKey;
    
    final prompt = _buildPrompt(casJson);
    
    try {
      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4-turbo-preview",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );

      final text = chatCompletion.choices.first.message.content?.first.text;
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from OpenAI');
      }
      return text;
    } catch (e) {
      throw Exception('OpenAI Analysis Failed: ${e.toString()}');
    }
  }

  String _buildPrompt(String casJson) {
    return '''
Role:
You are a financial analyst. Analyze the given CAS (Consolidated Account Statement) JSON data and generate concise investment insights.

Input:
$casJson

Instructions:
- Respond ONLY if valid data is present; otherwise return:
  "Invalid or insufficient CAS data to generate insights."
- Output must be in plain text.
- Each insight must include:
  • title (short and clear)
  • summary (1–2 lines, concise and actionable)
- Avoid verbosity. Be professional and precise.

Insights to Generate:
1. Portfolio Overview – Investment distribution and coverage
2. Risk Assessment – Diversification and risk exposure
3. Performance Insights – Key trends or strengths
4. Improvement Areas – Gaps or inefficiencies
5. Future Recommendations – Actionable steps for better returns

Output Format (strict):
[
  {"title": "<title>", "summary": "<summary>"},
  {"title": "<title>", "summary": "<summary>"},
  {"title": "<title>", "summary": "<summary>"},
  {"title": "<title>", "summary": "<summary>"},
  {"title": "<title>", "summary": "<summary>"}
]
''';
  }
}
