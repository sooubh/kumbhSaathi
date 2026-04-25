import 'dart:async';
import 'dart:convert';
import 'dart:io';

String readApiKey() {
  final lines = File('.env').readAsLinesSync();
  for (final line in lines) {
    final l = line.trim();
    if (l.startsWith('GEMINI_API_KEY=')) {
      return l.substring('GEMINI_API_KEY='.length).trim();
    }
  }
  throw StateError('GEMINI_API_KEY not found');
}

Future<void> runCase(String model) async {
  final key = readApiKey();
  final wsUrl =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$key';

  stdout.writeln('=== model: $model ===');
  WebSocket? ws;
  try {
    ws = await WebSocket.connect(wsUrl);
    stdout.writeln('connected');

    final done = Completer<void>();

    ws.listen(
      (data) {
        final text = data is String ? data : utf8.decode(data as List<int>);
        stdout.writeln('message: ${text.length > 500 ? text.substring(0, 500) : text}');
      },
      onError: (e) {
        stdout.writeln('onError: $e');
        if (!done.isCompleted) done.complete();
      },
      onDone: () {
        stdout.writeln('onDone: code=${ws?.closeCode}, reason=${ws?.closeReason}');
        if (!done.isCompleted) done.complete();
      },
      cancelOnError: false,
    );

    final configMsg = {
      'config': {
        'model': model,
        'responseModalities': ['AUDIO'],
        'systemInstruction': {
          'parts': [
            {'text': 'You are a concise assistant. Reply in one line.'},
          ],
        },
      },
    };

    ws.add(jsonEncode(configMsg));
    stdout.writeln('config sent');

    // Try a text prompt after config to trigger a response.
    final textMsg = {
      'realtimeInput': {'text': 'Hello from websocket probe. Please reply.'},
    };
    ws.add(jsonEncode(textMsg));
    stdout.writeln('text sent');

    await done.future.timeout(const Duration(seconds: 10), onTimeout: () {
      stdout.writeln('timeout (session still open)');
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
  await runCase('models/gemini-2.5-flash-native-audio-preview-12-2025');
  await runCase('models/gemini-3.1-flash-live-preview');
}
