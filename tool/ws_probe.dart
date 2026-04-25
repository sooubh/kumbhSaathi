import 'dart:async';
import 'dart:convert';
import 'dart:io';

String readApiKey() {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    throw StateError('.env file not found in project root');
  }

  final lines = envFile.readAsLinesSync();
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    if (!line.startsWith('GEMINI_API_KEY=')) continue;
    final key = line.substring('GEMINI_API_KEY='.length).trim();
    if (key.isNotEmpty) return key;
  }

  throw StateError('GEMINI_API_KEY not found in .env');
}

Map<String, dynamic> setupSnake(String model) {
  return {
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
      'system_instruction': {
        'parts': [
          {'text': 'You are a test assistant. Reply briefly.'},
        ],
      },
    },
  };
}

Map<String, dynamic> setupCamel(String model) {
  return {
    'setup': {
      'model': model,
      'generationConfig': {
        'responseModalities': ['AUDIO', 'TEXT'],
        'speechConfig': {
          'voiceConfig': {
            'prebuiltVoiceConfig': {'voiceName': 'Aoede'},
          },
        },
      },
      'systemInstruction': {
        'parts': [
          {'text': 'You are a test assistant. Reply briefly.'},
        ],
      },
    },
  };
}

Future<void> probe({
  required String label,
  required Uri uri,
  required Map<String, dynamic> setup,
}) async {
  stdout.writeln('---- $label ----');
  WebSocket? ws;

  try {
    ws = await WebSocket.connect(uri.toString());
    stdout.writeln('connected');

    final done = Completer<void>();

    ws.listen(
      (message) {
        final text = message is String ? message : utf8.decode(message as List<int>);
        stdout.writeln('message: ${text.length > 500 ? text.substring(0, 500) : text}');
      },
      onError: (e) {
        stdout.writeln('onError: $e');
        if (!done.isCompleted) done.complete();
      },
      onDone: () {
        stdout.writeln('onDone: closeCode=${ws?.closeCode}, closeReason=${ws?.closeReason}');
        if (!done.isCompleted) done.complete();
      },
      cancelOnError: false,
    );

    ws.add(jsonEncode(setup));
    stdout.writeln('setup sent');

    // Wait for any response/close up to 8 seconds.
    await done.future.timeout(const Duration(seconds: 8), onTimeout: () {
      stdout.writeln('timeout waiting for response/close');
    });

    try {
      await ws.close();
    } catch (_) {}
  } catch (e) {
    stdout.writeln('connect/send exception: $e');
    try {
      await ws?.close();
    } catch (_) {}
  }
}

Future<void> main() async {
  final key = readApiKey();
  final uri = Uri.parse(
    'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$key',
  );

  final cases = <({String label, Map<String, dynamic> setup})>[
    (
      label: 'snake + models/gemini-2.0-flash-exp',
      setup: setupSnake('models/gemini-2.0-flash-exp'),
    ),
    (
      label: 'snake + models/gemini-2.0-flash-live-001',
      setup: setupSnake('models/gemini-2.0-flash-live-001'),
    ),
    (
      label: 'camel + models/gemini-2.0-flash-exp',
      setup: setupCamel('models/gemini-2.0-flash-exp'),
    ),
    (
      label: 'camel + models/gemini-2.0-flash-live-001',
      setup: setupCamel('models/gemini-2.0-flash-live-001'),
    ),
    (
      label: 'snake + models/gemini-3.1-flash-live-preview',
      setup: setupSnake('models/gemini-3.1-flash-live-preview'),
    ),
    (
      label: 'camel + models/gemini-3.1-flash-live-preview',
      setup: setupCamel('models/gemini-3.1-flash-live-preview'),
    ),
    (
      label: 'snake + models/gemini-2.5-flash-native-audio-preview-12-2025',
      setup: setupSnake('models/gemini-2.5-flash-native-audio-preview-12-2025'),
    ),
    (
      label: 'camel + models/gemini-2.5-flash-native-audio-preview-12-2025',
      setup: setupCamel('models/gemini-2.5-flash-native-audio-preview-12-2025'),
    ),
  ];

  for (final c in cases) {
    await probe(label: c.label, uri: uri, setup: c.setup);
    stdout.writeln('');
  }
}
