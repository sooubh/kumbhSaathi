# 🔴 REALTIME SETUP - What You Need To Do

## Step 1: Add Ghats to Firestore (5 minutes)

### Option A: Using Firebase Console (Easy)

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com
   - Select your project: "KumbhSaathi"
   - Click "Firestore Database" in left menu

2. **Create 'ghats' Collection**
   - Click "Start collection"
   - Collection ID: `ghats`
   - Click "Next"

3. **Add Ram Ghat (First Document)**
   - Document ID: `ram_ghat`
   - Add these fields:
   ```
   id: "ram_ghat" (string)
   name: "Ram Ghat" (string)
   nameHindi: "राम घाट" (string)
   description: "Most sacred ghat in Nashik" (string)
   latitude: 19.9987 (number)
   longitude: 73.7883 (number)
   crowdLevel: "high" (string)
   isGoodForBathing: true (boolean)
   facilities: ["Changing Rooms", "Toilets", "Drinking Water"] (array)
   userCount: 0 (number)
   lastUpdated: [current timestamp]
   ```

4. **Add More Ghats**
   - Repeat for all 7 ghats from `panchavati_ghats_data.dart`
   - Copy coordinates carefully!

### Option B: Import JSON (Faster)

1. Use Firebase CLI:
```bash
# Install Firebase CLI if not installed
npm install -g firebase-tools

# Login
firebase login

# Import data
firebase firestore:import ghats_data.json
```

---

## Step 2: Enable Automatic Crowd Updates (CRITICAL!)

### Add This to Your App

In `lib/main.dart`, add automatic crowd monitoring:

```dart
import 'dart:async';
import 'core/services/realtime_crowd_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await FirebaseService.initialize();

  // 🔴 START AUTOMATIC CROWD MONITORING
  Timer.periodic(Duration(minutes: 5), (timer) {
    RealtimeCrowdService().autoUpdateCrowdLevels();
  });

  runApp(const ProviderScope(child: KumbhSaathiApp()));
}
```

**This automatically:**
- Counts users near each ghat every 5 minutes
- Updates crowd levels (low/medium/high)
- Changes marker colors in realtime
- Updates the dashboard live

---

## Step 3: Add Live Dashboard to Home Screen

In `lib/screens/home/home_screen.dart`:

```dart
import '../../widgets/kumbh/realtime_kumbh_dashboard.dart';

// Add to your home screen build method:
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          // Your existing widgets...
          
          // 🔴 ADD THIS
          RealtimeKumbhDashboard(),
          
          // Rest of your widgets...
        ],
      ),
    ),
  );
}
```

---

## Step 4: Update Firestore Security Rules

In Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Ghats - everyone can read, only admins write
    match /ghats/{ghatId} {
      allow read: if true;  // Public read
      allow write: if request.auth != null && 
                      request.auth.token.admin == true;
    }
    
    // User locations - users can update their own
    match /user_locations/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      request.auth.uid == userId;
      allow delete: if request.auth.uid == userId;
    }
  }
}
```

Click "Publish" to save.

---

## Step 5: Test Realtime Updates

### Test 1: Manual Update
```dart
// In your app, add a test button:
ElevatedButton(
  onPressed: () async {
    await RealtimeCrowdService().updateCrowdLevel(
      ghatId: 'ram_ghat',
      newLevel: CrowdLevel.high,
    );
  },
  child: Text('Set Ram Ghat to HIGH'),
)
```
- Tap button
- Watch map marker turn RED 🔴
- Dashboard updates instantly!

### Test 2: Location Sharing
1. Open app on 2 devices
2. Go to Navigation screen
3. Enable location on both
4. Move close to Ram Ghat
5. Wait 5 minutes
6. Watch crowd level auto-update!

---

## Step 6: Production Setup

### Add Background Service (Optional but Recommended)

For production, run crowd updates in background:

```dart
import 'package:workmanager/workmanager.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await FirebaseService.initialize();
    await RealtimeCrowdService().autoUpdateCrowdLevels();
    return Future.value(true);
  });
}

void main() async {
  // Initialize WorkManager
  await Workmanager().initialize(callbackDispatcher);
  
  // Schedule background task every 5 minutes
  Workmanager().registerPeriodicTask(
    "crowd-update",
    "updateCrowdLevels",
    frequency: Duration(minutes: 15),
  );
  
  // Rest of your app...
}
```

---

## What Happens in Realtime:

### 1. **Map Markers** 🗺️
- ✅ Auto-update colors every 5 min
- ✅ Green = Low crowd (< 10 people)
- ✅ Orange = Medium (10-50)
- ✅ Red = High (50+)

### 2. **Dashboard** 📊
- ✅ Live crowd count per ghat
- ✅ Pulsing LIVE indicator
- ✅ Smart recommendations
- ✅ Updates every second via StreamBuilder

### 3. **User Locations** 📍
- ✅ Updates every 10 meters
- ✅ Syncs to Firestore
- ✅ Nearby users visible
- ✅ Family/friend tracking

### 4. **Navigation** 🧭
- ✅ Routes avoid crowded areas
- ✅ Suggests less-crowded ghats
- ✅ Real-time estimations

---

## Quick Checklist

- [ ] Added all 7 ghats to Firestore
- [ ] Set initial crowdLevel for each ghat
- [ ] Added automatic crowd monitoring to main.dart
- [ ] Added RealtimeKumbhDashboard to home screen
- [ ] Updated Firestore security rules
- [ ] Tested manual crowd update
- [ ] Tested with multiple devices
- [ ] Installed app on test device in Nashik

---

## Testing in Nashik

**Before Kumbh Mela:**
1. Install app on your phone
2. Go to Ram Ghat area
3. Enable location sharing
4. Walk around different ghats
5. Watch map update in realtime!

**During Kumbh Mela:**
1. Automatic updates every 5 min
2. Pilgrims see live crowd levels
3. Route to less crowded ghats
4. Real emergency tracking

---

## Troubleshooting

**Dashboard shows 0/0/0?**
- Check Firebase connection
- Verify ghats are in Firestore
- Check crowdLevel field exists

**Markers not changing color?**
- Run `autoUpdateCrowdLevels()` once manually
- Check user_locations collection has data
- Verify Timer is running

**Location not updating?**
- Check location permissions
- Enable GPS on device
- Check network connection

---

## 🎯 You're Ready!

Once you complete Steps 1-4, your app will be **FULLY REALTIME** for Nashik Kumbh Mela 2025!

🕉️ Har Har Mahadev! 🙏
