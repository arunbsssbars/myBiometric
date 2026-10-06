import 'dart:io';

void main(List<String> args) {
  final path = args.isNotEmpty ? args[0] : 'lib/views/terminal_punch_injection_screen.dart';
  final file = File(path);
  final content = file.readAsStringSync();
  final regex = RegExp(r'\bColors\.(white|black|red|green|blue|grey|amber|orange|purple|cyan|teal|yellow|indigo|pink|brown|lightBlue|deepOrange|blueGrey)\b|Color\(0x[0-9a-fA-F]+\)|fontSize:\s*[0-9]+');
  final lines = content.split('\n');
  print('--- Debug matches in $path ---');
  for (int i = 0; i < lines.length; i++) {
    final matches = regex.allMatches(lines[i]);
    if (matches.isNotEmpty) {
      for (final m in matches) {
        print('${i + 1}: ${m.group(0)}  -->  ${lines[i].trim()}');
      }
    }
  }
}
