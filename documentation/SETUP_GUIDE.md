# 🛠️ Setup Guide

Follow these steps to set up **KumbhSaathi** on your local development environment.

## Prerequisites

- **Flutter SDK**: v3.10.x or higher
- **Dart SDK**: v3.x
- **Android Studio** / **VS Code** with Flutter extensions
- **Firebase Project**: Configured with Auth and Firestore
- **Gemini API Key**: Access to Gemini 2.0 Flash Live

## 📲 Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/kumbhsaathi.git
   cd kumbhsaathi
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**
   - Create an `.env` file in the root directory.
   - Add your API keys:
     ```env
     GEMINI_API_KEY=your_gemini_api_key_here
     GOOGLE_MAPS_KEY=your_maps_key (if used)
     ```
   - *Note*: Ensure `envied` generator is run if using the `envied` package:
     ```bash
     dart run build_runner build
     ```

4. **Firebase Setup**
   - Place your `google-services.json` in `android/app/`.
   - Place your `GoogleService-Info.plist` in `ios/Runner/`.

## 🏃‍♂️ Running the App

### Android
```bash
flutter run
```
*Ensure you have an emulator or physical device connected.*

### iOS
```bash
cd ios
pod install
cd ..
flutter run
```

### Web
```bash
flutter run -d chrome
```
*Note*: Voice features require HTTPS or localhost.

## 🛑 Common Issues

**Microphone Error (Web)**
- If you see `SpeechRecognitionError: network`, check your internet connection.
- Ensure you are using **Chrome** or **Edge**.
- Voice features might be blocked on non-secure (http) remote servers.

**Map Not Loading**
- Check your internet connection (OpenStreetMap requires it unless tiles are cached).
