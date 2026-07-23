import 'dart:io';

void main() {
  print('=============================================');
  print('QCF Font Asset Verification Script');
  print('=============================================');

  // Determine pub cache path
  final pubCache = Platform.environment['PUB_CACHE'] ?? 
      '${Platform.environment['LOCALAPPDATA']}\\Pub\\Cache';
  
  final hostedDir = Directory('$pubCache\\hosted\\pub.dev');
  if (!hostedDir.existsSync()) {
    print('❌ Error: pub cache hosted directory not found at $hostedDir');
    return;
  }

  // Find qcf_quran package directory
  final qcfDirs = hostedDir.listSync().where((d) => d.path.contains('qcf_quran'));
  if (qcfDirs.isEmpty) {
    print('❌ Error: qcf_quran package not found in pub cache. Have you run "flutter pub get"?');
    return;
  }

  final qcfDir = qcfDirs.first;
  final pubspecFile = File('${qcfDir.path}\\pubspec.yaml');
  
  if (!pubspecFile.existsSync()) {
    print('❌ Error: pubspec.yaml not found inside qcf_quran package at ${qcfDir.path}');
    return;
  }

  print('Analyzing qcf_quran package at: ${qcfDir.path}');
  final pubspecContent = pubspecFile.readAsStringSync();

  final List<int> missingPages = [];
  int foundCount = 0;

  for (int page = 1; page <= 604; page++) {
    final pageStr = page.toString().padLeft(3, '0');
    final fontName = 'QCF_P$pageStr';
    
    if (!pubspecContent.contains('family: $fontName')) {
      missingPages.add(page);
    } else {
      foundCount++;
    }
  }

  print('\nSummary:');
  print('Found $foundCount QCF page fonts properly declared.');
  
  if (missingPages.isEmpty) {
    print('✅ SUCCESS: All 604 page fonts are correctly bundled in the package!');
  } else {
    print('❌ WARNING: ${missingPages.length} fonts are missing from the package declaration.');
    print('Missing Pages: $missingPages');
    print('\nAction Required: Ensure the app includes a fallback text renderer (like Standard Uthmani)');
    print('for these specific pages to prevent raw mapping gibberish.');
  }
}
