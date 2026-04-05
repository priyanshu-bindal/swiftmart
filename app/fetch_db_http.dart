import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://wfbxhuuvstahijtwsraf.supabase.co/rest/v1/products?select=id,name,category,image_url');
  final response = await http.get(url, headers: {
    'apikey': 'sb_publishable_0z4xzVT3isqJsF46-efEVw_QUwNAzx4',
    'Authorization': 'Bearer sb_publishable_0z4xzVT3isqJsF46-efEVw_QUwNAzx4',
  });
  
  final file = File('db_dump.txt');
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    final buffer = StringBuffer();
    for (var p in data) {
      buffer.writeln('ID: ${p['id']} - Name: ${p['name']} - Cat: ${p['category']} - Img: ${p['image_url']}');
    }
    await file.writeAsString(buffer.toString());
    print('Dumped ${data.length} records to db_dump.txt');
  } else {
    print('Failed: ${response.statusCode} - ${response.body}');
    await file.writeAsString('Failed: ${response.statusCode} - ${response.body}');
  }
}
