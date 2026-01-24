# 🔌 API Reference & Integrations

## 1. Google Gemini 2.0 Flash Live (Multimodal)

We use the **Gemini Multimodal Live API** via WebSockets for real-time interaction.

- **Endpoint**: `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=YOUR_API_KEY`
- **Model**: `models/gemini-2.0-flash-exp` (or `gemini-2.0-flash-live` once general available)

### WebSocket Protocol

#### 1. Setup Message (Sent immediately on connection)
```json
{
  "setup": {
    "model": "models/gemini-2.0-flash-exp",
    "generation_config": {
      "response_modalities": ["TEXT"],
      "speech_config": { "voice_config": { "prebuilt_voice_config": { "voice_name": "Aoede" } } }
    },
    "system_instruction": { "parts": [ { "text": "SYSTEM_PROMPT_HERE" } ] }
  }
}
```

#### 2. Client Turn (User Input)
```json
{
  "client_content": {
    "turns": [
      { "role": "user", "parts": [ { "text": "Hello Gemini" } ] }
    ],
    "turn_complete": true
  }
}
```

#### 3. Server Response (Streaming)
The server sends a stream of JSON messages. We handle:
- `serverContent.modelTurn`: Contains text chunks.
- `serverContent.turnComplete`: Signals the end of a response (Trigger for TTS flush).

---

## 2. OpenStreetMap (Flutter Map)

We use **Flutter Map** with `flutter_map_tile_caching` for offline capabilities.
- **Provider**: OpenStreetMap (Standard Tile Layer)
- **Caching**: Tiles are cached locally to support usage in low-network areas (Kumbh Mela grounds).

---

## 3. Firebase (Backend)

- **Authentication**: Anonymous auth (for quick access) and Google Sign-In.
- **Firestore**:
  - `users/`: User profiles and emergency contacts.
  - `lost_persons/`: Reports of lost individuals.
  - `emergency_alerts/`: Real-time SOS alerts.
