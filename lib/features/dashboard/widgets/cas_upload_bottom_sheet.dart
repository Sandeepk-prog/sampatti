import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../profile/providers/ai_configuration_provider.dart';
import '../providers/ai_insight_provider.dart';

class CASUploadBottomSheet extends StatefulWidget {
  const CASUploadBottomSheet({super.key});

  @override
  State<CASUploadBottomSheet> createState() => _CASUploadBottomSheetState();
}

class _CASUploadBottomSheetState extends State<CASUploadBottomSheet> {
  final TextEditingController _panController = TextEditingController();
  String? _panError;
  String? _fileError;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AIInsightProvider>(context, listen: false);
    _panController.text = provider.panNumber ?? '';
  }

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  void _validatePan(String value) {
    final provider = Provider.of<AIInsightProvider>(context, listen: false);
    provider.setPan(value);
    setState(() {
      if (value.isEmpty) {
        _panError = null;
      } else if (!provider.isPanValid) {
        _panError = "Invalid PAN format (e.g., ABCDE1234F)";
      } else {
        _panError = null;
      }
    });
  }

  Future<void> _pickFile() async {
    final provider = Provider.of<AIInsightProvider>(context, listen: false);
    final isJson = provider.selectedFileType == UploadFileType.json;
    
    try {
      // Using FileType.any to avoid platform-specific issues where JSON/CSV is 
      // ignored when using FileType.custom.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
 
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final extension = file.extension?.toLowerCase() ?? 
                         file.path?.split('.').last.toLowerCase();
        
        // Manual validation for extension
        if ((isJson && extension == 'json') || (!isJson && extension == 'pdf')) {
          if (mounted) {
            provider.setFile(file);
            setState(() => _fileError = null);
          }
        } else {
          setState(() => _fileError = "Selected file is not a valid ${isJson ? 'JSON' : 'PDF'} file.");
        }
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
      setState(() => _fileError = "Error selecting file. Please ensure app has storage permissions.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Consumer<AIInsightProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upload Statement',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your file type and upload the statement to generate AI insights.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              
              // File Type Selector
              Row(
                children: [
                  Expanded(
                    child: _FileTypeButton(
                      title: 'PDF (CAS)',
                      isSelected: provider.selectedFileType == UploadFileType.pdf,
                      onTap: () => provider.setSelectedFileType(UploadFileType.pdf),
                      icon: LucideIcons.fileText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FileTypeButton(
                      title: 'JSON',
                      isSelected: provider.selectedFileType == UploadFileType.json,
                      onTap: () => provider.setSelectedFileType(UploadFileType.json),
                      icon: LucideIcons.fileCode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // PAN Input (Only for PDF)
              if (provider.selectedFileType == UploadFileType.pdf) ...[
                Text(
                  'PAN Number',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _panController,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: _validatePan,
                  decoration: InputDecoration(
                    hintText: 'ABCDE1234F',
                    hintStyle: TextStyle(color: Colors.grey[300]),
                    errorText: _panError,
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
              ],

              // File Upload
              Text(
                provider.selectedFileType == UploadFileType.pdf 
                    ? 'CAS Statement (PDF)' 
                    : 'Statement (JSON)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (provider.pickedFile == null)
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _fileError != null ? AppColors.error.withOpacity(0.5) : AppColors.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.fileUp, size: 32, color: AppColors.primary),
                        const SizedBox(height: 12),
                        Text(
                          'Drag & drop or Choose File',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.selectedFileType==UploadFileType.json ? 'Only JSON files accepted' : 'Only PDF files accepted',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_fileError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _fileError!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      if (provider.isUploadingFile)
                        const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (provider.uploadedFileUrl != null)
                        const Icon(LucideIcons.circleCheck, color: AppColors.success, size: 20)
                      else
                        const Icon(LucideIcons.fileText, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.pickedFile!.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(provider.pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => provider.setFile(null),
                        icon: const Icon(LucideIcons.x, size: 18, color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: ((provider.selectedFileType == UploadFileType.json || provider.isPanValid) &&
                          provider.uploadedFileUrl != null &&
                          !provider.isUploadingFile &&
                          provider.uploadStatus != CASUploadStatus.uploading)
                      ? () async {
                          final aiConfig = Provider.of<AIConfigurationProvider>(context, listen: false);
                          await provider.uploadCAS(aiConfig.selectedProvider, aiConfig.currentKey);
                          if (mounted && provider.uploadStatus == CASUploadStatus.uploaded) {
                            if(context.mounted) {
                              Navigator.pop(context); // Close the bottom sheet
                              context.go("/demat_demat");//Navigates to Demat screen
                            }// Navigate to the home screen
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: provider.uploadStatus == CASUploadStatus.uploading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Generate Insights',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (provider.errorMessage != null && provider.uploadStatus == CASUploadStatus.error) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    provider.errorMessage!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        );
      },
    );

    return provider;
  }
}

class _FileTypeButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const _FileTypeButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
