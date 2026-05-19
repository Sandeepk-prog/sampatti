import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/side_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';

class MainLayout extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isNavExpanded = true; // Default to expanded on desktop
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    if (index == 0) {
      widget.navigationShell.goBranch(
        index,
        initialLocation: index == widget.navigationShell.currentIndex,
      );
    } else {
      switch (index) {
        case 1:
          context.push('/home');
          break;
        case 2:
          context.push('/demat_demat');
          break;
        case 3:
          context.push('/insights');
          break;
        case 4:
          context.push('/profile');
          break;
      }
    }
    // Close drawer on mobile after selection
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  String _getPageName(int index) {
    switch (index) {
      case 0: return 'AI Chat';
      case 1: return 'Bank';
      case 2: return 'Demat';
      case 3: return 'Insights';
      case 4: return 'Profile';
      default: return 'Home';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, 
        statusBarBrightness: Brightness.dark, 
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {

          final isMobile = constraints.maxWidth < 600;
          final isTablet = constraints.maxWidth < 1024 && !isMobile;
          
          return Scaffold(
            key: _scaffoldKey,
            drawer: isMobile ? SideNavigation(
              currentIndex: widget.navigationShell.currentIndex,
              onTap: _onItemTapped,
              isVisible: true,
            ) : null,
            body: Column(
              children: [
                _buildHeader(
                  isWide: !isMobile && !isTablet,
                  isMobile: isMobile,
                ),
                Expanded(
                  child: Row(
                    children: [
                      if (!isMobile)
                        SizedBox(
                          width: _isNavExpanded ? 280 : 0,
                          child: SideNavigation(
                            currentIndex: widget.navigationShell.currentIndex,
                            onTap: _onItemTapped,
                            isVisible: _isNavExpanded,
                          ),
                        ),
                      Flexible(
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: (isMobile || !_isNavExpanded) ? Radius.zero : const Radius.circular(32),
                            bottomLeft: (isMobile || !_isNavExpanded) ? Radius.zero : const Radius.circular(32),
                          ),
                          child: Container(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: widget.navigationShell,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({required bool isWide, required bool isMobile}) {
    final pageName = _getPageName(widget.navigationShell.currentIndex);
    final horizontalPadding = isWide ? 20.0 : 24.0;
    final user = context.watch<AuthProvider>().user;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
      decoration: BoxDecoration(
        //color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.05),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            InkWell(
              onTap: () {
                if (isMobile) {
                  _scaffoldKey.currentState?.openDrawer();
                } else {
                  setState(() {
                    _isNavExpanded = !_isNavExpanded;
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),

              /*  decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                ),*/

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      isMobile ? LucideIcons.menu : (_isNavExpanded ? LucideIcons.chevronLeft : LucideIcons.menu),
                      size: 26,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),

                    /*Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF818CF8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 12),
                    ),*/

                    const SizedBox(width: 8),
                    Text(
                      'Sampatti AI',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),

                   /* const SizedBox(width: 8),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pageName.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),*/
                  ],
                ),
              ),
            ),
            const Spacer(),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: user?.name != null && user!.name.isNotEmpty
                  ? Text(
                      user.name[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Icon(LucideIcons.user, color: AppColors.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
