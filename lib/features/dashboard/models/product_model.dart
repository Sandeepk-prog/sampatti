class ProductModel {
  final String id;
  final String title;
  final int iconCodePoint;
  final String colorHex;
  final String iconColorHex;

  ProductModel({
    required this.id,
    required this.title,
    required this.iconCodePoint,
    required this.colorHex,
    required this.iconColorHex,
  });

  factory ProductModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ProductModel(
      id: id,
      title: data['title'] ?? '',
      iconCodePoint: data['iconCodePoint'] ?? 0,
      colorHex: data['colorHex'] ?? '0xFFFFFFFF',
      iconColorHex: data['iconColorHex'] ?? '0xFF000000',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'iconCodePoint': iconCodePoint,
      'colorHex': colorHex,
      'iconColorHex': iconColorHex,
    };
  }
}
