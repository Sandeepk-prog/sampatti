class GridItemData {
  final String title;
  final int iconCodePoint;
  final String value;
  final String pl;
  final String insight;
  final String colorHex;

  GridItemData({
    required this.title,
    required this.iconCodePoint,
    required this.value,
    required this.pl,
    required this.insight,
    required this.colorHex,
  });

  factory GridItemData.fromFirestore(Map<String, dynamic> data) {
    return GridItemData(
      title: data['title'] ?? '',
      iconCodePoint: data['iconCodePoint'] ?? 0,
      value: data['value'] ?? '',
      pl: data['pl'] ?? '',
      insight: data['insight'] ?? '',
      colorHex: data['colorHex'] ?? '0xFFFFFFFF',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'iconCodePoint': iconCodePoint,
      'value': value,
      'pl': pl,
      'insight': insight,
      'colorHex': colorHex,
    };
  }
}
