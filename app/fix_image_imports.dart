import 'dart:io';

void main() {
  final dir = Directory('d:/Apps/swiftmart/app/lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (var file in files) {
    if (file.path.contains('app_network_image.dart')) continue;
    
    var content = file.readAsStringSync();
    if (content.contains('package:swiftmart/shared/widgets/app_network_image.dart')) {
      content = content.replaceAll(
          "package:swiftmart/shared/widgets/app_network_image.dart", 
          "package:app/shared/widgets/app_network_image.dart");
      file.writeAsStringSync(content);
      print('Fixed import in ${file.path}');
    }
  }
}
