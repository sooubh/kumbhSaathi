import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final envFile = File('.env');
  String? apiKey;
  for (final line in envFile.readAsLinesSync()) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }
  if (apiKey == null) return;

  final versions = ['v1beta', 'v1alpha'];
  for (final v in versions) {
    print('Checking $v...');
    final url = 'https://generativelanguage.googleapis.com/$v/models?key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final models = (data['models'] as List<dynamic>?) ?? [];
      for (final m in models) {
        final name = m['name'] as String;
        if (name.contains('live') || name.contains('2.5') || name.contains('3.1') || name.contains('flash')) {
          print('  Found: $name');
        }
      }
    }
  }
}
