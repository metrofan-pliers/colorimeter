# Colorimeter Project

ESP32 color detector + Python MQTT relay server + React Native (Expo) mobile app.

## Project Structure

```
colorimeter/
├── ColorimeterApp/          # React Native (Expo) mobile app
│   ├── App.js               # Main app code
│   ├── app.json             # Expo config
│   ├── eas.json              # EAS build config
│   ├── package.json          # Dependencies
│   ├── .github/workflows/    # GitHub Actions
│   └── assets/              # Icons
├── server.py                # Python FastAPI server
├── requirements.txt         # Python deps
└── color_and_screen...ino   # ESP32 firmware
```

## Server

- VPS on SprintHost (Ubuntu 24.04)
- SSH: `ssh a1255400@141.8.192.25`
- Service: `systemctl start colorimeter` (autostart enabled)
- MQTT broker: `broker.emqx.io:1883`, topic: `colorimeter/reading`
- Endpoints: `GET /`, `GET /color`, `POST /color`, `GET /test-color`

## Mobile App (ColorimeterApp)

### Tech Stack
- React Native with Expo SDK 52
- JavaScript

### Development
```bash
cd ColorimeterApp
npm install
npx expo start
```

### Building APK
- GitHub Actions: `.github/workflows/build.yml` (requires EXPO_TOKEN)
- Or locally: `eas build --platform android`

### Configuration
Change server URL in `App.js`:
```javascript
const SERVER_URL = 'http://YOUR_SERVER_IP:8000';
```

## Arduino

File: `color_and_screen_norm_sound_test_led_button_copy_END.ino`

**Libraries** (Arduino Library Manager):
- `Adafruit TCS34725`, `Adafruit GFX`, `Adafruit SSD1306`, `DFRobotDFPlayerMini`

**Hardware**: ESP32, TCS34725, SSD1306 OLED (0x3C), DFPlayer Mini (Serial2, pins 16/17), button (GPIO32), LED (GPIO27).
