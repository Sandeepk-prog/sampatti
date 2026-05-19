class InvestmentAllocation {
  final String label;
  final double percentage;
  final String colorHex;

  InvestmentAllocation({
    required this.label,
    required this.percentage,
    required this.colorHex,
  });

  factory InvestmentAllocation.fromMap(Map<String, dynamic> map) {
    return InvestmentAllocation(
      label: map['label'] ?? '',
      percentage: (map['percentage'] ?? 0).toDouble(),
      colorHex: map['colorHex'] ?? '0xFF000000',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'percentage': percentage,
      'colorHex': colorHex,
    };
  }
}
