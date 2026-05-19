import 'package:googleai_dart/googleai_dart.dart';
import 'llm_service.dart';

class GeminiService implements LLMService {
  @override
  Future<String> getFinancialInsights(String casJson, String apiKey) async {
    final client = GoogleAIClient.withApiKey(apiKey);

    final prompt = _buildPrompt(casJson);

    try {
      final response = await client.models.generateContent(
        request: GenerateContentRequest(
          contents: [
            Content.text(prompt),
          ],
        ), model: 'gemini-2.5-flash',
      );

      //final text = response.candidates?.first.content?.parts?.first.text;
      final text=response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }
      return text;
    } catch (e) {
      throw Exception('Gemini Analysis Failed: ${e.toString()}');
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
