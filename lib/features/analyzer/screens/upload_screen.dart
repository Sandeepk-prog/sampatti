import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/bank_analyzer_provider.dart';
import '../../profile/providers/ai_configuration_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/ai_config_helper.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    
    _controller.forward();
    
    // Listen for AI configuration and initial error state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiConfig = context.read<AIConfigurationProvider>();
      if (!aiConfig.isAnyProviderConfigured) {
        AIConfigHelper.showAIConfigGuidance(context);
      }
      _checkInitialError();
    });
  }

  void _checkInitialError() {
    if (!mounted) return;
    final provider = context.read<BankAnalyzerProvider>();
    if (provider.state == AnalyzerState.error && provider.errorMessage != null) {
      _showErrorDialog(context, provider.errorMessage!);
      provider.reset(); // Clear error after showing
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyzerProvider = context.watch<BankAnalyzerProvider>();
    final aiConfig = context.watch<AIConfigurationProvider>();
    final isConfigured = aiConfig.isAnyProviderConfigured;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 40),
                            !isConfigured 
                                ? _buildConfigRequiredCard()
                                : _buildUploadCard(context, analyzerProvider),
                            const SizedBox(height: 32),
                            _buildStepsProcess(),
                            const SizedBox(height: 40),
                            _buildTrustIndicators(),
                            const SizedBox(height: 48),
                            if (isConfigured) _buildDemoButton(context, analyzerProvider),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: AppColors.primary),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              'Analyzer',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance for the back button
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'POWERED BY AI',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Financial Insights\nSimplified.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Upload your bank statement to unlock deep insights into your financial health.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textSecondary.withOpacity(0.7),
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard(BuildContext context, BankAnalyzerProvider provider) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _pickAndAnalyzeFile(context, provider),
            splashColor: AppColors.primary.withOpacity(0.05),
            highlightColor: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  right: -20,
                  child: Icon(
                    LucideIcons.fileText,
                    size: 120,
                    color: AppColors.primary.withOpacity(0.03),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24,
                      vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.15),
                              AppColors.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.cloudUpload,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Select Bank Statement',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Supports PDF, CSV and JSON',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Browse Files',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigRequiredCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.sparkles,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI Key Required',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Analysis requires a Gemini or OpenAI API key. Configure it in settings to proceed.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => AIConfigHelper.showAIConfigGuidance(context),
            icon: const Icon(LucideIcons.settings2, size: 16),
            label: const Text('Configure Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsProcess() {
    return Row(
      children: [
        _stepItem('1', 'Upload', LucideIcons.upload, true),
        _stepDivider(),
        _stepItem('2', 'AI Parse', LucideIcons.brain, false),
        _stepDivider(),
        _stepItem('3', 'Insights', LucideIcons.trendingUp, false),
      ],
    );
  }

  Widget _stepItem(String number, String label, IconData icon, bool active) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? AppColors.primary : AppColors.primary.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: active ? Colors.white : AppColors.primary.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: active ? AppColors.primary : AppColors.textSecondary.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDivider() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
        color: AppColors.primary.withOpacity(0.05),
      ),
    );
  }

  Widget _buildTrustIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _trustIconLabel(LucideIcons.shieldCheck, 'Bank Grade')),
          Expanded(child: _trustIconLabel(LucideIcons.lock, 'Private')),
          Expanded(child: _trustIconLabel(LucideIcons.zap, 'Instant')),
        ],
      ),
    );
  }

  Widget _trustIconLabel(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDemoButton(BuildContext context, BankAnalyzerProvider provider) {
    return OutlinedButton(
      onPressed: () {
        provider.startDemo();
        context.push('/analyzer/processing');
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.sparkles, size: 18),
          const SizedBox(width: 12),
          Text(
            'Try with Demo Data',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndAnalyzeFile(BuildContext context, BankAnalyzerProvider provider) async {
    try {
      final aiConfig = context.read<AIConfigurationProvider>();
      final apiKey = aiConfig.currentKey;

      // Using FileType.any instead of FileType.custom because many systems (especially Android/macOS)
      // don't have JSON/CSV registered as well-known types, causing them to be greyed out.
      // We perform manual extension validation below.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final extension = filePath.split('.').last.toLowerCase();
        
        // Final validation for the selected file type
        if (!['pdf', 'csv', 'json'].contains(extension)) {
           if (mounted) {
             _showErrorDialog(context, "Unsupported file type. Please select a PDF, CSV or JSON file.");
           }
           return;
        }
        
        provider.analyzeStatement(file, apiKey: apiKey);
        
        if (mounted && context.mounted) {
           context.push('/analyzer/processing');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(LucideIcons.circleAlert, color: Colors.red),
            const SizedBox(width: 12),
            Text('Upload Error', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Understood',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}



