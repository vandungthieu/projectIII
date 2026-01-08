#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include <TinyGPS++.h>
#include <HardwareSerial.h>

// ---------------- WIFI ----------------
const char* ssid = "Dug";
const char* password = "77777777";

// ---------------- MQTT ----------------
const char* mqtt_server = "f275e90fe8454aed8c3d90e35c44fc09.s1.eu.hivemq.cloud";
const int   mqtt_port   = 8883;
const char* mqtt_user   = "dungthieu123";
const char* mqtt_pass   = "Dung.tv215547";

// ---------------- BUZZER ----------------
const int buzzerPin = 19;

// ---------------- GPS ----------------
TinyGPSPlus gps;
HardwareSerial gpsSerial(1); // UART1
const int RXPin = 16;        
const int TXPin = 17;        
const uint32_t GPSBaud = 9600;

// ---------------- DEVICE INFO ----------------
const char* DEVICEID = "device3";
const char* DEVICEKEY = "413d6b176257eaca25077811bca3217d";
Preferences prefs;
String deviceId;
String deviceKey;

// Tạo topic từ DEVICEID
String topic = String("device/") + DEVICEID;

WiFiClientSecure espClient;
PubSubClient client(espClient);

// ---------------- WIFI ----------------
void setup_wifi() {
  Serial.print("Connecting to ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n WiFi connected!");
  Serial.println(WiFi.localIP());
}

// ---------------- MQTT CALLBACK ----------------
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("\nMessage arrived [");
  Serial.print(topic);
  Serial.print("]: ");

  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.println(message);

  // Parse JSON
  StaticJsonDocument<200> doc;
  DeserializationError error = deserializeJson(doc, message);
  if (error) {
    Serial.print(" JSON parse failed: ");
    Serial.println(error.c_str());
    return;
  }

  const char* action = doc["action"];
  if (!action) return;

  String expectedTopic = "buzzer/" + deviceId;
  if (String(topic) == expectedTopic) {
    if (strcmp(action, "on") == 0) {
      digitalWrite(buzzerPin, LOW);
      Serial.println(" Buzzer ON");
    } 
    else if (strcmp(action, "off") == 0) {
      digitalWrite(buzzerPin, HIGH);
      Serial.println(" Buzzer OFF");
    } 
  }
}

// ---------------- MQTT RECONNECT ----------------
void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect(deviceId.c_str(), mqtt_user, mqtt_pass)) {
      Serial.println(" Connected!");

      String buzzerTopic = "buzzer/" + deviceId;
      client.subscribe(buzzerTopic.c_str());
      Serial.print(" Subscribed to: ");
      Serial.println(buzzerTopic);
    } else {
      Serial.print(" failed, rc=");
      Serial.print(client.state());
      Serial.println(" → retry in 5s");
      delay(5000);
    }
  }
}

// ----- gps ---
void readGPSAndSend() {
  static unsigned long lastAuthTime = 0; // thời điểm gửi kèm deviceKey lần cuối
  const unsigned long authInterval = 3600000; // 1 tiếng = 3600000 ms

  while (gpsSerial.available() > 0) {
    gps.encode(gpsSerial.read());
  }

  if (gps.location.isUpdated()) {
    double lat = gps.location.lat();
    double lng = gps.location.lng();
    double speed = gps.speed.kmph();

    Serial.print(" Lat: "); Serial.print(lat, 6);
    Serial.print(", Lng: "); Serial.print(lng, 6);
    Serial.print(", Speed: "); Serial.print(speed);
    Serial.println(" km/h");

    // gửi dữ liệu lên MQTT
    StaticJsonDocument<256> doc;
    doc["latitude"] = lat;
    doc["longitude"] = lng;
    doc["speed"] = speed;

    // nếu đã qua 1 tiếng thêm vào payload
    unsigned long now = millis();
    if (now - lastAuthTime >= authInterval || lastAuthTime == 0) {
      doc["deviceKey"] = deviceKey;
      lastAuthTime = now;
      Serial.println(" Gửi kèm deviceKey (xác thực 1 tiếng/lần)");
    }

    char buffer[256];
    serializeJson(doc, buffer);
    client.publish("esp32/gps", buffer);

    Serial.println("Dữ liệu GPS đã gửi lên MQTT.");
  }
}

// ------test---
void readGPSAndSendTest() {
  static unsigned long lastSend = 0;
  static unsigned long lastAuthTime = 0;
  const unsigned long interval = 15000; 
  const unsigned long authInterval = 3600000; // 1 giờ

  unsigned long now = millis();
  if (now - lastSend < interval) return;  
  lastSend = now;

  double lat = 21.028511 + random(-50, 50) * 0.00001;
  double lng = 105.804817 + random(-50, 50) * 0.00001;
  double speed = random(0, 20);

  Serial.print(" [TEST] Lat: "); Serial.print(lat, 6);
  Serial.print(", Lng: "); Serial.print(lng, 6);
  Serial.print(", Speed: "); Serial.println(speed);

  StaticJsonDocument<256> doc;
  JsonObject loc = doc.createNestedObject("location");
  loc["lat"] = lat;
  loc["lng"] = lng;
  doc["speed"] = speed;


  // Gửi kèm deviceKey nếu cần xác thực
  if (now - lastAuthTime >= authInterval || lastAuthTime == 0) {
    doc["deviceKey"] = deviceKey;
    lastAuthTime = now;
    Serial.println(" Gửi kèm deviceKey (xác thực 1 tiếng/lần)");
  }

  char buffer[256];
  serializeJson(doc, buffer);

  client.publish(topic.c_str(), buffer);


  Serial.println(" [TEST] Đã gửi dữ liệu GPS mô phỏng.\n");
}



// ---------- SETUP ----
void setup() {
  Serial.begin(115200);
  pinMode(buzzerPin, OUTPUT);
  digitalWrite(buzzerPin, HIGH);

  gpsSerial.begin(GPSBaud, SERIAL_8N1, RXPin, TXPin);

  prefs.begin("config", false);
  deviceId = prefs.getString("deviceId", "");
  deviceKey = prefs.getString("deviceKey", "");
  if (deviceId == "" || deviceKey == "") {
    deviceId = DEVICEID;
    deviceKey = DEVICEKEY;
    prefs.putString("deviceId", deviceId);
    prefs.putString("deviceKey", deviceKey);
    Serial.println(" Default device info saved to flash.");
  }

  setup_wifi();
  espClient.setInsecure();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

// --------- LOOP ------
void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  //readGPSAndSend();  // Đọc GPS và gửi lên MQTT
  readGPSAndSendTest();
  delay(1);      
}

{
"deviceId": "device3",
  "deviceKey": "413d6b176257eaca25077811bca3217d",
  "speed": 30,
  "location": {
    "lat": 10.76,
    "lng": 106.66
  }
}
