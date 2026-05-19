import 'aum_data.dart';
import 'chart_data_point.dart';
import 'product_model.dart';
import 'allocation_data.dart';
import 'insight_data.dart';
import 'grid_item_data.dart';

class HomeData {
  final AumData aumData;
  final List<ChartDataPoint> chartData;
  final List<ProductModel> products;
  final List<AllocationData> allocations;
  final List<InsightData> insights;
  final List<GridItemData> gridItems;

  HomeData({
    required this.aumData,
    required this.chartData,
    required this.products,
    required this.allocations,
    required this.insights,
    required this.gridItems,
  });
}
