import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/aum_data.dart';
import '../models/chart_data_point.dart';
import '../models/home_data.dart';
import '../models/product_model.dart';
import '../models/allocation_data.dart';
import '../models/insight_data.dart';
import '../models/grid_item_data.dart';
import '../repositories/home_repository.dart';

class FirestoreHomeService implements HomeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<HomeData> getHomeData() async {
    try {
      // Fetch AUM Metrics
      final aumDoc = await _firestore.collection('dashboard_metrics').doc('aum_stats').get();
      final aumData = AumData.fromFirestore(aumDoc.data() ?? {});

      // Fetch Chart Data
      final chartSnapshot = await _firestore
          .collection('dashboard_metrics')
          .doc('aum_stats')
          .collection('chart_data')
          .orderBy('month_index') // Assume an index for proper ordering
          .get();
      
      final chartData = chartSnapshot.docs
          .map((doc) => ChartDataPoint.fromFirestore(doc.data()))
          .toList();

      // Fetch Products
    /*  final productSnapshot = await _firestore.collection('products').get();
      final products = productSnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.id, doc.data()))
          .toList();*/

      // Fetch Allocations
      final allocationSnapshot = await _firestore.collection('dashboard_metrics').doc('aum_stats').collection('allocations').get();
      final allocations = allocationSnapshot.docs.map((doc) => AllocationData.fromFirestore(doc.data())).toList();

      // Fetch Insights
      final insightSnapshot = await _firestore.collection('dashboard_metrics').doc('aum_stats').collection('insights').get();
      final insights = insightSnapshot.docs.map((doc) => InsightData.fromFirestore(doc.data())).toList();

      // Fetch Grid Items
      final gridItemSnapshot = await _firestore.collection('dashboard_metrics').doc('aum_stats').collection('grid_items').get();
      final gridItems = gridItemSnapshot.docs.map((doc) => GridItemData.fromFirestore(doc.data())).toList();

      return HomeData(
        aumData: aumData,
        chartData: chartData,
        products: [],
        allocations: allocations,
        insights: insights,
        gridItems: gridItems,
      );
    } catch (e) {
      // In a real app, we might want to log this to a service like Sentry or Crashlytics
      print('Error fetching home data: $e');
      rethrow;
    }
  }

  @override
  Future<bool> checkDataExists() async {
    try {
      final aumDoc = await _firestore.collection('dashboard_metrics').doc('aum_stats').get();
      return aumDoc.exists;
    } catch (e) {
      print('Error checking data existence: $e');
      return false;
    }
  }

  @override
  Future<void> initializeSampleData() async {
    try {
      // 1. Initial AUM Data
      final initialAum = AumData(
        totalAum: 1245000,
        lastMeetingTime: '04.02.2024, 10.20 am',
        netWorthChangePercentage: 12.5,
      );
      await updateAumMetrics(initialAum);

      // 2. Initial Chart Data
      final sampleChartData = [
        {'month': 'Jan', 'value': 22000.0, 'index': 0},
        {'month': 'Feb', 'value': 27000.0, 'index': 1},
        {'month': 'Mar', 'value': 23000.0, 'index': 2},
        {'month': 'Apr', 'value': 26000.0, 'index': 3},
        {'month': 'May', 'value': 18000.0, 'index': 4},
        {'month': 'Jun', 'value': 26000.0, 'index': 5},
      ];

      for (var point in sampleChartData) {
        await addChartDataPoint(
          point['month'] as String,
          point['value'] as double,
          point['index'] as int,
        );
      }

      // 3. Initial Products
      final sampleProducts = [
        ProductModel(id: '', title: 'Mutual\nFunds', iconCodePoint: 58711, colorHex: '0xFFDDF3E4', iconColorHex: '0xFF1E8C45'),
        ProductModel(id: '', title: 'Equity', iconCodePoint: 57475, colorHex: '0xFFFFE8D1', iconColorHex: '0xFFE88A1A'),
        ProductModel(id: '', title: 'Vested', iconCodePoint: 58405, colorHex: '0xFFF9E8B3', iconColorHex: '0xFFB58E29'),
        ProductModel(id: '', title: 'SIP', iconCodePoint: 58014, colorHex: '0xFFFFD6D6', iconColorHex: '0xFFD85C3A'),
        ProductModel(id: '', title: 'Fixed\nDeposit', iconCodePoint: 59379, colorHex: '0xFFEBE3FF', iconColorHex: '0xFF6B4CA4'),
        ProductModel(id: '', title: 'Insurance', iconCodePoint: 59450, colorHex: '0xFFDAE6FF', iconColorHex: '0xFF3B6CB4'),
        ProductModel(id: '', title: 'PMS', iconCodePoint: 57404, colorHex: '0xFFD1EEDB', iconColorHex: '0xFF4A895C'),
        ProductModel(id: '', title: 'Liquiloan', iconCodePoint: 59389, colorHex: '0xFFD0F4EE', iconColorHex: '0xFF329F8B'),
        ProductModel(id: '', title: 'Commercial\nProperty', iconCodePoint: 58245, colorHex: '0xFFE0F7FA', iconColorHex: '0xFF0097A7'),
        ProductModel(id: '', title: 'Bond', iconCodePoint: 59618, colorHex: '0xFFFCE4EC', iconColorHex: '0xFFC2185B'),
        ProductModel(id: '', title: 'Gold', iconCodePoint: 58169, colorHex: '0xFFFFF8E1', iconColorHex: '0xFFFFA000'),
      ];

      for (var product in sampleProducts) {
        await addProduct(product);
      }

      // 4. Sample Allocations
      final sampleAllocations = [
        AllocationData(label: 'Equity', colorHex: '0xFF1E8C45', percentage: 60),
        AllocationData(label: 'Debt', colorHex: '0xFFE88A1A', percentage: 25),
        AllocationData(label: 'Gold', colorHex: '0xFFFFA000', percentage: 15),
      ];
      for (var alloc in sampleAllocations) {
        await _firestore.collection('dashboard_metrics').doc('aum_stats').collection('allocations').add(alloc.toFirestore());
      }

      // 5. Sample Insights
      final sampleInsights = [
        InsightData(title: 'Top Gainers', subtitle: 'Mutual Funds up 8%', iconCodePoint: LucideIcons.trendingUp.codePoint, bgColorHex: '0x1A10B981', iconColorHex: '0xFF10B981'),
        InsightData(title: 'Action Required', subtitle: 'Rebalance Gold', iconCodePoint: LucideIcons.badgeAlert.codePoint, bgColorHex: '0x1AF59E0B', iconColorHex: '0xFFF59E0B'),
        InsightData(title: 'Upcoming SIP', subtitle: 'Equity due in 2d', iconCodePoint: LucideIcons.calendar.codePoint, bgColorHex: '0x1A6366F1', iconColorHex: '0xFF6366F1'),
      ];
      for (var insight in sampleInsights) {
        await _firestore.collection('dashboard_metrics').doc('aum_stats').collection('insights').add(insight.toFirestore());
      }

      // 6. Sample Grid Items
      final sampleGridItems = [
        GridItemData(title: 'Mutual Funds', iconCodePoint: LucideIcons.layers.codePoint, value: '₹ 12,45,000', pl: '+14.2%', insight: '3 Funds active', colorHex: '0xFFF0F9FF'),
        GridItemData(title: 'Direct Equity', iconCodePoint: LucideIcons.chartArea.codePoint, value: '₹ 8,90,000', pl: '+22.5%', insight: 'High Risk', colorHex: '0xFFF0FDF4'),
        GridItemData(title: 'SIP\'s', iconCodePoint: LucideIcons.calendarDays.codePoint, value: '₹ 45,000', pl: 'Monthly', insight: 'Next: 20 Mar', colorHex: '0xFFFEF2F2'),
        GridItemData(title: 'Gold', iconCodePoint: LucideIcons.coins.codePoint, value: '₹ 2,15,000', pl: '+8.1%', insight: 'Safe Haven', colorHex: '0xFFFFFBEB'),
        GridItemData(title: 'Vested', iconCodePoint: LucideIcons.globe.codePoint, value: '₹ 1,20,000', pl: '-2.4%', insight: 'US Stocks', colorHex: '0xFFEFF6FF'),
        GridItemData(title: 'Insurance', iconCodePoint: LucideIcons.shieldCheck.codePoint, value: '3 Policies', pl: 'Active', insight: '₹ 50L Cover', colorHex: '0xFFFDF2F8'),
        GridItemData(title: 'Real Estate', iconCodePoint: LucideIcons.building2.codePoint, value: '₹ 45,00,000', pl: '+15.0%', insight: 'Commercial', colorHex: '0xFFFAF5FF'),
        GridItemData(title: 'Bonds', iconCodePoint: LucideIcons.fileText.codePoint, value: '₹ 3,00,000', pl: '+9.2%', insight: 'Fixed Income', colorHex: '0xFFF0FEFE'),
      ];
      for (var item in sampleGridItems) {
        await _firestore.collection('dashboard_metrics').doc('aum_stats').collection('grid_items').add(item.toFirestore());
      }
    } catch (e) {
      print('Error initializing sample data: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getSavedNameFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sp_user_name');
  }

  // Helper methods to add sample data (as requested by user)
  Future<void> updateAumMetrics(AumData aumData) async {
    await _firestore.collection('dashboard_metrics').doc('aum_stats').set(aumData.toFirestore(), SetOptions(merge: true));
  }

  Future<void> addChartDataPoint(String month, double value, int index) async {
    await _firestore
        .collection('dashboard_metrics')
        .doc('aum_stats')
        .collection('chart_data')
        .add({
      'month': month,
      'value': value,
      'month_index': index,
    });
  }

  Future<void> addProduct(ProductModel product) async {
    await _firestore.collection('products').add(product.toFirestore());
  }
}
