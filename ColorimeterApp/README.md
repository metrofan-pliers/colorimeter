# Colorimeter App

Mobile app for receiving color data from the colorimeter device.

## Quick Start

1. Install dependencies:
```bash
cd ColorimeterApp
npm install
```

2. Start development server:
```bash
npx expo start
```

3. Run on Android:
```bash
npx expo run:android
```

## Server Configuration

Edit `App.js` and change the `SERVER_URL` constant to your server address:
```javascript
const SERVER_URL = 'http://YOUR_SERVER_IP:8000';
```

## Building APK

### Option 1: Local Build (requires Android SDK)
```bash
eas build --platform android
```

### Option 2: GitHub Actions (automatic)
Push to main branch and the APK will be built automatically.

Required secrets:
- `EXPO_TOKEN` - Expo token for authentication

## Tech Stack

- React Native (Expo SDK 52)
- JavaScript
