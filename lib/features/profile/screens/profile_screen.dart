import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/ai_insight_provider.dart';
import '../../dashboard/widgets/cas_upload_bottom_sheet.dart';
import '../providers/ai_configuration_provider.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: true,
        leadingWidth: 30,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Account'),
            const SizedBox(height: 16),
            _buildAccountCard(context, user?.name ?? 'Sridharan', user?.email ?? 'knsridharan@gmail.com'),
            
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Data Sources'),
            const SizedBox(height: 16),
            _buildCASDataSourceCard(context),

            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Settings'),
            const SizedBox(height: 16),
            _buildAISettingsItem(context),
            _buildSettingItem(context, LucideIcons.fileText, 'Meeting Notes', () {
              context.push('/meeting-notes');
            }),
            _buildSettingItem(context, LucideIcons.clipboardList, 'Questionnaire', () {
              context.push('/questionnaire');
            }),
            _buildSettingItem(context, LucideIcons.helpCircle, 'FAQ', () {
              context.push('/faq');
            }),
            _buildSettingItem(context, LucideIcons.helpingHand, 'Support', () {
              context.push('/help-support');
            }),
            _buildSettingItem(context, LucideIcons.logOut, 'Sign Out', () {
              context.read<AuthProvider>().logout();
              context.go('/login');
            }),

            const SizedBox(height: 16),
            _buildRatingCard(context),
            const SizedBox(height: 16),
            _buildServiceContactsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, String name, String email) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(LucideIcons.user, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16, 
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Meeting link',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _buildAISettingsItem(BuildContext context) {
    final aiConfig = context.watch<AIConfigurationProvider>();
    final theme = Theme.of(context);
    final isConfigured = aiConfig.isAnyProviderConfigured;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (isConfigured) {
            context.push('/manage-keys');
          } else {
            context.push('/ai-settings');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.sparkles, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        isConfigured ? 'Connected' : 'Not configured',
                        style: TextStyle(
                          color: isConfigured ? AppColors.success : theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
            if (isConfigured && aiConfig.lastUpdated != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(aiConfig.lastUpdated!)}',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 11),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isConfigured 
                ? OutlinedButton(
                    onPressed: () => context.push('/manage-keys'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Manage API Keys', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  )
                : ElevatedButton(
                    onPressed: () => context.push('/ai-settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Add API Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: theme.colorScheme.onSurface,
          ),
        ),
        trailing: Icon(LucideIcons.chevronRight, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget _buildRatingCard(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      leading: const Icon(LucideIcons.star, color: Color(0xFFFFD700)), // Golden Star
      title: const Text(
        'Ratings',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
      ),
      subtitle: const Text(
        'Rate our associates',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildUserRatingItem(context, 'Jeevan'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserRatingItem(BuildContext context, String name) {
    return GestureDetector(
      onTap: () => context.push('/rating'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(LucideIcons.user, size: 18, color: Color(0xFF1E8C45)),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceContactsCard() {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      leading: const Icon(LucideIcons.users, color: Color(0xFF1E8C45)),
      title: const Text(
        'Service Associated',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
      ),
      subtitle: const Text(
        'Quick contact for help',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildContactItem('Jeevan', '9292929297'),
              const SizedBox(height: 12),
              _buildContactItem('Niranjan', '9292929297'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCASDataSourceCard(BuildContext context) {
    final aiProvider = context.watch<AIInsightProvider>();
    final theme = Theme.of(context);
    final isUploaded = aiProvider.uploadStatus == CASUploadStatus.uploaded;
    final lastUploadStr = aiProvider.lastUploadTime != null 
        ? DateFormat('dd MMM yyyy, hh:mm a').format(aiProvider.lastUploadTime!)
        : 'Never';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUploaded ? AppColors.success.withOpacity(0.1) : theme.dividerColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUploaded ? LucideIcons.fileCheck : LucideIcons.filePlus, 
                  color: isUploaded ? AppColors.success : theme.colorScheme.onSurface.withOpacity(0.4),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              //CAS Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consolidated Account Statement',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface),
                    ),
                    Text(
                      isUploaded ? 'Last upload: $lastUploadStr' : 'No statement uploaded',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final aiConfig = context.read<AIConfigurationProvider>();
                  if (aiConfig.isAnyProviderConfigured) {
                    _showCASUploadBottomSheet(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please configure AI Settings first')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUploaded ? Colors.transparent : theme.colorScheme.primary,
                  foregroundColor: isUploaded ? theme.colorScheme.primary : Colors.white,
                  elevation: 0,
                  side: isUploaded ? BorderSide(color: theme.colorScheme.primary) : null,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(isUploaded ? 'Replace' : 'Upload', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (aiProvider.uploadStatus == CASUploadStatus.uploading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (aiProvider.errorMessage != null)
             Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                aiProvider.errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String name, String phone) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.user, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(LucideIcons.smartphone, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    phone,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF2C3E50)),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDDF3E4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.phone, size: 18, color: Color(0xFF1E8C45)),
          ),
        ],
      ),
    );
  }

  void _showCASUploadBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CASUploadBottomSheet(),
    );
  }
}
