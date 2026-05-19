import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class SideNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isCollapsed;
  final bool isVisible;

  const SideNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isCollapsed = false,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    final user = context.watch<AuthProvider>().user;

    return Drawer(
      width: 280,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
              child: _buildLogo(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildNavItem(
                      icon: LucideIcons.sparkles,
                      label: 'AI Chat',
                      isSelected: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                    _buildNavItem(
                      icon: Icons.home_outlined,
                      label: 'Banking',
                      isSelected: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                    _buildNavItem(
                      icon: LucideIcons.pieChart,
                      label: 'Demat',
                      isSelected: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                   /* _buildNavItem(
                      icon: LucideIcons.barChart2,
                      label: 'Insights',
                      isSelected: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),*/
                    _buildNavItem(
                      icon: LucideIcons.user,
                      label: 'Profile',
                      isSelected: currentIndex == 4,
                      onTap: () => onTap(4),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(indent: 24, endIndent: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: _buildUserProfile(user),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF818CF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            LucideIcons.landmark,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Sampatti',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfile(dynamic user) {
    final String name = user?.name ?? 'John Doe';
    final String initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(
              initials.isEmpty ? 'U' : initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Premium Member',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.moreVertical,
            color: AppColors.textSecondary,
            size: 16,
          ),
        ],
      ),
    );
  }
}
