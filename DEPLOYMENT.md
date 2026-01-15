# KumbhSaathi - Web Deployment Guide

## Prerequisites
1. Flutter SDK installed (3.10.1 or higher)
2. Vercel CLI installed: `npm i -g vercel`
3. Firebase project configured for web

## Firebase Web Configuration

### 1. Enable Web Platform in Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **KumbhSaathi**
3. Click on "Project Settings" (gear icon)
4. Scroll to "Your apps" section
5. Click "Add app" → Select **Web** (</>)
6. Register the app:
   - **App nickname**: KumbhSaathi Web
   - Check "Also set up Firebase Hosting" (optional)
   - Click "Register app"

### 2. Configure Firebase Authentication for Web
1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable **Google Sign-In**:
   - Click on "Google"
   - Toggle "Enable"
   - Set **Project support email**
   - Add **Authorized domains**: 
     - `localhost` (for local testing)
     - Your Vercel domain (e.g., `kumbhsaathi.vercel.app`)
   - Click "Save"

### 3. Get Web Configuration
After registering the web app, you'll see Firebase configuration code like:
```javascript
const firebaseConfig = {
  apiKey: "...",
  authDomain: "...",
  projectId: "...",
  storageBucket: "...",
  messagingSenderId: "...",
  appId: "..."
};
```

**Note**: These are already configured in `lib/firebase_options.dart` if you've run `flutterfire configure`.

## Building for Web

### Local Build & Test
```bash
# Build for web
flutter build web --release

# Serve locally (choose one method)
# Method 1: Python
cd build/web
python -m http.server 8000

# Method 2: npm serve
npx serve build/web

# Method 3: Flutter run
flutter run -d chrome
```

Visit `http://localhost:8000` to test.

## Deploying to Vercel

### Method 1: Vercel CLI (Recommended)
```bash
# Login to Vercel
vercel login

# Deploy (from project root)
vercel

# For production deployment
vercel --prod
```

### Method 2: GitHub Integration
1. Push your code to GitHub
2. Go to [Vercel Dashboard](https://vercel.com/dashboard)
3. Click "Import Project"
4. Select your GitHub repository
5. Vercel will detect the `vercel.json` configuration
6. Click "Deploy"

## Environment Variables (If needed)
If you need to set any environment variables in Vercel:
1. Go to your project in Vercel Dashboard
2. Settings → Environment Variables
3. Add variables as needed

## Post-Deployment Checklist
- [ ] Verify app loads correctly
- [ ] Test Google Sign-In authentication
- [ ] Check navigation (routing works on page refresh)
- [ ] Test on mobile browsers
- [ ] Verify Firebase features work
- [ ] Check console for errors

## Troubleshooting

### Google Sign-In Not Working
**Issue**: "Sign in failed" error

**Solutions**:
1. Verify authorized domains in Firebase Console
2. Check that web app is registered in Firebase
3. Ensure `google_sign_in` web plugin is configured
4. Add this to `web/index.html` before `</head>`:
```html
<meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
```

### Page Not Found on Refresh
**Cause**: SPA routing not configured

**Solution**: The `vercel.json` rewrites configuration handles this. Ensure it's present.

### Build Errors
- Run `flutter clean && flutter pub get`
- Ensure all dependencies support web platform
- Check `flutter doctor -v`

## Known Limitations
Some packages have limited web support:
- **geolocator**: Basic location works, background tracking doesn't
- **image_picker**: Works but with web-specific UI
- **google_maps_flutter**: Use `google_maps_flutter_web` plugin

## Custom Domain (Optional)
1. In Vercel Dashboard → Settings → Domains
2. Add your custom domain
3. Follow DNS configuration instructions
4. Update Firebase authorized domains

## Support
For issues, check:
- [Flutter Web Docs](https://flutter.dev/web)
- [Vercel Docs](https://vercel.com/docs)
- [Firebase Web Setup](https://firebase.google.com/docs/web/setup)
