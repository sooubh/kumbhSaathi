import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('No .env file found');
    return;
  }

  String? apiKey;
  for (final line in envFile.readAsLinesSync()) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey == null) {
    print('No API key found in .env');
    return;
  }

  print('Simulating Model Discovery...');
  try {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final models = (data['models'] as List<dynamic>?) ?? [];
      final names = models.map((m) => m['name'] as String).toList();

      String bestLiveModel = 'models/gemini-2.0-flash-exp';
      if (names.contains('models/gemini-3.1-flash-live-preview')) {
        bestLiveModel = 'models/gemini-3.1-flash-live-preview';
      } else if (names.contains('models/gemini-2.5-flash-live-preview')) {
        bestLiveModel = 'models/gemini-2.5-flash-live-preview';
      }

      print('Best Live Model Selected: $bestLiveModel');
      
      if (!names.contains(bestLiveModel)) {
        print('WARNING: Selected model $bestLiveModel is not in the list!');
      } else {
        print('SUCCESS: Selected model is available.');
      }
    } else {
      print('Error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
