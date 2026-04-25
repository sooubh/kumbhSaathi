import 'dart:async';
import 'dart:convert';
import 'dart:io';

String key() {
  for (final line in File('.env').readAsLinesSync()) {
    final t = line.trim();
    if (t.startsWith('GEMINI_API_KEY=')) {
      return t.substring('GEMINI_API_KEY='.length).trim();
    }
  }
  throw StateError('No GEMINI_API_KEY');
}

Future<void> runProbe(Map<String, dynamic> setup, String label) async {
  final wsUrl =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=${key()}';

  stdout.writeln('--- $label ---');
  final ws = await WebSocket.connect(wsUrl);
  stdout.writeln('connected');

  final done = Completer<void>();

  ws.listen(
    (data) {
      final msg = data is String ? data : utf8.decode(data as List<int>);
      stdout.writeln('message: ${msg.length > 400 ? msg.substring(0, 400) : msg}');
    },
    onDone: () {
      stdout.writeln('done code=${ws.closeCode} reason=${ws.closeReason}');
      if (!done.isCompleted) done.complete();
    },
    onError: (e) {
      stdout.writeln('error: $e');
      if (!done.isCompleted) done.complete();
    },
    cancelOnError: false,
  );

  ws.add(jsonEncode({'setup': setup}));
  stdout.writeln('setup sent');

  // Send a short text turn via realtimeInput
  ws.add(jsonEncode({
    'realtimeInput': {'text': 'Hello. Please say hi in one short line.'},
  }));
  stdout.writeln('text input sent');

  await done.future.timeout(const Duration(seconds: 10), onTimeout: () {
    stdout.writeln('timeout (still connected)');
  });

  await ws.close();
  stdout.writeln('');
}

Future<void> main() async {
  await runProbe({
    'model': 'models/gemini-2.5-flash-native-audio-preview-12-2025',
    'generationConfig': {
      'responseModalities': ['AUDIO'],
    },
  }, '2.5 native audio, AUDIO only');

  await runProbe({
    'model': 'models/gemini-2.5-flash-native-audio-preview-12-2025',
    'generationConfig': {
      'responseModalities': ['AUDIO', 'TEXT'],
    },
  }, '2.5 native audio, AUDIO+TEXT');

  await runProbe({
    'model': 'models/gemini-3.1-flash-live-preview',
    'generationConfig': {
      'responseModalities': ['AUDIO'],
    },
  }, '3.1 live preview, AUDIO only');
}
