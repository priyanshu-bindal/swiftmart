import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://wfbxhuuvstahijtwsraf.supabase.co',
    'sb_publishable_0z4xzVT3isqJsF46-efEVw_QUwNAzx4',
  );

  final products = await supabase.from('products').select('*').limit(1);
  print(products);
}
