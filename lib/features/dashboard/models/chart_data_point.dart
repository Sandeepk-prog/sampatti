class ChartDataPoint {
  final String month;
  final double value;

  ChartDataPoint({
    required this.month,
    required this.value,
  });

  factory ChartDataPoint.fromFirestore(Map<String, dynamic> data) {
    return ChartDataPoint(
      month: data['month'] ?? '',
      value: (data['value'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'month': month,
      'value': value,
    };
  }
}
