# KumbhSaathi - Smart Assistance for Kumbh Mela 🚩

**KumbhSaathi** is a comprehensive Flutter application designed to assist millions of pilgrims visiting the **Nashik Kumbh Mela**. It acts as a digital companion, providing real-time crowd navigation, lost person assistance, emergency SOS features, and an intelligent AI voice assistant powered by **Google Gemini 2.0 Flash Live**.

---

## 🚀 Key Features

### 1. 🎙️ Real-time AI Voice Assistant (Gemini Live)
- **Hands-free Interaction**: Just tap and speak to get instant help.
- **Multilingual Support**: Supports 12+ Indian languages (Hindi, Marathi, Gujarati, Telugu, etc.).
- **Smart Routing**: Detects intent (Navigation, Lost Person, SOS) and routes to the correct app screen.
- **Technology**: Uses **WebSockets** for low-latency bidirectional communication with Gemini 2.0.

### 2. 📍 Smart Navigation & Crowd Management
- **Live Crowd Heatmaps**: Visualizes crowd density at Ghats to help users avoid congestion.
- **Offline Maps**: Uses OpenStreetMap (OSM) for navigation even with poor connectivity.
- **AR Navigation**: (Planned) Augmented reality view for finding landmarks.

### 3. 🔍 Lost & Found (Face Search)
- **AI Face Matching**: Upload a photo of a lost person to find matches in the database.
- **Privacy First**: Secure reporting and matching system.

### 4. 🆘 Emergency SOS
- **One-Tap Alert**: Instantly notifies nearby police/volunteers and pre-saved emergency contacts.
- **Offline SMS fallback**: Sends location via SMS if internet is unavailable.

### 5. 👨‍👩‍👧 Family Tracking
- **Group Location**: Track family members in real-time on the map.
- **Safe Zones**: Get alerts if a member strays too far (Geofencing).

---

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **State Management**: Riverpod
- **AI/LLM**: Google Gemini 2.0 Flash Exp (Multimodal Live API)
- **Maps**: Flutter Map (OpenStreetMap)
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Voice**: `speech_to_text` (Input), `flutter_tts` (Output)

---

## 📂 Documentation Structure

- **[Setup Guide](SETUP_GUIDE.md)**: Instructions to build and run the app.
- **[Architecture](ARCHITECTURE.md)**: Deep dive into the code structure and services.
- **[API Reference](API_REFERENCE.md)**: Details on Gemini WebSocket and external APIs.
