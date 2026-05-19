import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/mutual_funds_view.dart';
import '../widgets/equity_funds_view.dart';
import '../widgets/vested_funds_view.dart';
import '../widgets/insurance_funds_view.dart';
import '../widgets/sip_funds_view.dart';
import '../widgets/investments_shimmer.dart';
import '../providers/investment_provider.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  // Hardcoded current user ID for demo purposes
  final String _currentUserId = 'demo_user_123';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvestmentProvider>().initData(_currentUserId);
    });
  }

  final List<String> _familyTabs = ['Total Invest.', 'Family member 1', 'Family member 2'];

  final List<String> _tabs = [
    'Dashboard', 'Mutual Funds', 'Equity', 'Vested', 'SIP', 
    'Insurance', 'Fixed Deposit', 'PMS', 'Liquiloans', 
    'Commercial Property', 'Bond', 'Gold', 'Strata'
  ];

  final List<Map<String, String>> _breakdownData = [
    {'title': 'Mutual Funds', 'subtitle': 'Current Value', 'value': '₹ 2,67,70,128.67'},
    {'title': 'Equity', 'subtitle': 'Current Value', 'value': '₹ 77,46,653.41'},
    {'title': 'Vested', 'subtitle': 'Current Value', 'value': '\$10422.25'},
    {'title': 'SIP', 'subtitle': 'Invested Amount', 'value': '₹17,72,411.39'},
    {'title': 'Fixed Deposit', 'subtitle': 'Invested Amount', 'value': '₹17,72,411.39'},
    {'title': 'Portfolio Management Service', 'subtitle': 'Invested Amount', 'value': '₹17,72,411.39'},
    {'title': 'Commercial Property', 'subtitle': 'Invested Amount', 'value': '₹17,72,411.39'},
    {'title': 'Liquiloans', 'subtitle': 'Current Value', 'value': '₹17,72,411.37'},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvestmentProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildHeader(provider),
            const SizedBox(height: 16),
            if (provider.selectedDropdown == 'Family') ...[
              _buildFamilyTabs(provider),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.selectedDropdown == 'Family') ...[
                      _buildFamilySummary(provider),
                      const SizedBox(height: 24),
                    ],
                    if (provider.isLoading)
                      InvestmentsShimmer(selectedTab: provider.selectedTab)
                    else if (provider.state == InvestmentState.error)
                      Center(child: Text(provider.errorMessage))
                    else ...[
                      if (!(provider.selectedDropdown == 'Family' && provider.selectedFamilyTab == 'Total Invest.')) ...[
                        _buildCategoryTabs(provider),
                        const SizedBox(height: 24),
                      ],
                      if (provider.selectedTab == 'Mutual Funds')
                        MutualFundsView(summary: provider.currentSummary, holdings: provider.holdings)
                      else if (provider.selectedTab == 'Equity')
                        EquityFundsView(summary: provider.currentSummary, holdings: provider.holdings)
                      else if (provider.selectedTab == 'Vested')
                        const VestedFundsView()
                      else if (provider.selectedTab == 'Insurance')
                        const InsuranceFundsView()
                      else if (provider.selectedTab == 'SIP')
                        const SipFundsView()
                      else ...[
                        Text(
                          'Product wise AUM',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold, 
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildDonutChart(),
                        const SizedBox(height: 32),
                        Text(
                          'Investment Breakdown',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold, 
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInvestmentBreakdown(),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(InvestmentProvider provider) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Investments',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (String value) => provider.setSelectedDropdown(value, _currentUserId),
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Personal',
                child: Text('Personal'),
              ),
              const PopupMenuItem<String>(
                value: 'Family',
                child: Text('Family'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    provider.selectedDropdown,
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down,
                      color: theme.colorScheme.primary, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTabs(InvestmentProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: _familyTabs.map((tab) {
          final isActive = tab == provider.selectedFamilyTab;
          return GestureDetector(
            onTap: () => provider.setSelectedFamilyTab(tab, _currentUserId),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              padding: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? const Color(0xFF1E8C45) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: isActive ? const Color(0xFF1E8C45) : Colors.grey[800],
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFamilySummary(InvestmentProvider provider) {
    if (provider.selectedFamilyTab == 'Total Invest.') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: RichText(
          text: const TextSpan(
            text: 'Total Investments: ',
            style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
            children: [
              TextSpan(
                text: '100,000,000',
                style: TextStyle(color: Color(0xFF1E8C45), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    } else if (provider.selectedFamilyTab == 'Family member 1') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account holder: Velicheti Venkata Durga',
            style: TextStyle(color: Colors.grey[700], fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF438B57), Color(0xFF2E633C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF438B57).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Portfolio',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                getSummaryValueWidget('₹6,746,653'),
              ],
            ),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  Widget getSummaryValueWidget(String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Asset Under Management',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs(InvestmentProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: _tabs.map((tab) {
          final isActive = tab == provider.selectedTab;
          return GestureDetector(
            onTap: () => provider.setSelectedTab(tab, _currentUserId),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFDDF3E4) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? const Color(0xFF1E8C45) : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: isActive ? const Color(0xFF1E8C45) : Colors.grey[600],
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDonutChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF6),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 70,
                    startDegreeOffset: 270,
                    sections: [
                      PieChartSectionData(
                        color: const Color(0xFF6246C6),
                        value: 6.21,
                        title: '6.21%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        titlePositionPercentageOffset: 0.6,
                      ),
                      PieChartSectionData(
                        color: const Color(0xFF7CB342),
                        value: 1.56,
                        title: '',
                        radius: 50,
                        badgeWidget: const Text(
                          '1.56%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                        ),
                        badgePositionPercentageOffset: 1.3,
                      ),
                      PieChartSectionData(
                        color: const Color(0xFFFACC35),
                        value: 41.11,
                        title: '41.11%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                        titlePositionPercentageOffset: 0.6,
                      ),
                      PieChartSectionData(
                        color: const Color(0xFFE55D3B),
                        value: 51.11,
                        title: '51.11%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        titlePositionPercentageOffset: 0.6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.push('/category-distribution'),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF28A745),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Category Distribution',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.feed_outlined, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFF6246C6), 'Equity'),
              _buildLegendItem(const Color(0xFF7CB342), 'Gold'),
              _buildLegendItem(const Color(0xFFFACC35), 'Mutual Funds'),
              _buildLegendItem(const Color(0xFFE55D3B), 'PMS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentBreakdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _breakdownData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final isLast = index == _breakdownData.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title']!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['subtitle']!,
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      data['value']!,
                      style: const TextStyle(
                        color: Color(0xFF1E8C45),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  color: Colors.grey[100],
                  height: 1,
                  thickness: 1,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
