import 'dart:io';

void main() {
  final dir = Directory('lib/views');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  // Real material colors like Colors.white, Colors.black, Colors.red, Colors.blue, etc.
  // OR Color(0xFF...) OR fontSize: \d+
  // (Excluding Colors.transparent)
  final regex = RegExp(r'\bColors\.(white|black|red|green|blue|grey|amber|orange|purple|cyan|teal|yellow|indigo|pink|brown|lightBlue|deepOrange|blueGrey)\b|Color\(0x[0-9a-fA-F]+\)|fontSize:\s*[0-9]+');
  final results = <MapEntry<String, int>>[];

  for (final file in files) {
    final content = file.readAsStringSync();
    final matches = regex.allMatches(content);
    if (matches.isNotEmpty) {
      results.add(MapEntry(file.path, matches.length));
    }
  }

  results.sort((a, b) => b.value.compareTo(a.value));
  print('=== STRICT AQIL DEBT BY FILE (EXCLUDING Colors.transparent) ===');
  int total = 0;
  for (final entry in results) {
    print('${entry.value.toString().padLeft(4)} : ${entry.key}');
    final lines = File(entry.key).readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (regex.hasMatch(line)) {
        print('       L${i + 1}: ${line.trim()}');
      }
    }
    total += entry.value;
  }
  print('================================================================');
  print('TOTAL STRICT DEBT: $total instances in ${results.length} files');
}
