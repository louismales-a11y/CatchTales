# Best Fish Buddy - Build Guide

## 📱 Download Latest APK (Android)
https://tinyurl.com/bfree1914

---

## 🪟 Building for Windows

You need a **Windows PC** with:

1. **Install Flutter** (Windows)
   - Download from https://docs.flutter.dev/get-started/install/windows
   - Run `flutter doctor` to verify

2. **Clone the repo**
   ```cmd
   cd C:\Projects
   git clone https://github.com/louismales-a11y/BestFishBuddy.git
   cd BestFishBuddy
   ```

3. **Get dependencies**
   ```cmd
   flutter pub get
   ```

4. **Build**
   ```cmd
   flutter build windows --release
   ```

5. **Output**
   `build\windows\runner\Release\` — contains the `.exe` and all DLLs

---

## 🍎 Building for iOS / macOS

You need a **Mac** with:

### 1. Prerequisites
- Xcode 15+ (from Mac App Store)
- CocoaPods: `sudo gem install cocoapods`
- Flutter (install via `brew install flutter` or from flutter.dev)

### 2. Clone & Setup
```bash
cd ~/Projects
git clone https://github.com/louismales-a11y/BestFishBuddy.git
cd BestFishBuddy
flutter pub get
```

### 3. Firebase Setup for iOS
The Android `google-services.json` is already in the repo. For iOS you need:

1. Go to **Firebase Console** → Project Settings → **Add app** → **iOS**
2. Bundle ID: `com.bestfishbuddy.bestfishbuddy`
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`
5. Also add it in Xcode: open `ios/Runner.xcworkspace` → add file to Runner target

### 4. iOS Build
```bash
cd ios
pod install
cd ..
flutter build ios --release
```

Output: `build/ios/ipa/` — an `.ipa` file for TestFlight or App Store.

### 5. macOS Build
```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/`

---

## ☁️ Firebase Note
The Android Firebase config (`google-services.json`) is already included.
For iOS, your buddy needs to download `GoogleService-Info.plist` from Firebase Console.
For Windows, Firebase Auth works but Firestore needs the config.

## ❓ Help
Each screen in the app has a ❓ button (top-right) with detailed help.
Or email: **BestfishBuddy@gmail.com**
