class InvestmentHolding {
  final String id;
  final String userId;
  final String memberId;
  final String type;
  final String name;
  final String? ticker;
  final String? units;
  final double value;
  final String category;
  final String colorHex;

  InvestmentHolding({
    required this.id,
    required this.userId,
    required this.memberId,
    required this.type,
    required this.name,
    this.ticker,
    this.units,
    required this.value,
    required this.category,
    required this.colorHex,
  });

  factory InvestmentHolding.fromFirestore(String id, Map<String, dynamic> data) {
    return InvestmentHolding(
      id: id,
      userId: data['userId'] ?? '',
      memberId: data['memberId'] ?? '',
      type: data['type'] ?? '',
      name: data['name'] ?? '',
      ticker: data['ticker'],
      units: data['units'],
      value: (data['value'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      colorHex: data['colorHex'] ?? '0xFF000000',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'memberId': memberId,
      'type': type,
      'name': name,
      'ticker': ticker,
      'units': units,
      'value': value,
      'category': category,
      'colorHex': colorHex,
    };
  }
}
