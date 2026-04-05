import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://wfbxhuuvstahijtwsraf.supabase.co',
    'sb_publishable_0z4xzVT3isqJsF46-efEVw_QUwNAzx4',
  );

  print('Fetching products...');
  final products = await supabase.from('products').select('id, name, image_url, category');
  for (var p in products) {
    print('Product: ${p['name']} | image: ${p['image_url']} | category: ${p['category']}');
  }

  print('\nFetching categories...');
  final categories = await supabase.from('categories').select('id, name, image_url');
  for (var c in categories) {
    print('Category: ${c['name']} | image: ${c['image_url']}');
  }
}
