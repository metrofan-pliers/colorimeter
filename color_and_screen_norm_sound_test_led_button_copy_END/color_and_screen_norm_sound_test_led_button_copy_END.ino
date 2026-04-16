#include <Wire.h>
#include <Adafruit_TCS34725.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DFRobotDFPlayerMini.h>
#include <math.h>
#include <WiFi.h>
#include <PubSubClient.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define BUTTON_PIN 32
#define LED_PIN 27

// ============== WIFI НАСТРОЙКИ ==============
const char* WIFI_SSID = "Pixel_9889";
const char* WIFI_PASSWORD = "88888888";

// ============== MQTT НАСТРОЙКИ ==============
const char* MQTT_SERVER = "broker.emqx.io";
const int MQTT_PORT = 1883;
const char* MQTT_TOPIC = "colorimeter/reading";

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
Adafruit_TCS34725 tcs(TCS34725_INTEGRATIONTIME_154MS, TCS34725_GAIN_60X);

HardwareSerial dfSerial(2);
DFRobotDFPlayerMini dfplayer;

WiFiClient espClient;
PubSubClient mqttClient(espClient);

bool lastButtonState = false;
String lastColor = "none";
unsigned long lastSpeakTime = 0;
unsigned long lastMqttTime = 0;

float Kr = 1.0;
float Kg = 1.0;
float Kb = 1.0;
float cWhite = 5000.0;
uint8_t imageBuffer[35000];

int R = 0, G = 0, B = 0;

// ============== MQTT ФУНКЦИИ ==============
void reconnectMQTT() {
    while (!mqttClient.connected()) {
        Serial.print("Connecting to MQTT...");
        String clientId = "ESP32-Colorimeter-" + String(random(9999));
        if (mqttClient.connect(clientId.c_str())) {
            Serial.println("connected");
        } else {
            Serial.print("failed, rc=");
            Serial.print(mqttClient.state());
            Serial.println(" try again in 5 seconds");
            delay(5000);
        }
    }
}

void sendToMQTT(int r, int g, int b) {
    if (!mqttClient.connected()) {
        reconnectMQTT();
    }
    
    char json[100];
    sprintf(json, "{\"r\":%d,\"g\":%d,\"b\":%d}", r, g, b);
    
    mqttClient.publish(MQTT_TOPIC, json);
    Serial.printf("MQTT sent: %s\n", json);
}

// ============== WIFI ФУНКЦИИ ==============
void setupWiFi() {
    delay(10);
    Serial.println();
    Serial.print("Connecting to ");
    Serial.println(WIFI_SSID);
    
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 30) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("");
        Serial.println("WiFi connected");
        Serial.println("IP address: ");
        Serial.println(WiFi.localIP());
    } else {
        Serial.println("");
        Serial.println("WiFi FAILED to connect");
    }
}

void rgbToHSV(float r, float g, float b, float &h, float &s, float &v) {
    float maxVal = max(r, max(g, b));
    float minVal = min(r, min(g, b));
    float delta = maxVal - minVal;

    v = maxVal;

    if (maxVal == 0) {
        s = 0;
        h = 0;
        return;
    }

    s = delta / maxVal;

    if (delta == 0) {
        h = 0;
        return;
    }

    if (maxVal == r)
        h = 60 * fmod(((g - b) / delta), 6);
    else if (maxVal == g)
        h = 60 * (((b - r) / delta) + 2);
    else
        h = 60 * (((r - g) / delta) + 4);

    if (h < 0) h += 360;
}

String detectColor(float r, float g, float b, float vReal) {
    float h, s, v;
    rgbToHSV(r, g, b, h, s, v);

    Serial.printf("HSV H:%.0f S:%.2f Vreal:%.2f\n", h, s, vReal);

    if (vReal < 0.10)
        return "black";

    if (s < 0.18) {
        if (vReal > 0.80) return "white";
        if (vReal > 0.25) return "gray";
        return "black";
    }

    if (s < 0.4 && vReal > 0.4) {
        if (h >= 20 && h < 50) return "beige";
        if (h >= 320 || h < 20) return "pink";
    }

    if (h < 40 && vReal < 0.20 && s > 0.25)
        return "brown";

    if (h >= 30 && h < 55)
        return "yellow";

    if (h >= 5 && h < 25 && vReal >= 0.35)
        return "orange";

    if (h < 10 || h >= 350) return "red";
    if (h > 55 && h < 85) return "lime";
    if (h > 85 && h < 150) return "green";
    if (h > 150 && h < 190) return "cyan";
    if (h > 190 && h < 220) return "light blue";
    if (h > 220 && h < 245) return "blue";
    if (h > 245 && h < 265) return "lilac";
    if (h > 265 && h < 320) return "purple";
    if (h > 320 && h < 350) return "pink";

    return "brown";
}

int gammaCorrect(float v) {
    if (v <= 0.0) return 0;
    if (v >= 1.0) return 255;
    return pow(v, 1.0 / 2.2) * 255;
}

int colorToTrack(String color) {
    if (color == "red") return 1;
    if (color == "green") return 2;
    if (color == "blue") return 3;
    if (color == "yellow") return 4;
    if (color == "orange") return 5;
    if (color == "cyan") return 6;
    if (color == "purple") return 7;
    if (color == "white") return 8;
    if (color == "black") return 9;
    if (color == "beige") return 10;
    if (color == "light blue") return 11;
    if (color == "brown") return 12;
    if (color == "pink") return 13;
    if (color == "lime") return 14;
    if (color == "gray") return 15;
    if (color == "lilac") return 16;
    return 0;
}

void createBMP(uint8_t r, uint8_t g, uint8_t b, uint8_t *buffer, int &fileSize) {
    const int width = 20, height = 20;
    const int rowSize = (3 * width + 3) & ~3;
    fileSize = 54 + rowSize * height;
    memset(buffer, 0, fileSize);

    buffer[0] = 'B'; buffer[1] = 'M';
    buffer[2] = fileSize;
    buffer[3] = fileSize >> 8;
    buffer[10] = 54;
    buffer[14] = 40;
    buffer[18] = width;
    buffer[22] = height;
    buffer[26] = 1;
    buffer[28] = 24;

    int idx = 54;
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            buffer[idx++] = b;
            buffer[idx++] = g;
            buffer[idx++] = r;
        }
        while ((idx - 54) % rowSize) buffer[idx++] = 0;
    }
}

String rgbToHex(int r, int g, int b) {
    char hexCol[8];
    sprintf(hexCol, "#%02X%02X%02X", r, g, b);
    return String(hexCol);
}

void calibrateWhite() {
    Serial.println("Put WHITE object and wait...");
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(1);
    display.setCursor(0, 0);
    display.println("Calibrating...");
    display.display();
    delay(3000);

    uint32_t rSum=0, gSum=0, bSum=0, cSum=0;
    digitalWrite(LED_PIN, HIGH);
    delay(200);

    for(int i=0;i<10;i++){
        uint16_t r,g,b,c;
        tcs.getRawData(&r,&g,&b,&c);
        rSum += r; gSum += g; bSum += b; cSum += c;
        delay(5);
    }
    digitalWrite(LED_PIN, LOW);

    float r = rSum / 10.0;
    float g = gSum / 10.0;
    float b = bSum / 10.0;
    float c = cSum / 10.0;
    cWhite = c;
    Serial.printf("cWhite = %.0f\n", cWhite);

    float rN = r/c;
    float gN = g/c;
    float bN = b/c;

    Kr = 1.0/rN;
    Kg = 1.0/gN;
    Kb = 1.0/bN;
    Serial.println("White calibration done");
}

void setup() {
    Serial.begin(115200);
    Wire.begin(21, 22);

    pinMode(BUTTON_PIN, INPUT_PULLUP);
    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, LOW);

    // ============== WIFI И MQTT ==============
    setupWiFi();
    mqttClient.setServer(MQTT_SERVER, MQTT_PORT);
    
    if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        Serial.println("OLED not found");
        while (1);
    }

    dfSerial.begin(9600, SERIAL_8N1, 16, 17);
    if(!dfplayer.begin(dfSerial)){
        Serial.println("DFPlayer not found");
        while(true);
    }
    dfplayer.volume(30);

    if(!tcs.begin()){
        Serial.println("TCS34725 not found");
        while(true);
    }

    display.clearDisplay();
    display.setTextColor(SSD1306_INVERSE);
    display.setTextSize(2);
    display.setCursor(0,0);
    display.println("Put white");
    display.println("press btn");
    display.display();

    while(digitalRead(BUTTON_PIN) == HIGH) delay(10);
    while(digitalRead(BUTTON_PIN) == LOW) delay(10);

    calibrateWhite();

    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(2);
    display.setCursor(0, 20);
    display.println("Ready!");
    display.display();

    delay(1500);

    lastButtonState = false;
}

void loop() {
    float h, s, v;

    bool buttonPressed = (digitalRead(BUTTON_PIN) == LOW);
    digitalWrite(LED_PIN, buttonPressed ? HIGH : LOW);

    if(!buttonPressed || lastButtonState){
        lastButtonState = buttonPressed;
        
        // MQTT loop
        if (!mqttClient.connected()) {
            reconnectMQTT();
        }
        mqttClient.loop();
        
        return;
    }
    delay(50);
    lastButtonState = buttonPressed;

    uint32_t rSum = 0, gSum = 0, bSum = 0, cSum = 0;
    float r, g, b;
    float rN, gN, bN;

    const int N = 3;
    digitalWrite(LED_PIN, HIGH);
    delay(20);
    for(int i=0; i<N; i++){
        uint16_t rRaw, gRaw, bRaw, cRaw;
        tcs.getRawData(&rRaw, &gRaw, &bRaw, &cRaw);
        rSum += rRaw;
        gSum += gRaw;
        bSum += bRaw;
        cSum += cRaw;
        delay(10);
    }
    digitalWrite(LED_PIN, LOW);

    r = rSum / (float)N;
    g = gSum / (float)N;
    b = bSum / (float)N;
    float c = cSum / (float)N;

    rN = (c > 0) ? (r / c) * Kr : 0;
    gN = (c > 0) ? (g / c) * Kg : 0;
    bN = (c > 0) ? (b / c) * Kb : 0;

    float maxRGB = max(rN, max(gN, bN));
    if (maxRGB > 0) {
        rN /= maxRGB;
        gN /= maxRGB;
        bN /= maxRGB;
    }

    float vReal = c / cWhite;
    if (vReal > 1.0) vReal = 1.0;

    String colorName;
    float rHSV = (c > 0) ? (r / c) * Kr : 0;
    float gHSV = (c > 0) ? (g / c) * Kg : 0;
    float bHSV = (c > 0) ? (b / c) * Kb : 0;
    rgbToHSV(rN, gN, bN, h, s, v);
    
    colorName = detectColor(rHSV, gHSV, bHSV, vReal);
    Serial.printf("FINAL: %s\n", colorName.c_str());

    float brightness = vReal; 
    R = gammaCorrect(rN * brightness);
    G = gammaCorrect(gN * brightness);
    B = gammaCorrect(bN * brightness);

    String hexColor = rgbToHex(R, G, B);

    unsigned long now = millis();
    
    // ============== ОТПРАВКА В MQTT ==============
    if(now - lastMqttTime > 1000) {
        sendToMQTT(R, G, B);
        lastMqttTime = now;
    }
    
    if(now - lastSpeakTime > 500){
        int track = colorToTrack(colorName);
        if(track>0) dfplayer.play(track);

        int imageSize=0;
        createBMP(R,G,B,imageBuffer,imageSize);

        display.clearDisplay();

        display.setTextSize(1);
        display.setCursor(0, 55);
        display.printf("H:%3.0f", h);
        display.setCursor(40, 55);
        display.printf("S:%.0f", s*100);
        display.setCursor(90, 55);
        display.printf("V:%.0f", vReal*100);

        display.setTextColor(SSD1306_WHITE);
        display.setTextSize(2.7);
        display.setCursor(0,10);
        display.println(colorName);

        display.setTextSize(1);
        display.setCursor(0,45);
        display.printf("R:%3d G:%3d B:%3d",R,G,B);

        display.setTextSize(1);
        display.setCursor(0, 35);   
        display.println(hexColor);

        display.display();

        lastColor=colorName;
        lastSpeakTime=now;
    }

    Serial.printf("RAW R:%.0f G:%.0f B:%.0f | %s\n", r,g,b,colorName.c_str());
}
