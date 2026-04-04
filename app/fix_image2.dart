import 'dart:io';

void main() {
  final files = [
    'lib/features/cart/cart_screen.dart',
    'lib/features/deals/widgets/deal_card.dart',
    'lib/features/home/sdui_renderer.dart',
    'lib/features/products/product_detail_screen.dart',
    'lib/widgets/product_card.dart',
    'lib/shared/widgets/product_card.dart'
  ];

  final r = RegExp(r"CachedNetworkImage\(\s*imageUrl:\s*([^,)]+)(,\s*fit:\s*BoxFit\.[a-zA-Z]+)?\s*\)", multiLine: true);

  for (var f in files) {
    try {
      final file = File('d:/Apps/swiftmart/app/$f');
      if (!file.existsSync()) continue;
      String content = file.readAsStringSync();
      int matches = 0;
      content = content.replaceAllMapped(r, (m) {
        matches++;
        String url = m.group(1)!;
        String fit = m.group(2) ?? '';
        return 'CachedNetworkImage(imageUrl: $url $fit, placeholder: (context, url) => const Center(child: CircularProgressIndicator()), errorWidget: (context, url, error) => const Icon(Icons.broken_image))';
      });
      print('Fixed $matches in $f');
      file.writeAsStringSync(content);
    } catch (e) {
      print('Error $e');
    }
  }
}
