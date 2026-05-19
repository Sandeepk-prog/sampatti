import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/cas_service.dart';
import '../../../core/services/cas_parser.dart';
import '../../../core/services/llm_service_factory.dart';
import '../../profile/providers/ai_configuration_provider.dart';
import '../models/insight_data.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/user_service.dart';

enum CASUploadStatus { none, uploading, uploaded, error }
enum AIInsightState { none, generating, ready, error }
enum UploadFileType { pdf, json }

class AIInsightProvider extends ChangeNotifier {
  final CASService _casService = CASService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final UserService _userService = UserService();
  
  AuthProvider? _authProvider;

  void update(AuthProvider authProvider) {
    _authProvider = authProvider;
  }
  
  CASUploadStatus _uploadStatus = CASUploadStatus.none;
  AIInsightState _insightState = AIInsightState.none;
  List<InsightData> _insights = [];
  DateTime? _lastUploadTime;
  String? _errorMessage;
  String? _lastParsedJson;
  UploadFileType _selectedFileType = UploadFileType.pdf;

  CASUploadStatus get uploadStatus => _uploadStatus;
  AIInsightState get insightState => _insightState;
  List<InsightData> get insights => _insights;
  DateTime? get lastUploadTime => _lastUploadTime;
  String? get errorMessage => _errorMessage;
  UploadFileType get selectedFileType => _selectedFileType;

  void setSelectedFileType(UploadFileType type) {
    _selectedFileType = type;
    _pickedFile = null;
    _uploadedFileUrl = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchUserInsights() async {
    if (_authProvider?.user == null) return;
    
    try {
      final user = await _userService.getUser(_authProvider!.user!.id);
      if (user != null && user.insights != null && user.insights!.isNotEmpty) {
        _insights = user.insights!;
        _lastUploadTime = user.lastUpdated;
        _insightState = AIInsightState.ready;
        _uploadStatus = CASUploadStatus.uploaded; // Set this so UI doesn't show Upload button
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching insights from Firestore: $e");
    }
  }

  String? _panNumber;
  PlatformFile? _pickedFile;
  bool _isPanValid = false;

  String? get panNumber => _panNumber;
  PlatformFile? get pickedFile => _pickedFile;
  bool get isPanValid => _isPanValid;

  bool _isUploadingFile = false;
  String? _uploadedFileUrl;

  bool get isUploadingFile => _isUploadingFile;
  String? get uploadedFileUrl => _uploadedFileUrl;

  Future<void> _uploadFileToCloudinary() async {
    if (_pickedFile == null || _pickedFile!.path == null) return;
    
    _isUploadingFile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("Picked file path: ${_pickedFile!.path!}");
      _uploadedFileUrl = await _cloudinaryService.uploadFile(_pickedFile!.path!);
      print("Uploaded File Url: $_uploadedFileUrl");

      // Sync to Firestore if user is logged in
      if (_uploadedFileUrl != null && _authProvider?.user != null) {
        try {
          final fileType = _selectedFileType == UploadFileType.json ? 'json' : 'pdf';
          await _userService.updateCasUrl(_authProvider!.user!.id, _uploadedFileUrl!, fileType);
          print("Firestore updated with CAS URL and type: $fileType");
          
          // Refresh user profile to ensure latest casUrl is available globally
          await _authProvider?.refreshUser();
        } catch (firestoreError) {
          print("Failed to update Firestore with CAS URL: $firestoreError");
          // We don't set error message here to avoid confusing the user 
          // if the file was actually uploaded successfully to Cloudinary.
        }
      }
    } catch (e) {
      _errorMessage = "Failed to upload file to Cloudinary: ${e.toString().replaceAll('Exception: ', '')}";
      _uploadedFileUrl = null;
    } finally {
      _isUploadingFile = false;
      notifyListeners();
    }
  }

  void setPan(String pan) {
    _panNumber = pan.toUpperCase();
    _isPanValid = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(_panNumber!);
    notifyListeners();
  }

  void setFile(PlatformFile? file) {
    _pickedFile = file;
    _uploadedFileUrl = null;
    if (_pickedFile != null && !_isUploadingFile) {
      print("Uploading it to Cloudinary....");
      _uploadFileToCloudinary();
    }
    notifyListeners();
  }

  Future<void> uploadCAS(AIProvider provider, String apiKey) async {
    if (_pickedFile == null || (_selectedFileType == UploadFileType.pdf && !_isPanValid)) return;
    _uploadStatus = CASUploadStatus.uploading;
    _errorMessage = null;
    notifyListeners();

    try {
      final String rawCasJson;
      
      if (_selectedFileType == UploadFileType.json) {
        // Direct JSON upload: Read the file content
        if (_pickedFile!.path != null) {
          final file = File(_pickedFile!.path!);
          rawCasJson = await file.readAsString();
        } else if (_pickedFile!.bytes != null) {
          rawCasJson = utf8.decode(_pickedFile!.bytes!);
        } else {
          throw Exception("Could not read JSON file content.");
        }
        print("Using direct JSON upload, length: ${rawCasJson.length}");
      } else {
        // PDF upload: Parse via CAS Service
        if (_uploadedFileUrl != null) {
          print("Parsing CAS from URL: $_uploadedFileUrl");
          rawCasJson = await _casService.parseCASFromUrl(_uploadedFileUrl, _panNumber);
        } else {
          print("Parsing CAS from local file: ${_pickedFile?.path}");
          rawCasJson = await _casService.parseCAS(_pickedFile?.path, _panNumber);
        }
      }
      
      _lastParsedJson = rawCasJson;
      _uploadStatus = CASUploadStatus.uploaded;
      _lastUploadTime = DateTime.now();
      
      // 2. Generate insights using the parsed JSON
      await generateInsights(provider, apiKey);
    } catch (e) {
      _uploadStatus = CASUploadStatus.error;
      _errorMessage = e.toString().contains('Exception:') 
          ? e.toString().replaceAll('Exception: ', '') 
          : e.toString();
    }
    notifyListeners();
  }

  Future<void> generateInsights(AIProvider provider, String apiKey, [String? casJson]) async {
    final jsonToUse = casJson ?? _lastParsedJson;
    if (jsonToUse == null) {
      _errorMessage = "No parsed CAS data available. Please upload again.";
      notifyListeners();
      return;
    }

    _insightState = AIInsightState.generating;
    _errorMessage = null;
    //notifyListeners();

    try {
      final llmService = LLMServiceFactory.getService(provider);
      final rawInsights = await llmService.getFinancialInsights(jsonToUse??"", apiKey);

      print("LLM Response:" +jsonToUse);
      _insights = _parseInsights(rawInsights);
      _insightState = AIInsightState.ready;
      
      // Save insights to Firestore if user is logged in
      if (_insights.isNotEmpty && _authProvider?.user != null) {
        try {
          _lastUploadTime = await _userService.updateInsights(_authProvider!.user!.id, _insights);
          print("Insights saved to Firestore");
        } catch (firestoreError) {
          print("Failed to save insights to Firestore: $firestoreError");
        }
      }
    } catch (e) {
      _insightState = AIInsightState.error;
      _errorMessage = e.toString().contains('Exception:') 
          ? e.toString().replaceAll('Exception: ', '') 
          : e.toString();
    }


    notifyListeners();
  }

  Future<void> refreshInsights(String password, AIProvider provider, String apiKey) async {
    if (_authProvider?.user == null) {
      _errorMessage = "User not logged in.";
      notifyListeners();
      return;
    }

    final casUrl = _authProvider!.user!.casUrl;
    if (casUrl == null || casUrl.isEmpty) {
      _errorMessage = "No CAS file found to refresh. Please upload one first.";
      notifyListeners();
      return;
    }

    _insightState = AIInsightState.generating;
    _uploadStatus = CASUploadStatus.uploading;
    _errorMessage = null;
    notifyListeners();

    try {
      final String rawCasJson;
      // 1. Check the stored file type from the user profile
      final isJsonType = _authProvider!.user!.casFileType == 'json';
      
      if (isJsonType) {
        print("Refreshing direct JSON from URL: $casUrl");
        final response = await _casService.getJsonFromUrl(casUrl);
        rawCasJson = response;
      } else {
        print("Refreshing CAS from URL: $casUrl");
        rawCasJson = await _casService.parseCASFromUrl(casUrl, password);
      }
      
      _lastParsedJson = rawCasJson;
      _uploadStatus = CASUploadStatus.uploaded;
      
      // 3. Generate insights
      await generateInsights(provider, apiKey, rawCasJson);
    } catch (e) {
      _insightState = AIInsightState.error;
      _uploadStatus = CASUploadStatus.error;
      _errorMessage = e.toString().contains('Exception:') 
          ? e.toString().replaceAll('Exception: ', '') 
          : e.toString();
      notifyListeners();
    }
  }

  List<InsightData> _parseInsights(String rawInsights) {
    // Parser to convert formatted response to InsightData list
    // Expected format: "- Title: Summary"
    if (rawInsights.contains("Invalid or insufficient CAS data")) {
      return [
        InsightData(
          title: "Incomplete Data",
          subtitle: "Provide a valid CAS statement for deeper analysis.",
          iconCodePoint: LucideIcons.circleAlert.codePoint,
          bgColorHex: "0xFFFFF3E0",
          iconColorHex: "0xFFFF9800",
        )
      ];
    }

    print("RAW INSIGHT:" +rawInsights);

    final List<InsightData> parsedInsights = [];
    
    try {
      // Find the start and end of the JSON array
      final startIndex = rawInsights.indexOf('[');
      final endIndex = rawInsights.lastIndexOf(']');
      
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonString = rawInsights.substring(startIndex, endIndex + 1);
        final List<dynamic> decodedList = jsonDecode(jsonString);
        
        for (var item in decodedList) {
          if (item is Map<String, dynamic>) {
            final title = item['title']?.toString() ?? '';
            final summary = item['summary']?.toString() ?? '';
            
            if (title.isNotEmpty && summary.isNotEmpty) {
              print("AI Insight title:" +title);
              parsedInsights.add(
                InsightData(
                  title: title,
                  subtitle: summary,
                  iconCodePoint: LucideIcons.sparkles.codePoint,
                  bgColorHex: "0xFFF3E5F5",
                  iconColorHex: "0xFF9C27B0",
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print("JSON parsing error: \$e");
    }

    if (parsedInsights.isEmpty && rawInsights.isNotEmpty) {
      // Fallback if parsing fails or formatting is slightly off but we have text
      parsedInsights.add(
        InsightData(
          title: "AI Analysis",
          subtitle: rawInsights.length > 300 ? "\${rawInsights.substring(0, 300)}..." : rawInsights,
          iconCodePoint: LucideIcons.sparkles.codePoint,
          bgColorHex: "0xFFF3E5F5",
          iconColorHex: "0xFF9C27B0",
        ),
      );
    }
    
    return parsedInsights;
  }

  void reset() {
    _uploadStatus = CASUploadStatus.none;
    _insightState = AIInsightState.none;
    _insights = [];
    _lastUploadTime = null;
    _errorMessage = null;
    _isUploadingFile = false;
    _uploadedFileUrl = null;
    _pickedFile = null;
    _panNumber = null;
    _isPanValid = false;
    notifyListeners();
  }
}
