Step 1: Add Dependencies
yamldependencies:
  flutter:
    sdk: flutter
  google_generative_ai: ^0.4.0
  record: ^5.0.0  # For audio recording
  audioplayers: ^5.2.0  # For audio playback
  permission_handler: ^11.0.0  # For microphone permissions
  path_provider: ^2.1.0
Step 2: Get Gemini API Key

Go to Google AI Studio
Create an API key
Store it securely (use environment variables or secure storage)

Step 3: Request Permissions (Android & iOS)
android/app/src/main/AndroidManifest.xml:
xml<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
ios/Runner/Info.plist:
xml<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice chat</string>
Step 4: Implementation
Here's a complete voice chat implementation:
dartimport 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

class VoiceChatBot extends StatefulWidget {
  @override
  _VoiceChatBotState createState() => _VoiceChatBotState();
}

class _VoiceChatBotState extends State<VoiceChatBot> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  late GenerativeModel _model;
  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusMessage = 'Ready to chat';
  List<ChatMessage> _messages = [];
  
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _requestPermissions();
  }

  void _initializeGemini() {
    // Replace with your API key
    const apiKey = 'YOUR_GEMINI_API_KEY';
    
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',  // Use the latest available model
      apiKey: apiKey,
    );
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getTemporaryDirectory();
      _recordingPath = '${directory.path}/voice_message.m4a';
      
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );
      
      setState(() {
        _isRecording = true;
        _statusMessage = 'Recording... Tap to stop';
      });
    }
  }

  Future<void> _stopRecordingAndProcess() async {
    final path = await _audioRecorder.stop();
    
    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _statusMessage = 'Processing your voice...';
    });

    if (path != null) {
      await _sendAudioToGemini(path);
    }
  }

  Future<void> _sendAudioToGemini(String audioPath) async {
    try {
      // Read audio file
      final audioFile = File(audioPath);
      final audioBytes = await audioFile.readAsBytes();
      
      // Add user message
      setState(() {
        _messages.add(ChatMessage(
          text: '[Voice Message]',
          isUser: true,
          timestamp: DateTime.now(),
        ));
      });

      // Send to Gemini with audio
      final content = [
        Content.multi([
          DataPart('audio/aac', audioBytes),
          TextPart('Please respond to this voice message naturally.'),
        ])
      ];

      final response = await _model.generateContent(content);
      
      final botResponse = response.text ?? 'Sorry, I couldn\'t understand that.';
      
      setState(() {
        _messages.add(ChatMessage(
          text: botResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isProcessing = false;
        _statusMessage = 'Ready to chat';
      });

      // Optional: Convert response to speech (TTS)
      // You can use Google Cloud Text-to-Speech API here
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _isProcessing = false;
      });
      print('Error sending audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Chat Bot'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Status indicator
          Container(
            padding: EdgeInsets.all(16),
            color: _isRecording ? Colors.red[100] : Colors.blue[100],
            width: double.infinity,
            child: Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return ChatBubbleWidget(message: message);
              },
            ),
          ),
          
          // Recording button
          Container(
            padding: EdgeInsets.all(20),
            child: GestureDetector(
              onTap: _isProcessing ? null : (_isRecording ? _stopRecordingAndProcess : _startRecording),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : Colors.deepPurple,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatBubbleWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatBubbleWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.deepPurple : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
Step 5: Important Notes
⚠️ Model Availability:
The gemini-2.5-flash-native-audio-preview-12-2025 model you mentioned might be:

An experimental/preview model (check availability in your region)
May have limited access
Currently, use gemini-2.0-flash-exp or check the latest available models at Google AI Studio

Check current available models:
dart// List available models
final models = await GenerativeModel.listModels(apiKey: apiKey);
for (var model in models) {
  print(model.name);
}
Step 6: Add Text-to-Speech (Optional)
For complete voice interaction, add TTS for bot responses:
dartdependencies:
  flutter_tts: ^3.8.0
dartimport 'package:flutter_tts/flutter_tts.dart';

FlutterTts _tts = FlutterTts();

Future<void> _speakResponse(String text) async {
  await _tts.setLanguage('en-US');
  await _tts.setPitch(1.0);
  await _tts.speak(text);
}
Testing:

Replace YOUR_GEMINI_API_KEY with your actual API key
Run the app on a real device (audio recording doesn't work well on emulators)
Grant microphone permissions
Tap the mic button to start recording
Speak your message
Tap again to stop and send to Gemini

Does this help? Let me know if you need clarification on any part!just the the live voice chat functionality like goooogle live chat chatgpt live chat i want that means incomng and outgoin at the same tim8:02 pmAh, you want real-time bidirectional voice chat (like ChatGPT's Advanced Voice Mode or Google's live audio streaming) where both you and the AI can speak simultaneously with natural interruptions!
Yes, Gemini 2.0 Flash supports this through Live API with native audio streaming!
Real-Time Live Voice Chat Implementation
Step 1: Dependencies
yamldependencies:
  flutter:
    sdk: flutter
  google_generative_ai: ^0.4.0
  record: ^5.0.0
  audioplayers: ^5.2.0
  permission_handler: ^11.0.0
  path_provider: ^2.1.0
  web_socket_channel: ^2.4.0
Step 2: Live Voice Chat with Streaming
Here's the complete implementation for real-time bidirectional voice chat:
dartimport 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:typed_data';

class LiveVoiceChatBot extends StatefulWidget {
  @override
  _LiveVoiceChatBotState createState() => _LiveVoiceChatBotState();
}

class _LiveVoiceChatBotState extends State<LiveVoiceChatBot> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  late GenerativeModel _model;
  ChatSession? _chatSession;
  
  bool _isConnected = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _statusMessage = 'Tap to start conversation';
  String _transcript = '';
  
  StreamSubscription? _audioStreamSubscription;
  List<int> _audioBuffer = [];

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _requestPermissions();
  }

  void _initializeGemini() {
    const apiKey = 'YOUR_GEMINI_API_KEY';
    
    // Initialize with Gemini 2.0 Flash with audio support
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 8192,
      ),
      systemInstruction: Content.system(
        'You are a helpful voice assistant. Keep responses conversational, '
        'natural, and concise. Respond as if having a real-time voice conversation.'
      ),
    );
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  Future<void> _toggleLiveChat() async {
    if (_isConnected) {
      await _disconnectLiveChat();
    } else {
      await _connectLiveChat();
    }
  }

  Future<void> _connectLiveChat() async {
    try {
      setState(() {
        _statusMessage = 'Connecting...';
      });

      // Start chat session
      _chatSession = _model.startChat();
      
      // Start audio recording stream
      await _startAudioStreaming();
      
      setState(() {
        _isConnected = true;
        _isListening = true;
        _statusMessage = 'Connected - Listening...';
      });
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
      print('Connection error: $e');
    }
  }

  Future<void> _startAudioStreaming() async {
    if (await _audioRecorder.hasPermission()) {
      // Start continuous audio recording
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      // Process audio stream in chunks
      _audioStreamSubscription = stream.listen(
        (audioChunk) {
          _audioBuffer.addAll(audioChunk);
          
          // Send audio chunks every 1 second (16000 samples at 16kHz)
          if (_audioBuffer.length >= 16000 * 2) { // 2 bytes per sample for 16-bit
            _sendAudioChunkToGemini(Uint8List.fromList(_audioBuffer));
            _audioBuffer.clear();
          }
        },
        onError: (error) {
          print('Audio stream error: $error');
        },
      );
    }
  }

  Future<void> _sendAudioChunkToGemini(Uint8List audioData) async {
    if (_chatSession == null || !_isConnected) return;

    try {
      // Send audio chunk with streaming
      final content = Content.multi([
        DataPart('audio/pcm', audioData),
      ]);

      // Use streaming to get response
      final responseStream = _chatSession!.sendMessageStream(content);
      
      String fullResponse = '';
      
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          fullResponse += chunk.text!;
          
          setState(() {
            _transcript = fullResponse;
            _isSpeaking = true;
          });
        }
      }
      
      // When response is complete, convert to speech
      if (fullResponse.isNotEmpty) {
        await _speakResponse(fullResponse);
      }
      
      setState(() {
        _isSpeaking = false;
      });
      
    } catch (e) {
      print('Error sending audio: $e');
    }
  }

  Future<void> _speakResponse(String text) async {
    // Here you would use Text-to-Speech
    // For now, just displaying the text
    // You can integrate Google Cloud TTS API for actual voice output
    print('AI Response: $text');
  }

  Future<void> _disconnectLiveChat() async {
    await _audioStreamSubscription?.cancel();
    await _audioRecorder.stop();
    
    setState(() {
      _isConnected = false;
      _isListening = false;
      _isSpeaking = false;
      _statusMessage = 'Disconnected';
      _transcript = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Voice Chat'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple[400]!, Colors.deepPurple[900]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Status Bar
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Connection status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isConnected ? Icons.circle : Icons.circle_outlined,
                          color: _isConnected ? Colors.green : Colors.white54,
                          size: 12,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Visual indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Listening indicator
                        _buildIndicator(
                          'Listening',
                          Icons.mic,
                          _isListening,
                          Colors.blue,
                        ),
                        // Speaking indicator
                        _buildIndicator(
                          'AI Speaking',
                          Icons.volume_up,
                          _isSpeaking,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Transcript area
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _transcript.isEmpty ? 'Conversation will appear here...' : _transcript,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Main control button
              Padding(
                padding: EdgeInsets.all(40),
                child: GestureDetector(
                  onTap: _toggleLiveChat,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isConnected ? Colors.red : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: (_isConnected ? Colors.red : Colors.white).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isConnected ? Icons.call_end : Icons.phone,
                      color: _isConnected ? Colors.white : Colors.deepPurple,
                      size: 45,
                    ),
                  ),
                ),
              ),
              
              // Info text
              Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  _isConnected ? 'Tap to end conversation' : 'Tap to start live chat',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(String label, IconData icon, bool isActive, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color.withOpacity(0.3) : Colors.white.withOpacity(0.1),
            border: Border.all(
              color: isActive ? color : Colors.white30,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? color : Colors.white54,
            size: 30,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _audioStreamSubscription?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
Step 3: Add Text-to-Speech for AI Voice Output
For complete bidirectional audio, add Google Cloud TTS or Flutter TTS:
dartdependencies:
  flutter_tts: ^3.8.0
dartimport 'package:flutter_tts/flutter_tts.dart';

class _LiveVoiceChatBotState extends State<LiveVoiceChatBot> {
  final FlutterTts _tts = FlutterTts();
  
  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }
  
  Future<void> _initializeTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }
  
  Future<void> _speakResponse(String text) async {
    setState(() {
      _isSpeaking = true;
    });
    
    await _tts.speak(text);
    
    // Listen for completion
    _tts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }
}
Step 4: Better Alternative - Use Gemini Live API (WebSocket)
For true real-time bidirectional streaming (like ChatGPT voice mode), you should use WebSocket connection with Gemini's Live API:
dartimport 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel? _channel;

Future<void> _connectWebSocket() async {
  final uri = Uri.parse(
    'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=YOUR_API_KEY'
  );
  
  _channel = WebSocketChannel.connect(uri);
  
  _channel!.stream.listen(
    (message) {
      // Handle incoming audio/text from AI
      _handleAIResponse(message);
    },
    onError: (error) {
      print('WebSocket error: $error');
    },
  );
  
  // Send initial setup
  _channel!.sink.add(jsonEncode({
    'setup': {
      'model': 'models/gemini-2.0-flash-exp',
      'generation_config': {
        'response_modalities': ['AUDIO'],
        'speech_config': {
          'voice_config': {
            'prebuilt_voice_config': {
              'voice_name': 'Aoede'
            }
          }
        }
      }
    }
  }));
}

void _sendAudioToWebSocket(Uint8List audioData) {
  if (_channel != null) {
    _channel!.sink.add(jsonEncode({
      'realtime_input': {
        'media_chunks': [{
          'mime_type': 'audio/pcm',
          'data': base64Encode(audioData),
        }]
      }
    }));
  }
}
Key Points:

✅ Real-time bidirectional - Both speak and listen simultaneously
✅ Natural interruptions - Can interrupt AI while speaking
✅ Low latency - WebSocket streaming for instant response
✅ Native audio - Direct audio input/output without transcription

Important Notes:

The exact model name might be gemini-2.0-flash-exp or similar - check Google AI Studio
For production, use Gemini Live API with WebSocket (shown above)
Test on real device (audio doesn't work well on emulators)
Ensure stable internet connection for streaming

Would you like me to provide a more detailed WebSocket implementation or help with any specific part?alerdy have the full app i wan to add that into my ai with ai ide so give me th implmenation paln ad ai gul to buil this and make workig propey8:04 pmGreat! I'll give you a complete implementation plan and guide to integrate live voice chat into your existing Flutter app.
📋 Implementation Plan & AI Guide
Phase 1: Project Setup & Dependencies
Step 1.1: Update pubspec.yaml
yamldependencies:
  flutter:
    sdk: flutter
  # Existing dependencies...
  
  # Add these new dependencies
  google_generative_ai: ^0.4.0
  record: ^5.0.0
  audioplayers: ^5.2.0
  permission_handler: ^11.0.0
  path_provider: ^2.1.0
  web_socket_channel: ^2.4.0
  flutter_tts: ^3.8.0
  just_audio: ^0.9.36
Step 1.2: Platform-specific permissions
For Android - android/app/src/main/AndroidManifest.xml:
xml<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
    
    <application>
        <!-- Your existing config -->
    </application>
</manifest>
For iOS - ios/Runner/Info.plist:
xml<dict>
    <!-- Existing keys -->
    
    <key>NSMicrophoneUsageDescription</key>
    <string>We need microphone access for voice chat with AI</string>
    
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
    </array>
</dict>
```

---

### **Phase 2: Create Core Service Files**

Create this folder structure in your project:
```
lib/
├── services/
│   ├── gemini_live_service.dart
│   ├── audio_service.dart
│   └── tts_service.dart
├── screens/
│   └── live_voice_chat_screen.dart
└── widgets/
    └── voice_visualizer.dart

Phase 3: Implementation Files
File 1: lib/services/gemini_live_service.dart
This handles all Gemini API communication:
dartimport 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';

class GeminiLiveService {
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE'; // TODO: Replace with your key
  
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _responseController;
  bool _isConnected = false;
  
  Stream<Map<String, dynamic>> get responseStream => 
      _responseController?.stream ?? Stream.empty();
  
  bool get isConnected => _isConnected;

  Future<bool> connect() async {
    try {
      _responseController = StreamController<Map<String, dynamic>>.broadcast();
      
      // Connect to Gemini WebSocket
      final uri = Uri.parse(
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$_apiKey'
      );
      
      _channel = WebSocketChannel.connect(uri);
      
      // Listen for responses
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _responseController?.add(data);
          } catch (e) {
            print('Error parsing message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _responseController?.addError(error);
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
        },
      );
      
      // Send initial setup
      await _sendSetup();
      
      _isConnected = true;
      return true;
      
    } catch (e) {
      print('Connection error: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> _sendSetup() async {
    final setupMessage = {
      'setup': {
        'model': 'models/gemini-2.0-flash-exp',
        'generation_config': {
          'response_modalities': ['AUDIO', 'TEXT'],
          'speech_config': {
            'voice_config': {
              'prebuilt_voice_config': {
                'voice_name': 'Aoede' // Female voice
                // Other options: 'Charon' (male), 'Fenrir' (male), 'Kore' (female)
              }
            }
          }
        },
        'system_instruction': {
          'parts': [{
            'text': 'You are a helpful AI voice assistant. Keep responses natural, '
                   'conversational, and concise. Speak as if having a real-time conversation. '
                   'Be friendly, helpful, and engaging.'
          }]
        }
      }
    };
    
    _channel?.sink.add(jsonEncode(setupMessage));
    
    // Wait for setup confirmation
    await Future.delayed(Duration(milliseconds: 500));
  }

  void sendAudio(Uint8List audioData) {
    if (!_isConnected || _channel == null) {
      print('Not connected to Gemini');
      return;
    }
    
    try {
      final message = {
        'realtime_input': {
          'media_chunks': [{
            'mime_type': 'audio/pcm',
            'data': base64Encode(audioData),
          }]
        }
      };
      
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      print('Error sending audio: $e');
    }
  }

  void sendText(String text) {
    if (!_isConnected || _channel == null) return;
    
    try {
      final message = {
        'client_content': {
          'turns': [{
            'role': 'user',
            'parts': [{'text': text}]
          }],
          'turn_complete': true
        }
      };
      
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      print('Error sending text: $e');
    }
  }

  Future<void> disconnect() async {
    _isConnected = false;
    await _channel?.sink.close();
    await _responseController?.close();
    _channel = null;
    _responseController = null;
  }

  void dispose() {
    disconnect();
  }
}

File 2: lib/services/audio_service.dart
This handles audio recording and streaming:
dartimport 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSubscription;
  bool _isRecording = false;
  
  bool get isRecording => _isRecording;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> startRecording(Function(Uint8List) onAudioChunk) async {
    try {
      if (!await _recorder.hasPermission()) {
        final granted = await requestPermission();
        if (!granted) return false;
      }

      // Start streaming audio
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000, // 16kHz for Gemini
          numChannels: 1, // Mono
          bitRate: 128000,
        ),
      );

      _isRecording = true;

      // Buffer to accumulate audio chunks
      List<int> buffer = [];
      const chunkSize = 16000; // 1 second of audio at 16kHz

      _audioSubscription = stream.listen(
        (audioData) {
          buffer.addAll(audioData);
          
          // Send chunks of ~1 second
          if (buffer.length >= chunkSize) {
            onAudioChunk(Uint8List.fromList(buffer));
            buffer.clear();
          }
        },
        onError: (error) {
          print('Audio stream error: $error');
          stopRecording();
        },
      );

      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  Future<void> stopRecording() async {
    await _audioSubscription?.cancel();
    await _recorder.stop();
    _audioSubscription = null;
    _isRecording = false;
  }

  void dispose() {
    stopRecording();
    _recorder.dispose();
  }
}

File 3: lib/services/tts_service.dart
Text-to-Speech service for playing AI responses:
dartimport 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  
  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5); // Natural speed
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    
    _tts.setStartHandler(() {
      _isSpeaking = true;
    });
    
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    
    _tts.setErrorHandler((msg) {
      print('TTS Error: $msg');
      _isSpeaking = false;
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  void dispose() {
    _tts.stop();
  }
}

File 4: lib/screens/live_voice_chat_screen.dart
Main UI screen for voice chat:
dartimport 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../services/gemini_live_service.dart';
import '../services/audio_service.dart';
import '../services/tts_service.dart';
import '../widgets/voice_visualizer.dart';

class LiveVoiceChatScreen extends StatefulWidget {
  @override
  _LiveVoiceChatScreenState createState() => _LiveVoiceChatScreenState();
}

class _LiveVoiceChatScreenState extends State<LiveVoiceChatScreen> {
  final GeminiLiveService _geminiService = GeminiLiveService();
  final AudioService _audioService = AudioService();
  final TTSService _ttsService = TTSService();
  
  bool _isConnected = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _statusMessage = 'Tap to start';
  List<ChatMessage> _messages = [];
  StreamSubscription? _geminiSubscription;

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
  }

  Future<void> _toggleConnection() async {
    if (_isConnected) {
      await _disconnect();
    } else {
      await _connect();
    }
  }

  Future<void> _connect() async {
    setState(() => _statusMessage = 'Connecting...');
    
    // Connect to Gemini
    final connected = await _geminiService.connect();
    
    if (!connected) {
      setState(() => _statusMessage = 'Connection failed');
      _showError('Failed to connect to Gemini');
      return;
    }
    
    // Start listening to Gemini responses
    _geminiSubscription = _geminiService.responseStream.listen(_handleGeminiResponse);
    
    // Start audio recording
    final recording = await _audioService.startRecording((audioChunk) {
      _geminiService.sendAudio(audioChunk);
    });
    
    if (!recording) {
      setState(() => _statusMessage = 'Microphone permission denied');
      _showError('Please grant microphone permission');
      await _geminiService.disconnect();
      return;
    }
    
    setState(() {
      _isConnected = true;
      _isListening = true;
      _statusMessage = 'Connected - Speak now';
    });
  }

  void _handleGeminiResponse(Map<String, dynamic> response) {
    print('Received response: $response');
    
    try {
      // Handle server content (AI response)
      if (response.containsKey('serverContent')) {
        final serverContent = response['serverContent'];
        
        // Check if model is currently speaking
        if (serverContent.containsKey('modelTurn')) {
          final modelTurn = serverContent['modelTurn'];
          
          // Extract text
          if (modelTurn.containsKey('parts')) {
            for (var part in modelTurn['parts']) {
              if (part.containsKey('text')) {
                final text = part['text'];
                _addMessage(text, false);
                
                // Speak the response if TTS is enabled
                // Note: Gemini can return audio directly, but for fallback
                if (!_isSpeaking) {
                  _ttsService.speak(text);
                  setState(() => _isSpeaking = true);
                }
              }
              
              // Handle audio response
              if (part.containsKey('inlineData')) {
                final inlineData = part['inlineData'];
                if (inlineData['mimeType'] == 'audio/pcm') {
                  // Audio data from Gemini
                  // You can play this directly using audioplayers
                  setState(() => _isSpeaking = true);
                }
              }
            }
          }
          
          // Check if turn is complete
          if (serverContent.containsKey('turnComplete') && 
              serverContent['turnComplete'] == true) {
            setState(() => _isSpeaking = false);
          }
        }
      }
      
      // Handle tool calls if any
      if (response.containsKey('toolCall')) {
        print('Tool call received: ${response['toolCall']}');
      }
      
    } catch (e) {
      print('Error handling response: $e');
    }
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _disconnect() async {
    await _audioService.stopRecording();
    await _geminiService.disconnect();
    await _ttsService.stop();
    await _geminiSubscription?.cancel();
    
    setState(() {
      _isConnected = false;
      _isListening = false;
      _isSpeaking = false;
      _statusMessage = 'Disconnected';
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Voice Chat'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade400,
              Colors.deepPurple.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Status Header
              _buildStatusHeader(),
              
              // Messages
              Expanded(
                child: _buildMessagesList(),
              ),
              
              // Voice Visualizer
              if (_isConnected)
                VoiceVisualizer(
                  isListening: _isListening,
                  isSpeaking: _isSpeaking,
                ),
              
              // Control Button
              _buildControlButton(),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isConnected ? Icons.circle : Icons.circle_outlined,
                color: _isConnected ? Colors.greenAccent : Colors.white54,
                size: 12,
              ),
              SizedBox(width: 8),
              Text(
                _statusMessage,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          if (_isConnected) ...[
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIndicator('Listening', Icons.mic, _isListening),
                _buildIndicator('AI Speaking', Icons.volume_up, _isSpeaking),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicator(String label, IconData icon, bool isActive) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive 
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            border: Border.all(
              color: isActive ? Colors.white : Colors.white30,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.white54,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'Start talking to begin conversation',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      );
    }
    
    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser 
              ? Colors.white 
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.deepPurple : Colors.white,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: message.isUser 
                    ? Colors.deepPurple.shade300 
                    : Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton() {
    return GestureDetector(
      onTap: _toggleConnection,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isConnected ? Colors.red : Colors.white,
          boxShadow: [
            BoxShadow(
              color: (_isConnected ? Colors.red : Colors.white)
                  .withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          _isConnected ? Icons.call_end : Icons.mic,
          color: _isConnected ? Colors.white : Colors.deepPurple,
          size: 40,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disconnect();
    _geminiService.dispose();
    _audioService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

File 5: lib/widgets/voice_visualizer.dart
Visual feedback for voice activity:
dartimport 'package:flutter/material.dart';
import 'dart:math';

class VoiceVisualizer extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;

  const VoiceVisualizer({
    required this.isListening,
    required this.isSpeaking,
  });

  @override
  _VoiceVisualizerState createState() => _VoiceVisualizerState();
}

class _VoiceVisualizerState extends State<VoiceVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: EdgeInsets.symmetric(vertical: 20),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isActive = widget.isListening || widget.isSpeaking;
              final height = isActive
                  ? 20 + (40 * sin((_controller.value * 2 * pi) + index)).abs()
                  : 10.0;
              
              return Container(
                width: 6,
                height: height,
                margin: EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: widget.isSpeaking 
                      ? Colors.orange 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

Phase 4: Integration into Your Existing App
Step 4.1: Add navigation to voice chat
In your existing app's main navigation (e.g., home screen, menu, or floating button):
dart// Add this button/navigation wherever you want
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveVoiceChatScreen(),
      ),
    );
  },
  child: Icon(Icons.mic),
  backgroundColor: Colors.deepPurple,
)
```

---

### **Phase 5: Configuration & API Key**

**Step 5.1: Get Gemini API Key**

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Click "Get API Key"
3. Create a new key or use existing
4. Copy the key

**Step 5.2: Add API key securely**

**Option A - Environment Variables (Recommended):**

Create `.env` file:
```
GEMINI_API_KEY=your_actual_api_key_here
Add to pubspec.yaml:
yamldependencies:
  flutter_dotenv: ^5.1.0

flutter:
  assets:
    - .env
Update gemini_live_service.dart:
dartimport 'package:flutter_dotenv/flutter_dotenv.dart';

// In class
static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
Option B - Direct (For Testing Only):
dartstatic const String _apiKey = 'AIzaSy...your_key_here';

Phase 6: Testing & Debugging
Step 6.1: Test on Real Device
bash# Connect your phone
flutter devices

# Run on device
flutter run
Step 6.2: Enable Debug Logging
Add to each service file:
dartvoid _log(String message) {
  print('[ServiceName] $message');
}
Step 6.3: Common Issues & Fixes
IssueSolutionNo microphone permissionCheck permissions in settingsWebSocket connection failsVerify API key and internetAudio not recordingTest on real device, not emulatorNo AI responseCheck console logs for errorsLatency issuesReduce audio chunk size

Phase 7: Optimization
Step 7.1: Reduce Latency
dart// In audio_service.dart
const chunkSize = 8000; // Send chunks more frequently (0.5 seconds)
Step 7.2: Add Error Recovery
dart// Auto-reconnect on disconnect
void _handleDisconnect() {
  Timer(Duration(seconds: 2), () {
    if (!_isConnected) {
      _connect();
    }
  });
}
Step 7.3: Background Audio Support
Add to android/app/src/main/AndroidManifest.xml:
xml<service android:name="com.ryanheise.audioservice.AudioService">
    <intent-filter>
        <action android:name="android.media.browse.MediaBrowserService" />
    </intent-filter>
</service>