# KumbhSaathi - Nashik Kumbh Mela 2025 Companion App

## 1. Project Overview
**KumbhSaathi** is a comprehensive digital companion designed for the **Nashik Kumbh Mela 2025**. It serves as a unified platform to assist millions of pilgrims with navigation, safety, and essential services during the event. The app prioritizes **offline-first** capabilities, **crowd management**, and **emergency response** to ensure a safe and spiritual experience for all devotees.

**Key Goals:**
*   Simplify navigation in the complex Mela grounds.
*    reunite lost individuals with their families quickly.
*   Provide real-time crowd updates to prevent stampedes.
*   Ensure rapid response in emergencies (SOS).
*   Empower administrators to manage the event dynamically.

---

## 2. Key Features

### 2.1. Authentication & Onboarding
*   **Google Sign-In**: Seamless one-tap login for users.
*   **Role-Based Access**:
    *   **Pilgrim (User)**: Access all public features (Nav, Lost & Found, Profile).
    *   **Administrator**: Access to special dashboards for managing facilities, ghats, and approvals. Detected automatically via email (`sourabh3527@gmail.com`).
*   **Onboarding Flow**: Collects essential user details (Name, Age, Gender, Medical Info, Emergency Contacts) to create a verified digital ID.

### 2.2. Smart Navigation & Ghats
*   **Interactive Map**: Visualizes key locations like **Ghats, Medical Camps, Police Stations, and Washrooms**.
*   **Live Crowd Monitoring**: Real-time "Crowd Levels" (Low, Medium, High) for each Ghat.
    *   *Logic*: Admins update the status; users see color-coded indicators (Green/Orange/Red).
*   **Ghat Filtering**: Users can filter Ghats by crowd level to find safe spots for the Holy Dip (Snan).
*   **Direction Assistance**: "Find Ghat" feature with distance calculation and walking time estimates.

### 2.3. Lost & Found System
*   **Report Lost Person**: Users can submit reports with:
    *   Photo (compressed <5MB)
    *   Physical Description (Height, clothes)
    *   Last Seen Location
    *   Guardian Contact Details
*   **Search**: A public feed of missing persons allows anyone to help identify and reunite lost pilgrims.
*   **Privacy**: Sensitive actions (editing reports) are restricted to the creator or admins.

### 2.4. Emergency Response (SOS)
*   **One-Tap SOS**: Dedicated "Emergency Mode" for critical situations.
*   **Long-Press Activation**: Prevents accidental triggers.
*   **Location Sharing**: Instantly shares live GPS coordinates with the Mela Control Room.
*   **Offline Support**: Displays nearby Police Stations and help desks even without internet.
*   **Medical Info**: Displays the user's blood group and medical conditions for first responders.

### 2.5. User Contributions
*   **"Add Place"**: Users can report missing facilities (e.g., a new medical tent or water station).
*   **Approval System**: Submissions are marked as `pending` and do not appear on the map until an Admin approves them.
*   **Community Trust**: Ensures data accuracy while leveraging crowd-sourced information.

### 2.6. Admin Dashboard
*   **Ghat Management**: Update crowd levels (Low/Med/High) in real-time.
*   **Facility Management**: Review, Approve, or Reject user-submitted facilities.
*   **Analytics**: View total users, active emergencies, and system health.

---

## 3. Technology Stack

### 3.1. Frontend (Mobile App)
*   **Framework**: [Flutter](https://flutter.dev/) (Dart) - Cross-platform (Android, iOS, Web).
*   **State Management**: [Riverpod](https://riverpod.dev/) - Reliable, compile-safe state handling.
*   **Architecture**: MVVM-based Repository Pattern (Model-View-ViewModel-Repository).
    *   `Screens`: UI logic.
    *   `Providers`: State encapsulation.
    *   `Repositories`: Data fetching logic.
    *   `Models`: Data structure definitions.

### 3.2. Backend (Firebase)
*   **Firebase Auth**: Google Sign-In handling.
*   **Cloud Firestore**: NoSQL Database for structured data.
    *   `users`: User profiles.
    *   `ghats`: Static locations + dynamic crowd status.
    *   `lost_persons`: Reports of missing individuals.
    *   `facilities`: Public amenities (toilets, camps).
    *   `emergency_alerts`: Active SOS logs.
*   **Firebase Storage**: Hosting for user-uploaded images (Lost & Found photos).
    *   *Rules*: User-isolated folders, 5MB limit.

---

## 4. Directory Structure

```
lib/
├── app.dart                   # Main App Widget & Routing
├── core/                      # Core utilities
│   ├── constants/             # App-wide constants
│   ├── services/              # Firebase, Storage, Location services
│   ├── theme/                 # App Theme (Light/Dark mode)
│   └── widgets/               # Reusable UI components
├── data/                      # Data Layer
│   ├── models/                # Dart classes (User, Ghat, Facility)
│   ├── providers/             # Riverpod providers
│   └── repositories/          # Firestore interaction logic
├── providers/                 # Global state providers (Auth, Theme)
└── screens/                   # UI Screens
    ├── admin/                 # Admin Dashboard & Management
    ├── auth/                  # Login, Onboarding, Profile Creation
    ├── emergency/             # SOS Screen
    ├── facilities/            # Add Facility Screen
    ├── home/                  # Home Dashboard
    ├── lost/                  # Lost & Found Reporting
    ├── navigation/            # Ghat Maps & List
    └── profile/               # User Profile & Activity
```

---

## 5. Security & Data Privacy

### 5.1. Firestore Rules
security is a top priority.
*   **Users**: Can ONLY edit their own data (`request.auth.uid == userId`).
*   **Public Data**: Ghats and Facilities are readable by everyone (`allow read: if true`).
*   **Admin Power**: Only `sourabh3527@gmail.com` has write access to critical collections (`ghats`, `facilities`).
*   **Pending Data**: Users can *create* facility documents but cannot set them to 'approved'. Only admins can change status.

### 5.2. Storage Rules
*   **Isolation**: Users upload to `/user_uploads/{userId}/`.
*   **Validation**: Files must be images/audio and < 5MB size.

---

## 6. How to Run

1.  **Prerequisites**:
    *   Flutter SDK installed.
    *   Firebase Project configured (`google-services.json`).

2.  **Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run**:
    ```bash
    flutter run
    ```
    *   Use `--release` for production builds.

---

## 7. Future Roadmap
1.  **Voice Assistant (Seva AI)**: Integration of AI for voice-based navigation queries in Hindi/Marathi.
2.  **Offline Maps**: Caching map tiles for zero-network zones.
3.  **family Tracking**: Live group location sharing for families.
