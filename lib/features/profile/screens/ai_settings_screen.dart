import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/ai_configuration_provider.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final _keyController = TextEditingController();
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AIConfigurationProvider>();
    _keyController.text = provider.currentKey;
    _keyController.addListener(_onKeyChanged);
  }

  void _onKeyChanged() {
    final provider = context.read<AIConfigurationProvider>();
    final isChanged = _keyController.text != provider.currentKey;
    if (isChanged != _isEdited) {
      setState(() {
        _isEdited = isChanged;
      });
    }
  }

  @override
  void dispose() {
    _keyController.removeListener(_onKeyChanged);
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'AI Configuration',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
      ),
      body: Consumer<AIConfigurationProvider>(
        builder: (context, provider, child) {
          // Sync controller text if provider changed (e.g. after selection)
          // But only if not currently being edited by user
          if (!_isEdited && _keyController.text != provider.currentKey && provider.state == AIConfigState.idle) {
             _keyController.text = provider.currentKey;
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 32),
                      _buildProviderSelection(provider),
                      const SizedBox(height: 24),
                      _buildApiKeyField(provider),
                      const SizedBox(height: 32),
                      _buildStatusIndicator(provider),
                      const SizedBox(height: 32),
                      _buildActionButtons(provider),
                      if (provider.isConfigured) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildRemoveSection(provider),
                      ],
                      const SizedBox(height: 48),
                      _buildSecurityNotice(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage AI Providers',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure your API keys for portfolio insights and smart analysis.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProviderSelection(AIConfigurationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LLM Provider',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AIProvider>(
          value: provider.selectedProvider,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: AIProvider.values.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Row(
                children: [
                   Icon(
                    p == AIProvider.gemini ? LucideIcons.sparkles : LucideIcons.bot,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(p.name.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) provider.setProvider(val);
          },
        ),
      ],
    );
  }

  Widget _buildApiKeyField(AIConfigurationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'API Key',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _keyController,
          obscureText: provider.isObscured,
          style: GoogleFonts.jetBrainsMono(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter your ${provider.selectedProvider.name} key',
            filled: true,
            fillColor: Colors.grey.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                provider.isObscured ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 20,
              ),
              onPressed: provider.toggleVisibility,
            ),
            prefixIcon: const Icon(LucideIcons.keyRound, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(AIConfigurationProvider provider) {
    if (provider.state == AIConfigState.idle) return const SizedBox.shrink();

    Color color;
    IconData icon;
    String text;

    switch (provider.state) {
      case AIConfigState.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        );
      case AIConfigState.success:
        color = AppColors.success;
        icon = LucideIcons.circleCheck;
        text = 'Key verified and saved successfully';
        break;
      case AIConfigState.error:
        color = AppColors.error;
        icon = LucideIcons.circleAlert;
        text = provider.errorMessage;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AIConfigurationProvider provider) {
    bool isLoading = provider.state == AIConfigState.loading;
    bool hasKey = _keyController.text.trim().isNotEmpty;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading || !hasKey ? null : () => provider.testConnection(_keyController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Test Connection', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        if (_isEdited) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: isLoading ? null : () {
                provider.saveKey(_keyController.text);
                setState(() => _isEdited = false);
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRemoveSection(AIConfigurationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danger Zone',
          style: GoogleFonts.inter(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remove API Key',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'This will permanently delete the current API key from this device.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _confirmDelete(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Remove API Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            'Your data is secure',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Keys are stored locally in your device\'s encrypted hardware storage and never uploaded to our servers.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(AIConfigurationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete API Key?'),
        content: Text('This will remove the ${_selectedProviderName(provider)} key from your device. You will need to re-enter it to use AI features.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteKey();
              _keyController.clear();
              setState(() => _isEdited = false);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _selectedProviderName(AIConfigurationProvider provider) {
    return provider.selectedProvider.name.toUpperCase();
  }
}
