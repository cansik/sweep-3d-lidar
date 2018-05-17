#include <Arduino.h>
#include <controller/BaseController.h>
#include <controller/network/NetworkController.h>
#include <controller/network/OTAController.h>
#include <controller/network/OscController.h>
#include <Wire.h>
#include <Servo.h>
#include <controller/servo/SerialServoController.h>

// serial
#define BAUD_RATE 115200

// hardware
#define SERVO_PIN 18

// network
#define DEVICE_NAME "esp-lidar-master"

#define SSID_NAME "esp-lidar"
#define SSID_PASSWORD "lidar"

#define OTA_PASSWORD "lidar"
#define OTA_PORT 8266

#define OSC_OUT_PORT 9000
#define OSC_IN_PORT 8000


// global typedefs
typedef BaseController *BaseControllerPtr;

// controllers
auto network = NetworkController(DEVICE_NAME, SSID_NAME, SSID_PASSWORD, WIFI_AP);
auto ota = OTAController(DEVICE_NAME, OTA_PASSWORD, OTA_PORT);
auto osc = OscController(OSC_IN_PORT, OSC_OUT_PORT);
auto serialServo = SerialServoController(SERVO_PIN);

// controller list
BaseControllerPtr controllers[] = {
        &network,
        &ota,
        &osc,
        &serialServo
};

void setup() {
    Serial.begin(BAUD_RATE);

    // wait 3000 seconds for debugging
    delay(3000);

    // setup controllers
    for (auto &controller : controllers) {
        controller->setup();
    }

    Serial.println("setup finished!");
}

void loop() {
    // loop controllers
    for (auto &controller : controllers) {
        controller->loop();
    }
}