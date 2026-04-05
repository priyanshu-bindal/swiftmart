import 'package:supabase/supabase.dart';
import 'dart:convert';
import 'dart:io';

void main() async {
  final supabase = SupabaseClient(
    'https://wfbxhuuvstahijtwsraf.supabase.co',
    'sb_publishable_0z4xzVT3isqJsF46-efEVw_QUwNAzx4',
  );

  final products = await supabase.from('products').select('*').limit(1);
  File('test_output.json').writeAsStringSync(jsonEncode(products));
}
