import 'dart:io';
import 'package:flutter/services.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import '../models/transaction_model.dart';

/// Service class to handle PDF parsing of bank statements.
class PDFParser {
  /// Parses a bank statement PDF file and returns a list of transactions as maps.
  /// 
  /// The [file] must be a valid PDF file. Returns an empty list if parsing fails.
  static Future<List<Map<String, dynamic>>> parseBankStatement(File file) async {
    try {
      if (!file.existsSync()) {
        throw Exception("File not found at path: ${file.path}");
      }

      // Extract text content using read_pdf_text
      String text = "";
      try {
        text = await ReadPdfText.getPDFtext(file.path);
        for(var data in text.split('\n')){
        print("PDF Line: $data");
        }
        print("PDF Parser: Successfully extracted text from PDF." +text);
      } on PlatformException catch (e) {
        print("PDF Parser Error (Platform): ${e.message}");
        return [];
      } catch (e) {
        print("PDF Parser Error (Extraction): $e");
        return [];
      }
      
      if (text.isEmpty) {
        print("PDF Parser: No text content found in PDF.");
        return [];
      }


      // Extract and convert transactions to JSON

      return _extractTransactions(text)
          .map((tx) => tx.toJson())
          .toList();
    } catch (e) {
      print("PDF Parser Error: $e");
      // Basic error handling - could be expanded to report specific issues to UI
      return [];
    }
  }

  /// Extracts transaction rows from the raw text using regex heuristics.
  static List<Transaction> _extractTransactions(String text) {
    List<Transaction> transactions = [];

      parseStatement(text);

    // Split text into lines for processing
    final lines = text.split('\n');
   // print("PDF data:" +lines);

    // Regex patterns for bank statement identification
    // Most Indian bank statements use DD/MM/YYYY or DD-MM-YYYY
    final dateRegex = RegExp(r'\b\d{2}[/-]\d{2}[/-]\d{4}\b');
    
    // Amount regex: Handles comma separators and decimal points (e.g., 1,234.56 or 1234.56)
    final amountRegex = RegExp(r'\d{1,3}(,\d{3})*(\.\d{2})');

    for (var line in lines) {
      try {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        // Skip lines that don't contain a date (likely not a transaction row)
        if (!dateRegex.hasMatch(trimmedLine)) continue;

        final dateMatch = dateRegex.firstMatch(trimmedLine);
        if (dateMatch == null) continue;

        String date = dateMatch.group(0)!;

        // Find all sequences that look like amounts
        final amountMatches = amountRegex.allMatches(trimmedLine).toList();
        final amountsStrings = amountMatches.map((m) => m.group(0)!).toList();

        // A transaction row typically has at least a transaction amount and a balance
        if (amountsStrings.length < 2) continue;

        // Clean and parse amounts to doubles
        List<double> parsedAmounts = amountsStrings
            .map((a) => double.tryParse(a.replaceAll(',', '')) ?? 0.0)
            .toList();

        // Heuristic mapping of amounts to columns:
        // Case 1: 2 amounts found -> [Debit/Credit, Balance]
        // Case 2: 3+ amounts found -> [Debit, Credit, Balance] (ignores extra intermediate amounts)
        
        double debit = 0.0;
        double credit = 0.0;
        double balance = parsedAmounts.last;

        if (parsedAmounts.length == 2) {
          // It's ambiguous if the first amount is debit or credit without more context
          // but we'll assume it's an outbound amount (debit) if it's the only one present
          // before the balance.
          debit = parsedAmounts[0];
        } else {
          // More granular bank statements have separate columns
          debit = parsedAmounts[0];
          credit = parsedAmounts[1];
        }

        // Extract description: everything else in the line
        String description = trimmedLine;
        
        // Remove date
        description = description.replaceFirst(date, '');
        
        // Remove the specific amount strings we extracted (to avoid greedy removal of other numbers)
        for (var amtStr in amountsStrings) {
          description = description.replaceFirst(amtStr, '');
        }
        
        // Clean up whitespace/remaining chars
        description = description.trim();
        if (description.isEmpty) description = "Bank Transaction";

        transactions.add(Transaction(
          date: date,
          description: description,
          debit: debit,
          credit: credit,
          balance: balance,
        ));
      } catch (e) {
        // Log individual row failure but continue parsing others
        print("PDF Parser: Skipping malformed row: $line. Error: $e");
        continue;
      }
    }

    print("PDF Parser: Successfully extracted ${transactions.length} transactions.");
    return transactions;
  }
  static Map<String, dynamic>? parseTransaction(String line) {
    // Normalize spacing (important for PDF text)
    line = line.replaceAll(RegExp(r'\s+'), ' ').trim();

    final regex = RegExp(
        r'^\s*(\d+)\s+(\d{2}\.\d{2}\.\d{4})\s+(.+?)\s+([\d,]+\.\d{2})\s+([\d,]+\.\d{2})\s+([\d,]+\.\d{2})\s*$'
    );

    final match = regex.firstMatch(line);
    if (match == null) return null;

    double withdrawal = double.parse(match.group(4)!.replaceAll(',', ''));
    double deposit   = double.parse(match.group(5)!.replaceAll(',', ''));
    double balance   = double.parse(match.group(6)!.replaceAll(',', ''));
    print("Parsed Transaction - S.No: ${match.group(1)}, Date: ${match.group(2)}, Description: ${match.group(3)}, Withdrawal: $withdrawal, Deposit: $deposit, Balance: $balance");

    return {
      "s_no": int.parse(match.group(1)!),
      "date": match.group(2),
      "remarks": match.group(3)?.trim(),

      "withdrawal": withdrawal,
      "deposit": deposit,
      "balance": balance,

      // Optional derived field (useful for UI/insights)
      "type": withdrawal > 0 ? "debit" : "credit",
      "amount": withdrawal > 0 ? withdrawal : deposit,
    };
  }

  static void parseStatement(String text) {
    final pattern = RegExp(
        r'(\d+)\s+(\d{2}\.\d{2}\.\d{4})\s+([A-Z]{2}\/[A-Z0-9]+)\s+([\d.]+)\s+([\d.]+)'
    );

    final match = pattern.firstMatch(text);

    if (match != null) {
      String txnId = match.group(1)!;
      String date = match.group(2)!;
      String reference = match.group(3)!;
      String amount = match.group(4)!;
      String balance = match.group(5)!;

      print('Transaction ID: $txnId');
      print('Date: $date');
      print('Reference: $reference');
      print('Amount: $amount');
      print('Balance: $balance');
    } else {
      print('No match found');
    }
  }


}
