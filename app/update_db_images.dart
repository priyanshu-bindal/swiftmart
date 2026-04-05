import 'dart:convert';
import 'package:http/http.dart' as http;

final apiKey = 'sb_publishable_0z4xzVT3isqJsF46-efEVw_QUwNAzx4';
final baseUrl = 'https://wfbxhuuvstahijtwsraf.supabase.co/rest/v1';

Map<String, String> imageUrls = {
  'Mango': 'https://images.unsplash.com/photo-1553284965-83fd3e82fa5a?auto=format&fit=crop&w=400&q=80',
  'Fresh Mango': 'https://images.unsplash.com/photo-1553284965-83fd3e82fa5a?auto=format&fit=crop&w=400&q=80',
  'Banana': 'https://images.unsplash.com/photo-1528825871115-3581a5387919?auto=format&fit=crop&w=400&q=80',
  'Apple': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6faa6?auto=format&fit=crop&w=400&q=80',
  'Tomato': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=400&q=80',
  'Tomatoes': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=400&q=80',
  'Potato': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=400&q=80',
  'Potatoes': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=400&q=80',
  'Onion': 'https://images.unsplash.com/photo-1518977822534-7049a61ee0c2?auto=format&fit=crop&w=400&q=80',
  'Onions': 'https://images.unsplash.com/photo-1518977822534-7049a61ee0c2?auto=format&fit=crop&w=400&q=80',
  'Spinach': 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&w=400&q=80',
  'Carrot': 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?auto=format&fit=crop&w=400&q=80',
  'Whole Milk': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=400&q=80',
  'Amul Milk': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=400&q=80',
  'Amul Taaza Toned Milk': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=400&q=80',
  'Nestle Munch Milk': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=400&q=80',
  'Amul Butter': 'https://images.unsplash.com/photo-1588195538326-c5b1e9f80a1b?auto=format&fit=crop&w=400&q=80',
  'Amul Dahi Curd': 'https://images.unsplash.com/photo-1570197781387-c1eaab6eb46f?auto=format&fit=crop&w=400&q=80',
  'Paneer Fresh': 'https://images.unsplash.com/photo-1631452180519-c014fe946bc0?auto=format&fit=crop&w=400&q=80',
  'Monaco Classic Crackers': 'https://images.unsplash.com/photo-1590080874088-eec648e18f8e?auto=format&fit=crop&w=400&q=80',
  'Hide & Seek Chocolate Chips': 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?auto=format&fit=crop&w=400&q=80',
  'Parle-G Biscuits': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=400&q=80',
  'Maggi 2-Minute Noodles': 'https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?auto=format&fit=crop&w=400&q=80',
  'Tata Tea Premium': 'https://images.unsplash.com/photo-1597481499750-3e6b22637e12?auto=format&fit=crop&w=400&q=80',
  'Nescafe Classic Coffee': 'https://images.unsplash.com/photo-1559525839-b184a4d698c7?auto=format&fit=crop&w=400&q=80',
  'Real Fruit Juice Mixed': 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?auto=format&fit=crop&w=400&q=80',
  'Tropicana Orange Juice': 'https://images.unsplash.com/photo-1601114224767-f58c707d853e?auto=format&fit=crop&w=400&q=80',
  'Bisleri Water Bottle': 'https://plus.unsplash.com/premium_photo-1664302152996-2244eb1ce6d2?auto=format&fit=crop&w=400&q=80',
  'Horlicks Health Drink': 'https://images.unsplash.com/photo-1589182373726-e4f658ab50f0?auto=format&fit=crop&w=400&q=80',
  'Britannia Bread': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
  'Brown Bread Whole Wheat': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
  'English Muffins': 'https://images.unsplash.com/photo-1582294101680-e83fa41f173b?auto=format&fit=crop&w=400&q=80',
  'Britannia Good Day Butter': 'https://images.unsplash.com/photo-1557089706-68d01f11a432?auto=format&fit=crop&w=400&q=80',
  'Croissant Plain': 'https://images.unsplash.com/photo-1555507036-ab1f40ce88cb?auto=format&fit=crop&w=400&q=80',
  'Chicken Breast Boneless': 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=400&q=80',
  'Eggs Farm Fresh': 'https://images.unsplash.com/photo-1506976785307-8732e854ad03?auto=format&fit=crop&w=400&q=80',
  'Rohu Fish Fresh': 'https://images.unsplash.com/photo-1615141982883-c7ad0e69fd62?auto=format&fit=crop&w=400&q=80',
  'Prawns Medium': 'https://images.unsplash.com/photo-1559742811-822873691df8?auto=format&fit=crop&w=400&q=80',
  'Mutton Curry Cut': 'https://images.unsplash.com/photo-1603048297172-c92544798d5e?auto=format&fit=crop&w=400&q=80',
  'Lay\'s Classic Salted Chips': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Lay%27s_Potato_Chips_Original.jpg/800px-Lay%27s_Potato_Chips_Original.jpg',
  'Kurkure Masala Munch': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Kurkure.jpg/800px-Kurkure.jpg',
  'Dove Soap Bar': 'https://images.unsplash.com/photo-1600857062241-98e5dba7f214?auto=format&fit=crop&w=400&q=80',
  'Head & Shoulders Shampoo': 'https://images.unsplash.com/photo-1599305090598-fe179d501227?auto=format&fit=crop&w=400&q=80',
  'Colgate Strong Teeth': 'https://images.unsplash.com/photo-1559564104-eeb19c238b68?auto=format&fit=crop&w=400&q=80',
  'Dettol Hand Wash': 'https://images.unsplash.com/photo-1584305574647-0cc9deac258f?auto=format&fit=crop&w=400&q=80',
  'Vaseline Body Lotion': 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=400&q=80',
  'Surf Excel Matic Powder': 'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?auto=format&fit=crop&w=400&q=80',
  'Vim Dishwash Bar': 'https://images.unsplash.com/photo-1585670149967-b4f4da88cc9f?auto=format&fit=crop&w=400&q=80',
  'Harpic Toilet Cleaner': 'https://images.unsplash.com/photo-1584813470613-28ad1779872e?auto=format&fit=crop&w=400&q=80',
  'Good Knight Mosquito Coil': 'https://images.unsplash.com/photo-1596489370605-72d829986b8f?auto=format&fit=crop&w=400&q=80',
  'Scotch-Brite Scrub Pad': 'https://images.unsplash.com/photo-1585670210693-e7fdd16b14d8?auto=format&fit=crop&w=400&q=80',
  'Papaya Semi Ripe': 'https://images.unsplash.com/photo-1517282009859-f000ec3b26fe?auto=format&fit=crop&w=400&q=80',
  'Watermelon Kiran': 'https://images.unsplash.com/photo-1587049352847-81a56d773c1c?auto=format&fit=crop&w=400&q=80',
  'Apple Royal Gala': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6faa6?auto=format&fit=crop&w=400&q=80',
  'Capsicum Green': 'https://images.unsplash.com/photo-1563514948011-002d75f2845a?auto=format&fit=crop&w=400&q=80',
  'Carrot Orange': 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?auto=format&fit=crop&w=400&q=80',
  'Fresh Onion (Pyaz)': 'https://images.unsplash.com/photo-1518977822534-7049a61ee0c2?auto=format&fit=crop&w=400&q=80',
  'Potato (Aloo)': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=400&q=80',
  'Tomato Hybrid': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=400&q=80',
  'Grapes Green Seedless': 'https://images.unsplash.com/photo-1537640538966-79f369143f8f?auto=format&fit=crop&w=400&q=80',
};

String getFallbackImage(String name) {
  if (name.toLowerCase().contains('mango')) return 'https://images.unsplash.com/photo-1553284965-83fd3e82fa5a?auto=format&fit=crop&w=400&q=80';
  if (name.toLowerCase().contains('apple')) return 'https://images.unsplash.com/photo-1560806887-1e4cd0b6faa6?auto=format&fit=crop&w=400&q=80';
  if (name.toLowerCase().contains('tomato')) return 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=400&q=80';
  if (name.toLowerCase().contains('potato')) return 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=400&q=80';
  if (name.toLowerCase().contains('onion')) return 'https://images.unsplash.com/photo-1518977822534-7049a61ee0c2?auto=format&fit=crop&w=400&q=80';
  if (name.toLowerCase().contains('banana')) return 'https://images.unsplash.com/photo-1528825871115-3581a5387919?auto=format&fit=crop&w=400&q=80';
  if (name.toLowerCase().contains('milk')) return 'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=400&q=80';
  return 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80'; // grocery abstract
}

void main() async {
  // 1. Fetch current products
  final url = Uri.parse('$baseUrl/products?select=id,name');
  final response = await http.get(url, headers: {
    'apikey': apiKey,
    'Authorization': 'Bearer $apiKey',
  });
  
  if (response.statusCode == 200) {
    final List<dynamic> products = jsonDecode(response.body);
    int count = 0;
    
    for (var p in products) {
      final name = p['name'] as String;
      final id = p['id'] as String;
      
      String newUrl = imageUrls[name] ?? getFallbackImage(name);
      
      // 2. Perform UPDATE
      final updateUrl = Uri.parse('$baseUrl/products?id=eq.$id');
      final updateRes = await http.patch(
        updateUrl,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal'
        },
        body: jsonEncode({'image_url': newUrl})
      );
      
      if (updateRes.statusCode >= 200 && updateRes.statusCode < 300) {
        print('Updated $name');
        count++;
      } else {
        print('Failed to update $name: ${updateRes.body}');
      }
    }
    print('Completed updating $count / ${products.length} products.\\n');
  } else {
    print('Failed to fetch data: ${response.statusCode} - ${response.body}');
  }
}
