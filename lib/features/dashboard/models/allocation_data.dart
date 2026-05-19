class AllocationData {
  final String label;
  final String colorHex;
  final double percentage;

  AllocationData({
    required this.label,
    required this.colorHex,
    required this.percentage,
  });

  factory AllocationData.fromFirestore(Map<String, dynamic> data) {
    return AllocationData(
      label: data['label'] ?? '',
      colorHex: data['colorHex'] ?? '0x00000000',
      percentage: (data['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'label': label,
      'colorHex': colorHex,
      'percentage': percentage,
    };
  }
}
