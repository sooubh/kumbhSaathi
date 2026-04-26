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

  print('Listing v1beta models...');
  final urlBeta = 'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';
  
  print('Listing v1alpha models...');
  final urlAlpha = 'https://generativelanguage.googleapis.com/v1alpha/models?key=$apiKey';
  
  try {
    final responseBeta = await http.get(Uri.parse(urlBeta));
    if (responseBeta.statusCode == 200) {
      final data = jsonDecode(responseBeta.body);
      final models = data['models'] as List<dynamic>;
      print('--- v1beta ---');
      for (final model in models) {
        final name = model['name'];
        final methods = model['supportedGenerationMethods'] as List<dynamic>;
        print('- $name: $methods');
      }
    }

    final responseAlpha = await http.get(Uri.parse(urlAlpha));
    if (responseAlpha.statusCode == 200) {
      final data = jsonDecode(responseAlpha.body);
      final models = data['models'] as List<dynamic>;
      print('--- v1alpha ---');
      for (final model in models) {
        final name = model['name'];
        final methods = model['supportedGenerationMethods'] as List<dynamic>;
        print('- $name: $methods');
      }
    }
  } catch (e) {
    print('Exception: $e');
  }
}
