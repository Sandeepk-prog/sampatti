class InsightData {
  final String title;
  final String subtitle;
  final int iconCodePoint;
  final String bgColorHex;
  final String iconColorHex;

  InsightData({
    required this.title,
    required this.subtitle,
    required this.iconCodePoint,
    required this.bgColorHex,
    required this.iconColorHex,
  });

  factory InsightData.fromFirestore(Map<String, dynamic> data) {
    return InsightData(
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      iconCodePoint: data['iconCodePoint'] ?? 0,
      bgColorHex: data['bgColorHex'] ?? '0xFFFFFFFF',
      iconColorHex: data['iconColorHex'] ?? '0xFF000000',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'iconCodePoint': iconCodePoint,
      'bgColorHex': bgColorHex,
      'iconColorHex': iconColorHex,
    };
  }
}
