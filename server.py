import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import paho.mqtt.client as mqtt
import json
from datetime import datetime

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

latest_color = {
    "r": 0,
    "g": 0,
    "b": 0,
    "hex": "#000000",
    "hsv": {"h": 0, "s": 0, "v": 0},
    "timestamp": None
}

mqtt_client = None

def rgb_to_hsv(r, g, b):
    r, g, b = r/255.0, g/255.0, b/255.0
    mx = max(r, g, b)
    mn = min(r, g, b)
    df = mx - mn
    
    if mx == mn:
        h = 0
    elif mx == r:
        h = (60 * ((g-b)/df) + 360) % 360
    elif mx == g:
        h = (60 * ((b-r)/df) + 120) % 360
    elif mx == b:
        h = (60 * ((r-g)/df) + 240) % 360
    
    s = 0 if mx == 0 else (df/mx)*100
    v = mx * 100
    
    return {"h": round(h), "s": round(s), "v": round(v)}

def rgb_to_hex(r, g, b):
    return "#{:02x}{:02x}{:02x}".format(r, g, b).upper()

def on_mqtt_message(client, userdata, message):
    global latest_color
    
    try:
        data = json.loads(message.payload.decode())
        
        r = int(data.get("r", 0))
        g = int(data.get("g", 0))
        b = int(data.get("b", 0))
        
        latest_color = {
            "r": r,
            "g": g,
            "b": b,
            "hex": rgb_to_hex(r, g, b),
            "hsv": rgb_to_hsv(r, g, b),
            "timestamp": datetime.now().isoformat()
        }
        
        print(f"Получен цвет: {latest_color['hex']} RGB({r},{g},{b})")
        
    except Exception as e:
        print(f"Ошибка обработки: {e}")

def setup_mqtt():
    global mqtt_client
    
    mqtt_client = mqtt.Client()
    mqtt_client.on_message = on_mqtt_message
    
    mqtt_client.connect("broker.emqx.io", 1883, 60)
    mqtt_client.subscribe("colorimeter/reading")
    mqtt_client.loop_start()
    
    print("MQTT подключён к broker.emqx.io")
    print("Ожидание данных от ESP32...")

@app.on_event("startup")
async def startup_event():
    setup_mqtt()

@app.get("/")
async def root():
    return {
        "status": "ok",
        "message": "Colorimeter Server",
        "latest_color": latest_color
    }

@app.get("/color")
async def get_color():
    return latest_color

@app.post("/color")
async def post_color(data: dict):
    global latest_color
    
    r = int(data.get("r", 0))
    g = int(data.get("g", 0))
    b = int(data.get("b", 0))
    
    latest_color = {
        "r": r,
        "g": g,
        "b": b,
        "hex": rgb_to_hex(r, g, b),
        "hsv": rgb_to_hsv(r, g, b),
        "timestamp": datetime.now().isoformat()
    }
    
    return {"status": "ok"}

@app.get("/test-color")
async def test_color():
    global latest_color
    
    import random
    r = random.randint(0, 255)
    g = random.randint(0, 255)
    b = random.randint(0, 255)
    
    latest_color = {
        "r": r,
        "g": g,
        "b": b,
        "hex": rgb_to_hex(r, g, b),
        "hsv": rgb_to_hsv(r, g, b),
        "timestamp": datetime.now().isoformat()
    }
    
    return {"status": "ok", "color": latest_color}

if __name__ == "__main__":
    import uvicorn
    setup_mqtt()
    
    print("=" * 40)
    print("СЕРВЕР ЗАПУЩЕН!")
    print("=" * 40)
    
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
