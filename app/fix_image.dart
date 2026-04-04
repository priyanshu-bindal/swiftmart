import 'dart:io';

void main() {
  final dir = Directory('d:/Apps/swiftmart/app/lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (var file in files) {
    if (!file.path.contains('fix_image')) {
      var content = file.readAsStringSync();
      // Simple regex replace for CachedNetworkImage missing errorWidget
      content = content.replaceAll(RegExp(r'CachedNetworkImage\(\s*imageUrl:\s*([^,]+),\s*fit:\s*BoxFit\.cover\s*\)'), 
        'CachedNetworkImage(imageUrl: \\1, fit: BoxFit.cover, errorWidget: (context, url, error) => const Icon(Icons.error), placeholder: (context, url) => const Center(child: CircularProgressIndicator()))');
      
      file.writeAsStringSync(content);
    }
  }
}
