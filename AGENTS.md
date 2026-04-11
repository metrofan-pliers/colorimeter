# Colorimeter Project

<<<<<<< Updated upstream
## Project Structure
- `.ino` file: ESP32 firmware (main embedded code for the colorimeter device)
- `server.py`: FastAPI server that receives/returns color data from the device
- `run_server.bat`: Windows batch to start the server

## Running the Server
The server requires a Python virtual environment at `C:\Users\igleb\Documents\python\venv`. Use the batch file:
```
run_server.bat
=======
ESP32 color detector (TCS34725 sensor) + Python MQTT relay server.

## Quick Start

```bash
pip install -r requirements.txt
python server.py
>>>>>>> Stashed changes
```
Or manually:
```bash
cd C:\Users\igleb\Documents\python
venv\Scripts\activate
python -m uvicorn server:app --host 0.0.0.0 --port 8000
```

<<<<<<< Updated upstream
## API Endpoints
- `POST /color` - receive color data from device
- `GET /color` - retrieve latest color reading

## No CI/Testing
This repo has no tests, linting, or automated checks configured.
=======
**Windows launcher**: `run_server.bat` (hardcoded path: `C:\Users\igleb\Documents\git\colorimeter`)

## Server

- `http://localhost:8000`
- MQTT broker: `broker.emqx.io:1883`, topic: `colorimeter/reading`
- Endpoints: `GET /`, `GET /color`, `POST /color`, `GET /test-color`
- Port configurable via `PORT` env var

## Arduino

File: `color_and_screen_norm_sound_test_led_button_copy_END.ino`

**Libraries** (Arduino Library Manager):
- `Adafruit TCS34725`, `Adafruit GFX`, `Adafruit SSD1306`, `DFRobotDFPlayerMini`

**Hardware**: ESP32, TCS34725, SSD1306 OLED (0x3C), DFPlayer Mini (Serial2, pins 16/17), button (GPIO32), LED (GPIO27).

**Workflow**: Press button to calibrate on white, then detects 16 colors via HSV thresholds in `detectColor()` (line 65):
- Saturation < 0.18: white/gray/black by brightness
- Pastel: beige (hue 20-50), pink (hue <20 or >320)
- Brown: dark orange (hue <40, sat >0.25, val <0.20)

## Key Files

| File | Purpose |
|------|---------|
| `server.py` | FastAPI + MQTT relay |
| `color_and_screen_norm_sound_test_led_button_copy_END.ino` | ESP32 firmware |
| `run_server.bat` | Windows launcher |
| `requirements.txt` | Python deps: fastapi, uvicorn, paho-mqtt |
>>>>>>> Stashed changes
