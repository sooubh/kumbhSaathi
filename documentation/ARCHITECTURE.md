# 🏗️ Architecture & Code Structure

KumbhSaathi follows a **Feature-First** directory structure with **Riverpod** for state management. This ensures scalability and maintainability.

## 📁 Directory Structure

```
lib/
├── core/                  # Core utilities and configs
│   ├── config/            # AI Config, Theme, Constants
│   ├── services/          # External services (Gemini, Audio, Location)
│   └── utils/             # Helper functions
├── data/                  # Data layer
│   ├── models/            # Dart models (User, Location, Message)
│   └── repositories/      # Data fetching logic (Firebase, APIs)
├── providers/             # Riverpod providers (Global State)
│   ├── auth_provider.dart
│   ├── location_provider.dart
│   ├── voice_session_provider.dart
│   └── ...
├── screens/               # UI Screens organized by feature
│   ├── auth/
│   ├── home/
│   ├── emergency/
│   └── ...
├── widgets/               # Reusable UI components
└── main.dart              # Entry point
```

## 🧠 Key Services

### 1. RealtimeChatService (`core/services/realtime_chat_service.dart`)
- **Purpose**: Manages the WebSocket connection to Gemini 2.0 Flash Live.
- **Protocol**: Implements Google's `BidiGenerateContent` protocol.
- **Streaming**: Exposes a `responseStream` for text chunks and `turnCompleteStream` for flow control.

### 2. VoiceSessionProvider (`providers/voice_session_provider.dart`)
- **Purpose**: The "Brain" of the voice assistant.
- **Logic**:
  1. **Listen**: Uses `speech_to_text` with robust state guarding.
  2. **Think**: Sends text to `RealtimeChatService`.
  3. **Speak**:Buffers streaming text and speaks using `flutter_tts`.
- **State Machine**: Handles transitions between `listening`, `processing`, and `speaking`.

### 3. LocationProvider (`providers/location_provider.dart`)
- **Purpose**: Tracks user location in background/foreground.
- **Optimization**: Uses distance filters to save battery.

## 🔄 State Management (Riverpod)

- **`voiceSessionProvider`**: `StateNotifier` that manages the complex UI state of the voice assistant.
- **`textChatProvider`**: Manages the text-based chat history, sharing the same `RealtimeChatService` backend for consistency.
- **`languageProvider`**: centralized locale management for Multilingual support.

## 🤖 AI Integration Strategy

We use a **System Prompt** injected at the start of every session (`AIConfig.getSystemPrompt`).
- **Context**: The AI receives user location, emergency contacts, and crowd stats.
- **Output**: The AI is instructed to return **JSON** for actionable intents (Navigation, SOS) or **Plain Text** for conversational answers.
- **Multilingual**: The AI detects the input language and handles the response language automatically.
