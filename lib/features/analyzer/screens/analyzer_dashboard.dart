// REFINED STORY-DRIVEN UI V2
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/bank_analyzer_provider.dart';
import '../models/bank_statement_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/providers/ai_configuration_provider.dart';
import '../providers/chat_provider.dart';
import 'ai_chat_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_models.dart';
import 'package:intl/intl.dart';

/// Financial Insights Screen
/// AI-first, story-driven experience featuring a swipeable carousel of insights.
class AnalyzerDashboard extends StatefulWidget {
  const AnalyzerDashboard({super.key});

  @override
  State<AnalyzerDashboard> createState() => _AnalyzerDashboardState();
}

class _AnalyzerDashboardState extends State<AnalyzerDashboard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final data = analyzerProvider.analyzedData;

    // Empty state: No analysis data available
    if (data == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (analyzerProvider.bankInfo != null) ...[
                  _buildBankInfoCard(analyzerProvider.bankInfo!),
                  const SizedBox(height: 48),
                ],
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.fileSearch, size: 54, color: AppColors.primary),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'No Analysis Available',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Upload your bank statement on the Home tab to unlock deep financial insights powered by AI.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to Home tab (index 0)
                            if (context.canPop()) {
                               context.pop();
                            } else {
                               context.go('/home');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Go to Home',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
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
      );
    }

    final summary = data.summary;
    final topCategory = data.outboundCategories.isNotEmpty ? data.outboundCategories.first : null;
    final topInsight = data.insights.isNotEmpty ? data.insights.first : null;
    final savingsPercent = summary.totalInflow > 0 
        ? ((summary.totalInflow - summary.totalOutflow) / summary.totalInflow * 100).clamp(0, 100).toInt()
        : 0;

    final stories = data.insights.map((insight) {
      return _StoryData(
        title: insight.title,
        content: insight.content,
        icon: insight.icon,
        color: insight.color,
        iconColor: Colors.white,
        textColor: Colors.white,
      );
    }).toList();

    if (stories.isEmpty) {
      stories.add(_StoryData(
        title: 'Summary',
        content: 'You spent ₹${_formatAmount(summary.totalOutflow)} this month.',
        icon: LucideIcons.trendingUp,
        color: const Color(0xFF0F172A),
        iconColor: Colors.white,
        textColor: Colors.white,
      ));
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Financial Insights',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20, color: AppColors.textSecondary),
            onPressed: () => analyzerProvider.reset(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              
              if (analyzerProvider.bankInfo != null) ...[
                _buildBankInfoCard(analyzerProvider.bankInfo!),
                const SizedBox(height: 32),
              ],
              
              // Progress indicator for stories
              _buildStoryProgress(stories.length),
              const SizedBox(height: 16),
              
              // Swipeable Carousel
              SizedBox(
                height: MediaQuery.of(context).size.height*0.5, // Slightly increased height to avoid trimming
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: stories.length,
                  itemBuilder: (context, idx) => _buildStoryCard(stories[idx]),
                ),
              ),
              
              const SizedBox(height: 48),

              // AI Chat Entry Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GestureDetector(
                  onTap: () => _navigateToChat(context, data.outboundCategories.expand((c) => c.transactions).toList() + data.inboundTransactions),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.sparkles, color: Color(0xFF10B981), size: 24),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ask Sampatti AI',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Get answers about your spending habits instantly.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, color: Colors.white38, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),
              
              // Elegant Financial Snapshot
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Financial Snapshot',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Summary',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildElegantSnapshot(summary.totalInflow, summary.totalOutflow, savingsPercent),
                  ],
                ),
              ),
              
              const SizedBox(height: 120), // Bottom padding
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/analyzer/transactions'),
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(LucideIcons.list, color: Colors.white),
      ),
    );
  }  Widget _buildBankInfoCard(BankInfo info) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
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
                            _formatAmount(info.currentBalance),
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
                              Icon(LucideIcons.shieldCheck, size: 12, color: const Color(0xFF10B981).withOpacity(0.8)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Verified Account',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF10B981).withOpacity(0.8),
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
      ),
    );
  }

  Widget _buildStoryProgress(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: List.generate(count, (idx) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: idx <= _currentPage 
                  ? AppColors.primary.withOpacity(0.8) 
                  : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStoryCard(_StoryData story) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: story.color,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle background decoration
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              story.icon,
              size: 150,
              color: story.iconColor.withOpacity(0.03),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(story.icon, color: story.iconColor, size: 36),
                ),
                const Spacer(),
                Text(
                  story.title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: story.textColor.withOpacity(0.8),
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Flexible(
                  flex: 2,
                  child: Center(
                    child:  SingleChildScrollView(child:Text(
                        story.content,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: story.textColor,
                          height: 1.35,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      )),

                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantSnapshot(double inflow, double outflow, int savings) {
    return Column(
      children: [
        Row(
          children: [
            _buildSnapshotCard(
              'Total Inflow', 
              '₹${_formatAmount(inflow)}', 
              LucideIcons.arrowDownLeft, 
              AppColors.success,
            ),
            const SizedBox(width: 16),
            _buildSnapshotCard(
              'Total Outflow', 
              '₹${_formatAmount(outflow)}', 
              LucideIcons.arrowUpRight, 
              AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSnapshotCard(
          'Savings Rate', 
          '$savings%', 
          LucideIcons.piggyBank, 
          AppColors.primary,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildSnapshotCard(String label, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    final content = Container(
      height: isFullWidth ? null : 160, // Fixed height for half-width cards to support Spacer()
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: isFullWidth ? 
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
      : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );

    return isFullWidth ? content : Expanded(child: content);
  }

  void _navigateToChat(BuildContext context, List<BankTransaction> transactions) {
    final aiConfig = context.read<AIConfigurationProvider>();
    final apiKey = aiConfig.currentKey;

    // Get CAS URL from AuthProvider
    final authProvider = context.read<AuthProvider>();
    final casUrl = authProvider.user?.casUrl;

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure your Gemini API key in Settings first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.go(
      '/chat',
      extra: {
        'transactions': transactions,
        'apiKey': apiKey,
        'casUrl': casUrl,
      },
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), 
      (m) => "${m[1]},"
    );
  }
}

class _StoryData {
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final Color textColor;

  _StoryData({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.textColor,
  });
}
