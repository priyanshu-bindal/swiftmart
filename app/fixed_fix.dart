import 'dart:io';

void main() {
  final files = [
    'd:/Apps/swiftmart/app/lib/features/deals/providers/flash_deals_provider.dart',
    'd:/Apps/swiftmart/app/lib/features/offers/providers/coupons_provider.dart',
  ];

  for (var path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    var c = file.readAsStringSync();
    
    c = c.replaceAll(RegExp(r"debugPrint\('Supabase \$1 error: \$\{e\.toString\(\)\}'\);"), "debugPrint('Supabase error: \${e.toString()}');");
    c = c.replaceAll(RegExp(r"debugPrint\('Supabase (.+?) error: \$e'\);"), "debugPrint('Supabase \$1 error: \${e.toString()}');");
    
    c = c.replaceAll("rethrow;", "return [];");
    
    file.writeAsStringSync(c);
  }
}
