import 'package:flutter/widgets.dart';

void main() {
  const icon = IconData(0xe800, fontFamily: 'LucideIcons', fontPackage: 'lucide_icons');
  print('Family: ${icon.fontFamily}, Package: ${icon.fontPackage}, code: ${icon.codePoint}');
}
