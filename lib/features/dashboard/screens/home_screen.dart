import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/home_provider.dart';
import '../models/home_data.dart';
import '../models/product_model.dart';
import '../models/chart_data_point.dart';

import '../widgets/home_shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllProducts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          if (homeProvider.state == HomeState.loading) {
            return const HomeShimmerLoading();
          }

          if (homeProvider.state == HomeState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${homeProvider.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => homeProvider.fetchHomeData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final homeData = homeProvider.homeData;
          if (homeData == null) {
            return const Center(child: Text('No data available'));
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, homeData),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAumChartCard(context, homeData),
                      const SizedBox(height: 16),
                      _buildProductsCard(context, homeData),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, HomeData homeData) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF438B57),
      expandedHeight: 240.0,
      pinned: true,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 56, left: 24, right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Asset Under Management',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹ ${homeData.aumData.totalAum.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFF9500),
            radius: 20,
            child: Text('V', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Velicheti Venkata Durga',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Last Meeting Time - ${homeData.aumData.lastMeetingTime}',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.menu, color: Colors.white),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAumChartCard(BuildContext context, HomeData homeData) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Month wise AUM',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildChart(homeData.chartData),
                  // Static Tooltip matching screenshot
                  Positioned(
                    top: 10,
                    right: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₹ 2,00,000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          SizedBox(height: 2),
                          Text('20 Sept 2023', style: TextStyle(color: Color(0xFF438B57), fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildChartToggles(),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<ChartDataPoint> chartData) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 10000,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 10000,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('0', style: TextStyle(color: Colors.grey, fontSize: 10));
                return Text('${(value / 1000).toInt()}K', style: const TextStyle(color: Colors.grey, fontSize: 10));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < chartData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(chartData[value.toInt()].month, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: chartData.isNotEmpty ? chartData.length.toDouble() - 1 : 0,
        minY: 0,
        maxY: 40000,
        lineBarsData: [
          LineChartBarData(
            spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
            isCurved: true,
            color: const Color(0xFF438B57),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF438B57).withOpacity(0.3),
                  const Color(0xFF438B57).withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartToggles() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTogglePill('Monthly', true),
        const SizedBox(width: 12),
        _buildTogglePill('Quarterly', false),
        const SizedBox(width: 12),
        _buildTogglePill('Yearly', false),
      ],
    );
  }

  Widget _buildTogglePill(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFDDF3E4) : const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF438B57) : Colors.grey[600],
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildProductsCard(BuildContext context, HomeData homeData) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 20),
            _buildProductsGrid(homeData.products),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showAllProducts = !_showAllProducts;
                  });
                },
                child: Text(
                  _showAllProducts ? 'View less >' : 'View more >',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(List<ProductModel> products) {
    final displayProducts = _showAllProducts ? products : products.take(8).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 16,
        childAspectRatio: 0.70,
      ),
      itemBuilder: (context, index) {
        final p = displayProducts[index];
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(int.parse(p.colorHex.replaceFirst('0x', ''), radix: 16)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                IconData(p.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: Color(int.parse(p.iconColorHex.replaceFirst('0x', ''), radix: 16)),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                p.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.1),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
