import 'dart:io';

void main() {
  final pubCache = Platform.environment['PUB_CACHE'] ?? 
      '${Platform.environment['LOCALAPPDATA']}\\Pub\\Cache';
  print('PUB_CACHE: $pubCache');
  
  final hostedDir = Directory('$pubCache\\hosted\\pub.dev');
  if (hostedDir.existsSync()) {
    final qcfDirs = hostedDir.listSync().where((d) => d.path.contains('qcf_quran'));
    for (var dir in qcfDirs) {
      print('Found: ${dir.path}');
      final pubspec = File('${dir.path}\\pubspec.yaml');
      if (pubspec.existsSync()) {
        print(pubspec.readAsStringSync());
      }
    }
  } else {
    print('hosted dir not found');
  }
}
