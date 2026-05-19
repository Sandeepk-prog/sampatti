import 'dart:convert';
import 'package:googleai_dart/googleai_dart.dart';

class LlmParserException implements Exception {
  final String message;
  LlmParserException(this.message);

  @override
  String toString() => message;
}

class LlmParserService {
  final String apiKey;
  
  LlmParserService(this.apiKey);

  /// Parses the raw text extracted from a bank statement PDF and returns a list of transactions as maps.
  Future<List<Map<String, dynamic>>> parseTransactionsFromText(String extractedText) async {
    if (extractedText.trim().isEmpty) {
      throw LlmParserException(
        "No text could be extracted from the PDF. It might be a scanned image without OCR support.",
      );
    }
    
    // Rudimentary check for extremely large texts that might exceed context limits
    // Assuming roughly 4 chars per token. Let's set a soft limit of roughly 400,000 chars (~100k tokens)
    // Gemini 1.5 Flash supports 1-2 million tokens, but older models or free tiers might be lower.
    // For now, this is a reasonable safeguard.
    if (extractedText.length > 500000) {
      throw LlmParserException(
        "The uploaded bank statement is too large to process at once. Please upload a shorter statement.",
      );
    }

    final client = GoogleAIClient.withApiKey(apiKey);
    final prompt = _buildPrompt(extractedText);

    try {
      final response = await client.models.generateContent(
        request: GenerateContentRequest(
          contents: [
            Content.text(prompt),
          ],
          // Using gemini-1.5-flash as it's the fast model used elsewhere in the codebase
        ), 
        model: 'gemini-1.5-flash',
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw LlmParserException('Empty response received from the AI parser.');
      }

      return _extractJsonFromResponse(text);
      
    } catch (e) {
      if (e is LlmParserException) {
        rethrow;
      }
      throw LlmParserException('AI Parsing Failed: ${e.toString()}');
    }
  }

  String _buildPrompt(String pdfText) {
    return '''
Extract only transaction table data from the input text.

Columns:
- sl_no
- date
- remarks
- withdrawal_amount
- deposit_amount
- balance

Rules:
- Ignore non-tabular content.
- Each row = one transaction.
- Preserve order.
- If a value is missing, use 0.00.
- Output only valid JSON array.
- No explanations.

Return format:
[
  {
    "sl_no": number,
    "date": "DD.MM.YYYY",
    "remarks": string,
    "withdrawal_amount": number,
    "deposit_amount": number,
    "balance": number
  }
]

Input Text:
$pdfText
''';
  }

  List<Map<String, dynamic>> _extractJsonFromResponse(String responseText) {
    try {
      String jsonStr = responseText.trim();
      
      // Sometimes LLMs wrap JSON in markdown blocks
      if (jsonStr.contains('```json')) {
        final start = jsonStr.indexOf('```json') + 7;
        final end = jsonStr.lastIndexOf('```');
        if (start != -1 && end != -1 && end > start) {
          jsonStr = jsonStr.substring(start, end).trim();
        }
      } else if (jsonStr.contains('```')) {
        final start = jsonStr.indexOf('```') + 3;
        final end = jsonStr.lastIndexOf('```');
        if (start != -1 && end != -1 && end > start) {
           jsonStr = jsonStr.substring(start, end).trim();
        }
      }
      
      // Fallback: extract substring between first [ and last ]
      if (!jsonStr.startsWith('[')) {
        final startIdx = jsonStr.indexOf('[');
        final endIdx = jsonStr.lastIndexOf(']');
        if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
          jsonStr = jsonStr.substring(startIdx, endIdx + 1);
        }
      }

      final parsedList = jsonDecode(jsonStr);

      
      if (parsedList is! List) {
        throw LlmParserException("AI returned JSON, but it is not an array format.");
      }
      
      // Convert mapping and ensure schema validity
      return parsedList.map((item) {
        if (item is Map<String, dynamic>) {
          return {
            's_no': item['sl_no'] is int ? item['sl_no'] : int.tryParse(item['sl_no'].toString()) ?? 0,
            'date': item['date']?.toString() ?? '',
            'description': item['remarks']?.toString() ?? 'Bank Transaction',
            'debit': _parseDouble(item['withdrawal_amount']),
            'credit': _parseDouble(item['deposit_amount']),
            'balance': _parseDouble(item['balance']),
          };
        }
        return <String, dynamic>{};
      }).where((element) => element.isNotEmpty).toList();

    } catch (e) {
      if (e is LlmParserException) rethrow;
      throw LlmParserException("Failed to decode AI response into JSON. Data might be malformed.");
    }
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
    }
    return 0.0;
  }
}
