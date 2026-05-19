import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/home_provider.dart';
import '../models/home_data.dart';
import '../models/product_model.dart';
import '../widgets/home_shimmer_loading.dart';
import '../providers/ai_insight_provider.dart';
import '../../profile/providers/ai_configuration_provider.dart';
import '../../profile/screens/ai_settings_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/cas_upload_bottom_sheet.dart';
import '../../analyzer/providers/bank_analyzer_provider.dart';
import '../../analyzer/models/bank_statement_model.dart';
import '../../analyzer/models/chat_models.dart';
import '../../../core/utils/ai_config_helper.dart';
import 'package:intl/intl.dart';


class HomePageV2 extends StatefulWidget {
  const HomePageV2({super.key});

  @override
  State<HomePageV2> createState() => _HomePageV2State();
}

class _HomePageV2State extends State<HomePageV2> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    
    // Fetch insights from Firestore on load and load AI keys
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AIInsightProvider>(context, listen: false).fetchUserInsights();
      Provider.of<AIConfigurationProvider>(context, listen: false).loadStoredKeys();
      
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        context.read<BankAnalyzerProvider>().fetchBankInfo(authProvider.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyzerProvider = context.watch<BankAnalyzerProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          if (homeProvider.state == HomeState.loading) {
            return const HomeShimmerLoading();
          }

          if (homeProvider.state == HomeState.error) {
            return _buildErrorView(homeProvider);
          }

          if (analyzerProvider.isProcessing) {
            return _buildProcessingState(analyzerProvider);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverAppBar(
                          title: Text("Dashboard"),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          centerTitle: false,
                          leadingWidth: 30,
                          automaticallyImplyLeading: true,
                        ),


                        if (analyzerProvider.bankInfo != null) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 24, vertical: 20),
                              child: _buildBankInfoCard(analyzerProvider.bankInfo!),
                            ),
                          ),
                        ],

                        if (analyzerProvider.analyzedData == null) ...[
                          _buildInitialStateSliver(isWide),
                        ] else
                          _buildPostUploadStateSliver(isWide, analyzerProvider.analyzedData!),
                        
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCardByIndex(int index, HomeData homeData, bool isWide) {
    switch (index) {
      case 0: return _buildNetWorthCard(homeData);
      case 1: return _buildAllocationCard(homeData);
      case 2: return _buildPerformanceCard(homeData);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildErrorView(HomeProvider homeProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(LucideIcons.circleAlert, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              homeProvider.errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => homeProvider.fetchHomeData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildNetWorthCard(HomeData homeData) {
    final netWorthChange = homeData.aumData.netWorthChangePercentage;
    final isPositive = netWorthChange >= 0;
    final changeText = '${isPositive ? '+' : ''}$netWorthChange%';

    return _buildBaseCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.primary.withBlue(200)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL NET WORTH',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 1.2,
                ),
              ),
              Icon(LucideIcons.eye, color: Colors.white.withOpacity(0.6), size: 18),
            ],
          ),
          const SizedBox(height: 24),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '₹ ${homeData.aumData.totalAum.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      changeText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'vs last month',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader(bool isWide, HomeProvider homeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                homeProvider.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: isWide ? 32 : 26,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 3),
              ),
              child: CircleAvatar(
                radius: isWide ? 28 : 24,
                backgroundColor: AppColors.primary,
                child: Text(
                  _getInitials(homeProvider.userName),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildAllocationCard(HomeData homeData) {
    final allocations = homeData.allocations;
    return _buildBaseCard(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio Allocation',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                ...allocations.map((a) => _buildAllocationLegend(a.label, Color(int.parse(a.colorHex)), '${a.percentage.toInt()}%')),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 35,
                sections: allocations.map((a) => PieChartSectionData(
                  color: Color(int.parse(a.colorHex)), 
                  value: a.percentage.toDouble(), 
                  radius: 15, 
                  showTitle: false
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationLegend(String label, Color color, String percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label, 
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Text(percentage, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(HomeData homeData) {
    // Generate FlSpots from homeData.chartData
    final List<FlSpot> spots = homeData.chartData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value / 10000)) // Scaled down for visual presentation
        .toList();

    return _buildBaseCard(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Performance Trend',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              Text(
                '+4.2%', // Mocked overall performance since we only have individual month values
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 25),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots.isNotEmpty 
                          ? spots 
                          : const [FlSpot(0, 0), FlSpot(1, 0)],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(HomeData homeData, AIInsightProvider aiProvider, AIConfigurationProvider aiConfig, bool isWide) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 24, 
        vertical: 16,
      ),
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.sparkles, size: 24, color: AppColors.primary),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart AI Insights',
                      style: GoogleFonts.inter(
                        fontSize: 20, 
                        fontWeight: FontWeight.w800, 
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (aiProvider.insightState == AIInsightState.ready && aiProvider.lastUploadTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Last updated: ${_formatDate(aiProvider.lastUploadTime!)}',
                          style: GoogleFonts.inter(
                            fontSize: 12, 
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (aiProvider.insightState == AIInsightState.ready)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (aiConfig.isAnyProviderConfigured) {
                        final user = context.read<AuthProvider>().user;
                        if (user?.casFileType == 'json') {
                          // No password needed for JSON, refresh immediately
                          aiProvider.refreshInsights(
                            '', 
                            aiConfig.selectedProvider, 
                            aiConfig.currentKey
                          );
                        } else {
                          _showRefreshPasswordDialog(aiProvider, aiConfig);
                        }
                      } else {
                        AIConfigHelper.showAIConfigGuidance(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAIContent(aiProvider, aiConfig),
          if (aiProvider.insightState == AIInsightState.ready) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _navigateToAIChat,
                icon: const Icon(LucideIcons.messageSquare, size: 18),
                label: Text(
                  'Discuss with AI Chat',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIContent(AIInsightProvider aiProvider, AIConfigurationProvider aiConfig) {
    if (!aiConfig.isInitialized) {
      return _buildAILoading("Initializing AI config...");
    }
    if (aiProvider.uploadStatus == CASUploadStatus.uploading) {
      return _buildAILoading("Uploading statement...");
    }
    
    if (aiProvider.insightState == AIInsightState.generating) {
      return _buildAILoading("Analyzing your portfolio...");
    }

    if (aiProvider.uploadStatus == CASUploadStatus.none) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.fileSearch, size: 40, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            "Unlock detailed AI insights by uploading your CAS statement.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (aiConfig.isAnyProviderConfigured) {
                _showCASUploadBottomSheet();
              } else {
                AIConfigHelper.showAIConfigGuidance(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text("Upload CAS"),
          ),
        ],
      );
    }

    if (aiProvider.insightState == AIInsightState.error || aiProvider.uploadStatus == CASUploadStatus.error) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.circleAlert, size: 30, color: AppColors.error),
          const SizedBox(height: 8),
          Text(
            aiProvider.errorMessage != null ? aiProvider.errorMessage!:"Failed to load insights",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
          ),
          TextButton(
            onPressed: () {
              final aiConfig = Provider.of<AIConfigurationProvider>(context, listen: false);
              aiProvider.uploadCAS(aiConfig.selectedProvider, aiConfig.currentKey);
            },
            child: const Text("Retry"),
          ),
        ],
      );
    }

    final insights = aiProvider.insights;
    if (insights.isEmpty) {
      return Center(
        child: Text(
          "No insights yet. Try uploading a fresh CAS.",
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: insights.map((insight) => _buildInsightRow(
        LucideIcons.sparkles, // Consistent icon for AI insights
        insight.title, 
        insight.subtitle, 
        Color(int.parse(insight.bgColorHex)), 
        Color(int.parse(insight.iconColorHex)),
      )).toList(),
    );
  }

  Widget _buildAILoading(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(height: 16),
        Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInsightRow(IconData icon, String title, String subtitle, Color bgColor, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 16, color: AppColors.border),
        ],
      ),
    );
  }

  Widget _buildBaseCard({Widget? child, Color? color, Gradient? gradient}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: color == Colors.white ? Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)) : null,
      ),
      child: child,
    );
  }

  Widget _buildInvestmentGrid(HomeData homeData, double width) {
    // Dynamic column count based on width
    int crossAxisCount = 2;
    if (width > 1000) {
      crossAxisCount = 4;
    } else if (width > 600) {
      crossAxisCount = 3;
    }

    final gridItems = homeData.gridItems;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = gridItems[index];
          return _InvestmentTile(
            title: item.title,
            icon: IconData(item.iconCodePoint,fontFamily:LucideIcons.aArrowUp.fontFamily, fontPackage:LucideIcons.aArrowUp.fontPackage),
            value: item.value,
            pl: item.pl,
            insight: item.insight,
            color: Color(int.parse(item.colorHex)),
          );
        },
        childCount: gridItems.length,
      ),
    );
  }

  Widget _buildPageIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        bool isSelected = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isSelected ? 32 : 8,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(4),
            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 4, offset: Offset(0, 2))] : null,
          ),
        );
      }),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == 'N/A') return 'N/A';
    final parts = name.split(' ');
    if (parts.length > 1) {
      if (parts[0].isNotEmpty && parts[parts.length - 1].isNotEmpty) {
        return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
      }
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'N/A';
  }

  void _showCASUploadBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CASUploadBottomSheet(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showRefreshPasswordDialog(AIInsightProvider aiProvider, AIConfigurationProvider aiConfig) {
    final TextEditingController passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Refresh Insights',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To generate fresh insights from your stored statement, we need your CAS password (PAN) to securely process the file.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'CAS Password (PAN)',
                labelStyle: TextStyle(fontSize: 14),
                hintText: 'Enter your PAN',

                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(LucideIcons.lock, size: 18),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final password = passwordController.text.trim();
              if (password.isNotEmpty) {
                Navigator.pop(context);
                aiProvider.refreshInsights(
                  password, 
                  aiConfig.selectedProvider, 
                  aiConfig.currentKey
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAnalyzerCTA(bool isWide) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank Statement Analyzer',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get AI-powered insights into your monthly spending & savings.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final aiConfig = Provider.of<AIConfigurationProvider>(context, listen: false);
                    if (aiConfig.isAnyProviderConfigured) {
                      context.push('/analyzer/upload');
                    } else {
                      AIConfigHelper.showAIConfigGuidance(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Get Started',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.chevronRight, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.sparkles,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialStateSliver(bool isWide) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 24, vertical: 10),
            child: _buildBankAnalyzerCTA(isWide),
          ),
          // Additional guidance for new users
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 24, vertical: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.shieldQuestionMark, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Why analyze your statements?',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildBenefitItem(LucideIcons.shieldCheck, 'Bank-grade security for your data'),
                  _buildBenefitItem(LucideIcons.brainCircuit, 'AI-powered spending categorization'),
                  _buildBenefitItem(LucideIcons.trendingUp, 'Personalized saving recommendations'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState(BankAnalyzerProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Text(
              provider.processingMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Our AI is analyzing your transactions to provide deep insights.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            if (provider.state == AnalyzerState.uploading)
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: provider.uploadProgress,
                    minHeight: 6,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostUploadStateSliver(bool isWide, AnalyzedStatement data) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 24, vertical: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.06),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
            border: Border.all(color: AppColors.primary.withOpacity(0.05)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section with header and health score
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Financial Pulse',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.insights.isNotEmpty 
                                ? data.insights.first.content 
                                : 'AI-analyzed summary of your statement',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildPulseHealthIndicator(data.summary.healthScore),
                    ],
                  ),
                ),
                
                // Metrics row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _buildRefinedPulseMetric(
                        'Total Inflow', 
                        '₹${_formatPulseAmount(data.summary.totalInflow)}', 
                        LucideIcons.arrowDownLeft, 
                        AppColors.success,
                      ),
                      const SizedBox(width: 16),
                      _buildRefinedPulseMetric(
                        'Total Outflow', 
                        '₹${_formatPulseAmount(data.summary.totalOutflow)}', 
                        LucideIcons.arrowUpRight, 
                        AppColors.error,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // CTA Button - Full width in a tinted section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.03),
                    border: Border(top: BorderSide(color: AppColors.primary.withOpacity(0.05))),
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.go('/insights'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.sparkles, size: 20),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'View Insights',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulseHealthIndicator(int score) {
    Color color = score >= 75 ? AppColors.success : (score >= 50 ? Colors.orange : AppColors.error);
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.2), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score',
            style: GoogleFonts.inter(
              fontSize: 22, 
              fontWeight: FontWeight.w900, 
              color: color,
              letterSpacing: -1,
            ),
          ),
          Text(
            'SCORE',
            style: GoogleFonts.inter(
              fontSize: 8, 
              fontWeight: FontWeight.w800, 
              color: color.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefinedPulseMetric(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankInfoCard(BankInfo info) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Premium Gradient Background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            
            // Decorative Glow
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.bankName.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withOpacity(0.4),
                                letterSpacing: 2.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              info.accountType,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Digital Chip Aesthetic
                      Container(
                        width: 40,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber.shade200, Colors.amber.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(LucideIcons.landmark, color: Colors.amber.shade900.withOpacity(0.6), size: 16),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'TOTAL BALANCE',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.3),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          info.currency,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatPulseAmount(info.currentBalance),
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Footer info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.shieldCheck, size: 12, color: AppColors.success.withOpacity(0.8)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Verified Account',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success.withOpacity(0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '•••• ${info.accountId.length > 4 ? info.accountId.substring(info.accountId.length - 4) : info.accountId}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPulseAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},");
  }
  void _navigateToAIChat() {
    final aiConfig = context.read<AIConfigurationProvider>();
    final authProvider = context.read<AuthProvider>();
    final casUrl = authProvider.user?.casUrl;

    if (aiConfig.currentKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure your AI API key in settings.')),
      );
      return;
    }

    context.go(
      '/chat',
      extra: {
        'apiKey': aiConfig.currentKey,
        'casUrl': casUrl,
        'transactions': null,
      },
    );
  }


  IconData _getCategoryIcon(String category) {
    final lowerCat = category.toLowerCase();
    if (lowerCat.contains('food') || lowerCat.contains('dining')) return LucideIcons.utensils;
    if (lowerCat.contains('transport') || lowerCat.contains('travel')) return LucideIcons.car;
    if (lowerCat.contains('shopping')) return LucideIcons.shoppingBag;
    if (lowerCat.contains('entertainment') || lowerCat.contains('fun')) return LucideIcons.film;
    if (lowerCat.contains('health') || lowerCat.contains('med')) return LucideIcons.heartPulse;
    if (lowerCat.contains('education') || lowerCat.contains('school')) return LucideIcons.graduationCap;
    if (lowerCat.contains('grocery') || lowerCat.contains('mart')) return LucideIcons.shoppingCart;
    if (lowerCat.contains('bills') || lowerCat.contains('utilities')) return LucideIcons.receipt;
    if (lowerCat.contains('transfer') || lowerCat.contains('upi')) return LucideIcons.arrowRightLeft;
    return LucideIcons.wallet;
  }
}

class _InvestmentTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final String pl;
  final String insight;
  final Color color;

  const _InvestmentTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.pl,
    required this.insight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = pl.startsWith('+') || pl == 'Active' || pl == 'Monthly';

    return GestureDetector(
      onTap: () {
        // Deep dive action
      },
      onLongPress: () {
        _showQuickStats(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 22, color: AppColors.textPrimary),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pl,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              insight,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickStats(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(insight, style: GoogleFonts.inter(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildStatRow('Current Value', value),
            const SizedBox(height: 12),
            _buildStatRow('Returns', pl),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('View Full Analysis', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ],
    );
  }


}


