# Colorimeter Project

Hardware project: ESP32-based color detector using TCS34725 sensor. Arduino code handles calibration and color detection; Python server relays data via MQTT.

## Running the Server

```bash
# Install dependencies first
pip install fastapi uvicorn paho-mqtt

# Run directly
python server.py

# Or use the batch file (hardcoded to C:\Users\igleb\Documents\python)
run_server.bat
```

The server:
- Listens on `http://localhost:8000`
- Connects to public MQTT broker `broker.emqx.io:1883`
- Subscribes to `colorimeter/reading` topic
- Endpoints: `GET /`, `GET /color`, `POST /color`, `GET /test-color`

## Arduino Code

File: `color_and_screen_norm_sound_test_led_button_copy_END.ino`

**Dependencies** (install via Arduino Library Manager or git):
- `Adafruit TCS34725`
- `Adafruit GFX`
- `Adafruit SSD1306`
- `DFRobotDFPlayerMini`

**Hardware**: ESP32, TCS34725 color sensor, SSD1306 OLED (0x3C), DFPlayer Mini (Serial2 on pins 16/17), button (GPIO32), LED (GPIO27).

**Workflow**: On boot, device waits for button press to calibrate on white object, then detects 16 colors by HSV thresholds.

## Color Detection Logic

Located in `detectColor()` function. Colors determined by HSV ranges:
- Saturation < 0.18: white/gray/black by brightness
- Hue-based detection for saturated colors
- Special cases: brown (dark orange), beige/pink (pastel)

## Key Files

- `server.py` - FastAPI + MQTT relay server
- `color_and_screen_norm_sound_test_led_button_copy_END.ino` - ESP32 device code
- `run_server.bat` - Windows launcher (hardcoded path)
- `README.md` - Project overview (in Russian)
