import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:finsight/core/services/cas_parser.dart';

void main() {
  group('CASParser Tests', () {
    test('compress should simplify raw CAS JSON', () {
      final Map<String, dynamic> sampleRaw = {
        "summary": {
          "total_value": 100000.0,
          "accounts": {
            "demat": {"total_value": 60000.0},
            "mutual_funds": {"total_value": 30000.0},
            "insurance": {"total_value": 5000.0},
            "nps": {"total_value": 5000.0}
          }
        },
        "demat_accounts": [
          {
            "holdings": {
              "equities": [
                {"name": "Reliance", "value": 40000.0},
                {"name": "HDFC Bank", "value": 20000.0}
              ]
            }
          }
        ],
        "mutual_funds": [
          {
            "amc": "SBI Mutual Fund",
            "value": 30000.0,
            "schemes": [
              {"name": "SBI Bluechip", "value": 30000.0}
            ]
          }
        ]
      };

      final rawJson = jsonEncode(sampleRaw);
      final compressedJson = CASParser.compress(rawJson);
      final Map<String, dynamic> compressed = jsonDecode(compressedJson);

      expect(compressed["total"], 100000);
      expect(compressed["alloc"]["eq"], 60);
      expect(compressed["alloc"]["debt"], 30);
      expect(compressed["alloc"]["oth"], 10);
      expect(compressed["amc"][0]["n"], "SBI Mutual Fund");
      expect(compressed["amc"][0]["p"], 30);
      expect(compressed["top"].length, 3); // Reliance, HDFC Bank, SBI Bluechip
    });

    test('compress should handle empty input', () {
      final rawJson = "{}";
      final compressedJson = CASParser.compress(rawJson);
      expect(compressedJson, "{}");
    });

    test('compress should handle invalid JSON', () {
      final rawJson = "invalid-json";
      final compressedJson = CASParser.compress(rawJson);
      expect(compressedJson, "invalid-json");
    });
  });
}
