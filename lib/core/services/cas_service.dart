import 'dart:convert';
import 'package:dio/dio.dart';
import '../env/env.dart';

class CASService {
  final Dio _dio = Dio();

  /// Parses the CAS PDF file using the casparser.in API.
  /// Returns the parsed data as a JSON string.
  Future<String> parseCAS(String? filePath, String? panNumber) async {
    if (filePath == null) {
      throw Exception('PDF file is required for parsing.');
    }
    if (panNumber == null || panNumber.isEmpty) {
      throw Exception('PAN number is required as the PDF password.');
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'password': panNumber,
      });

      return await _postToCASAPI(formData);
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message;
      throw Exception('CAS Parsing Error: $errorMsg');
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Parses the CAS PDF from a URL using the casparser.in API.
  /// Returns the parsed data as a JSON string.
  Future<String> parseCASFromUrl(String? pdfUrl, String? panNumber) async {
    if (pdfUrl == null || pdfUrl.isEmpty) {
      throw Exception('PDF URL is required for parsing.');
    }
    if (panNumber == null || panNumber.isEmpty) {
      throw Exception('PAN number is required as the PDF password.');
    }

    try {
      final formData = FormData.fromMap({
        'pdf_url': pdfUrl,
        'password': panNumber,
      });

      return await _postToCASAPI(formData);
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message;
      throw Exception('CAS Parsing Error: $errorMsg');
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<String> _postToCASAPI(FormData formData) async {
    final response = await _dio.post(
      'https://api.casparser.in/v4/smart/parse',
      data: formData,
      options: Options(
        headers: {
          'x-api-key': Env.prodCASAPIKey,
        },
      ),
    );
    if (response.statusCode == 200) {
      return jsonEncode(response.data);
    } else {
      throw Exception('Failed to parse CAS: ${response.statusMessage}');
    }
  }

  /// Fetches raw JSON content from a URL.
  Future<String> getJsonFromUrl(String url) async {
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        if (response.data is String) {
          return response.data;
        } else {
          return jsonEncode(response.data);
        }
      } else {
        throw Exception('Failed to fetch JSON: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error fetching JSON from URL: $e');
    }
  }
}
