// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final lines = File('lib/controllers/quran_audio_controller.dart').readAsLinesSync();
  int count = 0;
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().startsWith('//')) continue;
    
    // Very basic parsing ignoring string literals since we don't have complex ones here
    for (int j = 0; j < line.length; j++) {
      if (line[j] == '{') count++;
      if (line[j] == '}') count--;
    }
    
    if (count < 0) {
      print('Negative count at line ${i+1}: $line');
      return;
    }
  }
  print('Final brace count: $count');
}
