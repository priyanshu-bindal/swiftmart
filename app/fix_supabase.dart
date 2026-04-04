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
    
    // Convert print('... error: $e') to debugPrint('... error: ${e.toString()}')
    c = c.replaceAll(RegExp(r"debugPrint\('Supabase (.+?) error: \$e'\);"), "debugPrint('Supabase \$1 error: \${e.toString()}');");
    
    // The prompt says "return safe fallback (empty list instead of crash)", which probably applies. 
    // They are returning null or nothing causing a crash, let's look at the fallback. We can just add 'return [];' in the catch.
    c = c.replaceAllMapped(RegExp(r"catch\s*\(e\)\s*\{\s*debugPrint\('Supabase (.+?) error: \$\{e\.toString\(\)\}'\);\s*(\})?"), (m) {
      if (m.group(2) != null) {
        return "catch (e) { \n    debugPrint('Supabase \${m.group(1)} error: \${e.toString()}');\n    return [];\n}";
      }
      return m.group(0)!; // if there are already other things, skip
    });
    
    file.writeAsStringSync(c);
  }
}
