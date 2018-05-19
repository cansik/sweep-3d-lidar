//
// Created by Florian on 17.05.18.
//

#include <controller/BaseController.h>
#include "SerialServoController.h"

SerialServoController::SerialServoController(uint8_t devicePin) {
    this->devicePin = devicePin;
}

void SerialServoController::setup() {
    BaseController::setup();

    // setup hardware
    //servo.attach(SERVO_PIN, -1, 0, 180, 500, 2500); // 180° for PDI-6221MG
    servo.attach(devicePin, -1, 0, 180, 650, 2150); // 180° for MG995R
    //servo.attach(devicePin, -1, 0, 180, 1000, 2000); // 180° correct format
    servo.write(90);
}

void SerialServoController::loop() {
    BaseController::loop();

    // read command
    inputString = "";
    while (Serial.available()) {
        auto c = static_cast<char>(Serial.read());
        inputString += c;
        delay(2);
    }

    // if no input -> opt out
    if (inputString.length() == 0) {
        return;
    }

    // process input
    if(inputString.startsWith("m"))
    {
        // move, example: "m:23"
        inputString.remove(0, 2);
        auto angle = inputString.toInt();
        servo.write(angle);

        Serial.println("moving to " + angle);
    }

    if(inputString.startsWith("p"))
    {
        // move with pulse width, example: "p:1500"
        inputString.remove(0, 2);
        auto pulseWidth = inputString.toInt();
        servo.writeMicroseconds(pulseWidth);

        Serial.println("moving to " + pulseWidth);
    }
}
