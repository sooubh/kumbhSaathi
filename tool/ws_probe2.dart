import 'dart:async';
import 'dart:convert';
import 'dart:io';

String readApiKey() {
  final lines = File('.env').readAsLinesSync();
  for (final raw in lines) {
    final line = raw.trim();
    if (line.startsWith('GEMINI_API_KEY=')) {
      return line.substring('GEMINI_API_KEY='.length).trim();
    }
  }
  throw StateError('GEMINI_API_KEY not found in .env');
}

Map<String, dynamic> setupMinimal(String model) => {
      'setup': {
        'model': model,
      },
    };

Map<String, dynamic> setupTextOnlySnake(String model) => {
      'setup': {
        'model': model,
        'generation_config': {
          'response_modalities': ['TEXT'],
        },
      },
    };

Map<String, dynamic> setupAudioSnake(String model) => {
      'setup': {
        'model': model,
        'generation_config': {
          'response_modalities': ['AUDIO', 'TEXT'],
          'speech_config': {
            'voice_config': {
              'prebuilt_voice_config': {'voice_name': 'Aoede'},
            },
          },
        },
      },
    };

Future<void> probe(
  String endpoint,
  String label,
  Map<String, dynamic> payload,
) async {
  stdout.writeln('--- $label @ $endpoint ---');
  WebSocket? ws;

  try {
    ws = await WebSocket.connect(endpoint);
    stdout.writeln('connected');

    final done = Completer<void>();

    ws.listen(
      (message) {
        final text = message is String ? message : utf8.decode(message as List<int>);
        stdout.writeln('message: ${text.length > 300 ? text.substring(0, 300) : text}');
      },
      onDone: () {
        stdout.writeln('onDone: code=${ws?.closeCode}, reason=${ws?.closeReason}');
        if (!done.isCompleted) done.complete();
      },
      onError: (e) {
        stdout.writeln('onError: $e');
        if (!done.isCompleted) done.complete();
      },
      cancelOnError: false,
    );

    ws.add(jsonEncode(payload));
    stdout.writeln('setup sent');

    await done.future.timeout(const Duration(seconds: 8), onTimeout: () {
      stdout.writeln('timeout (connection stayed open)');
    });

    await ws.close();
  } catch (e) {
    stdout.writeln('exception: $e');
    try {
      await ws?.close();
    } catch (_) {}
  }

  stdout.writeln('');
}

Future<void> main() async {
  final key = readApiKey();
  final endpoints = [
    'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$key',
    'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$key',
  ];

  final models = [
    'models/gemini-3.1-flash-live-preview',
    'models/gemini-2.5-flash-native-audio-preview-12-2025',
    'models/gemini-2.5-flash',
  ];

  for (final endpoint in endpoints) {
    for (final model in models) {
      await probe(endpoint, '$model minimal', setupMinimal(model));
      await probe(endpoint, '$model textOnly', setupTextOnlySnake(model));
      await probe(endpoint, '$model audio', setupAudioSnake(model));
    }
  }
}
