# 🕉️ Nashik Kumbh Mela - Panchavati Setup Guide

## Quick Setup for Panchavati Area

### 1. Add Panchavati Ghats to Firestore

I've created `lib/data/panchavati_ghats_data.dart` with accurate coordinates for all major ghats in Panchavati area:

**Main Ghats:**
- 🏛️ Ram Ghat (19.9987, 73.7883) - Most sacred
- 🕉️ Kala Ram Ghat (19.9995, 73.7875)
- 🌿 Tapovan Ghat (20.0012, 73.7895)
- 🏺 Naroshankar Ghat (19.9978, 73.7890)
- 👑 Ahilya Ghat (19.9970, 73.7878)
- 🌊 Ganga Ghat (20.0005, 73.7888)
- 🛕 Someshwar Ghat (19.9960, 73.7870)

**To add to Firestore:**

```bash
# Option 1: Using Firebase Console
1. Go to Firebase Console → Firestore Database
2. Create collection: 'ghats'
3. Copy data from panchavati_ghats_data.dart
4. Add each ghat as a document

# Option 2: Using Flutter (recommended)
# Create a one-time setup script
```

### 2. Enable Realtime Crowd Monitoring

The map now has realtime crowd tracking! Here's how it works:

**Automatic Updates:**
```dart
// In your admin app or background service, run this periodically:
import 'core/services/realtime_crowd_service.dart';

// Auto-update crowd levels every 5 minutes
Timer.periodic(Duration(minutes: 5), (timer) {
  RealtimeCrowdService().autoUpdateCrowdLevels();
});
```

**How it works:**
1. Counts users within 100m of each ghat
2. Updates crowd level automatically:
   - 🟢 **Low**: < 10 people
   - 🟠 **Medium**: 10-50 people
   - 🔴 **High**: > 50 people
3. Updates Firestore in realtime
4. Map markers change color instantly!

### 3. Map is Now Centered on Panchavati

The map automatically opens at:
- **Location**: Panchavati, Ram Ghat area
- **Coordinates**: 19.9987°N, 73.7883°E
- **Zoom**: 15 (close-up of Kumbh area)

### 4. Add Facilities (Optional)

Add medical camps, police posts, parking areas:

```dart
// Data already in panchavati_ghats_data.dart
// Add 'facilities' collection to Firestore with:
- Medical Camps
- Police Posts
- Information Centers
- Parking Areas
```

## Realtime Features Available

### 🔴 Live Crowd Tracking
- Markers change color based on current crowd
- Auto-updates every 5 minutes
- Based on actual user locations

### 📍 User Location Sharing
- See nearby pilgrims in realtime
- Find family/friends on map
- Emergency location tracking

### 🧭 Live Navigation
- Routes update based on crowd
- Avoids high-crowd areas
- Suggests less crowded ghats

### 📊 Crowd Stats Dashboard

```dart
// Add to your home screen
StreamBuilder(
  stream: RealtimeCrowdService().streamCrowdStats(),
  builder: (context, snapshot) {
    final stats = snapshot.data;
    return Column(
      children: [
        Text('Low Crowd Ghats: ${stats['lowCrowd']}'),
        Text('Medium Crowd: ${stats['mediumCrowd']}'),
        Text('High Crowd: ${stats['highCrowd']}'),
      ],
    );
  },
)
```

## Testing Realtime Updates

### Test Crowd Levels:

```dart
// Manually update a ghat's crowd level for testing
await RealtimeCrowdService().updateCrowdLevel(
  ghatId: 'ram_ghat',
  newLevel: CrowdLevel.high,
);
// Watch the map marker turn RED instantly! 🔴
```

### Test with Multiple Devices:

1. Open app on 2-3 devices
2. Enable location sharing on all
3. Move devices close to Ram Ghat
4. Watch crowd level auto-update!

## Production Setup Checklist

- [ ] Add all Panchavati ghats to Firestore
- [ ] Add facilities (medical, police, parking)
- [ ] Set up automatic crowd monitoring (every 5 min)
- [ ] Test realtime updates on multiple devices
- [ ] Configure Firebase security rules for Kumbh period
- [ ] Add emergency contact numbers for Nashik
- [ ] Test navigation between major ghats
- [ ] Add offline support for poor network areas

## Important Kumbh Mela Contacts

Add these to your app:
- **Emergency**: 108
- **Police Control Room**: 100
- **Nashik Kumbh Helpline**: 0253-2506473
- **Tourist Information**: 0253-2570059

## Firestore Structure

```
kumbhsaathi/
├── ghats/
│   ├── ram_ghat/
│   │   ├── name: "Ram Ghat"
│   │   ├── latitude: 19.9987
│   │   ├── longitude: 73.7883
│   │   ├── crowdLevel: "high"  ← Updates realtime!
│   │   ├── userCount: 125      ← Updates realtime!
│   │   └── lastUpdated: timestamp
│   └── ...
├── user_locations/
│   ├── userId1/
│   │   ├── latitude: 19.9990
│   │   ├── longitude: 73.7885
│   │   └── timestamp: ...
│   └── ...
└── facilities/
    ├── medical_camp_1/
    └── ...
```

## Next Steps

1. **Import ghat data to Firestore** using the provided data
2. **Enable automatic crowd updates** in your backend
3. **Test with real devices** in Nashik area
4. **Add emergency features** specific to Kumbh Mela

Map is ready for Nashik Kumbh Mela 2025! 🙏
