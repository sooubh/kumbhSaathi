# Firebase Console Setup for Google Sign-In

## ⚠️ CRITICAL: Complete These Steps to Fix "Sign in failed" Error

Google Sign-In requires SHA-1 and SHA-256 fingerprints to be added to your Firebase project. Follow these steps carefully.

---

## Step 1: Get Your SHA Fingerprints

### Option A: Automated (Recommended)
I've already run the command. Check the output below for your SHA fingerprints.

### Option B: Manual
If you need to run it yourself:
```powershell
cd android
.\gradlew signingReport
```

Look for output similar to:
```
Variant: debug
Config: debug
Store: C:\Users\ACER\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX...
SHA1: AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12
SHA-256: 12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB
```

**Copy BOTH the SHA1 and SHA-256 values.**

---

## Step 2: Add SHA Fingerprints to Firebase Console

### 2.1 Open Firebase Console
1. Go to: https://console.firebase.google.com
2. Select your project: **nashikkumbhsaathi**

### 2.2 Navigate to Project Settings
1. Click the **⚙️ gear icon** (top left)
2. Select **Project settings**

### 2.3 Add SHA Fingerprints
1. Scroll down to **"Your apps"** section
2. Find the **Android app**: `com.sooubh.kumbhsaathi`
3. Click on the app to expand if needed
4. Scroll to **"SHA certificate fingerprints"** section
5. Click **"Add fingerprint"**
6. Paste your **SHA-1** value → Click **"Save"**
7. Click **"Add fingerprint"** again
8. Paste your **SHA-256** value → Click **"Save"**

### 2.4 Download Updated Configuration
1. Still in the same Android app section
2. Click **"Download google-services.json"**
3. **Replace** the file at: `android/app/google-services.json` in your project
4. ✅ This step is crucial - the file must be updated after adding fingerprints

---

## Step 3: Verify Google Sign-In is Enabled

### 3.1 Check Authentication Settings
1. In Firebase Console, go to **Authentication** (left sidebar)
2. Click **"Sign-in method"** tab
3. Find **"Google"** in the providers list
4. Ensure it shows **"Enabled"** status
   - If not, click on it → Toggle **"Enable"** → **"Save"**
5. Verify **"Project support email"** is set (required)

---

## Step 4: Verify OAuth Configuration in Google Cloud Console

### 4.1 Access Google Cloud Console
1. Go to: https://console.cloud.google.com
2. Select project: **nashikkumbhsaathi**
3. Navigate to: **APIs & Services** → **Credentials**

### 4.2 Verify Android OAuth Client
1. Look for **"Android client (auto created by Google Service)"**
2. Click on it to open
3. Verify:
   - ✅ **Package name**: `com.sooubh.kumbhsaathi`
   - ✅ **SHA-1 certificate fingerprint**: Should match what you added
4. If missing or incorrect, click **"Add Fingerprint"** and add your SHA-1

### 4.3 Verify Web OAuth Client (for Flutter Web)
1. Look for **"Web client (auto created by Google Service)"**
2. This is automatically created by Firebase
3. Note: This is used for web authentication

---

## Step 5: Rebuild and Test

### 5.1 Clean Build
```bash
cd d:\project 2\kumbhSaathi
flutter clean
flutter pub get
cd android
.\gradlew clean
cd ..
```

### 5.2 Test Debug Build
```bash
flutter run --debug
```

### 5.3 Try Google Sign-In
1. Navigate to the login screen (swipe to page 3)
2. Tap **"Sign in with Google"**
3. Expected behavior:
   - ✅ Google account picker appears
   - ✅ Can select account
   - ✅ Successfully authenticates
   - ✅ Navigates to Profile Creation or Main Screen

---

## Common Errors & Quick Fixes

| Error Message | Cause | Solution |
|---------------|-------|----------|
| **"Sign in failed"** | Missing SHA fingerprints | Add SHA-1 & SHA-256 to Firebase |
| **"12500: Unknown error"** | Outdated google-services.json | Re-download from Firebase |
| **"DEVELOPER_ERROR"** | Package name mismatch | Verify package name in Firebase & build.gradle |
| **Silent failure** | Google Services plugin not applied | Already configured ✅ |
| **"API not enabled"** | Google Sign-In API disabled | Enable in Google Cloud Console |

---

## Verification Checklist

Before testing, ensure:
- [ ] SHA-1 added to Firebase Console
- [ ] SHA-256 added to Firebase Console
- [ ] `google-services.json` downloaded and replaced
- [ ] Google Sign-In is **Enabled** in Firebase Auth
- [ ] Support email is set in Firebase
- [ ] Ran `flutter clean && flutter pub get`
- [ ] Package name matches everywhere: `com.sooubh.kumbhsaathi`

---

## Need Help?

If you still encounter issues after completing all steps:

1. **Check Firebase Logs**:
   - Firebase Console → Authentication → Sign-in method
   - Look for error details

2. **Verify Dependency Versions** (already correct in your pubspec.yaml):
   - `firebase_auth`: ^4.17.8 ✅
   - `google_sign_in`: ^6.1.6 ✅

3. **Enable Android Debug Logging**:
   ```bash
   flutter run --debug
   # Check Android Studio Logcat for detailed errors
   ```

4. **Test on Physical Device**:
   - Google Sign-In may not work on some emulators
   - Test on a real Android device

---

## Summary

The key steps are:
1. ✅ Get SHA-1 and SHA-256 (run `.\gradlew signingReport` in `android/` folder)
2. ✅ Add them to Firebase Console (Project Settings → Android app)
3. ✅ Download updated `google-services.json`
4. ✅ Replace file in `android/app/`
5. ✅ Verify Google Sign-In is enabled
6. ✅ Clean and rebuild: `flutter clean && flutter pub get && flutter run`

**After completing these steps, Google Sign-In should work!**
