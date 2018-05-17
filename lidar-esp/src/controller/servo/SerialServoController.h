//
// Created by Florian on 17.05.18.
//

#ifndef LIDAR_ESP_SERIALSERVOCONTROLLER_H
#define LIDAR_ESP_SERIALSERVOCONTROLLER_H

#include <Servo.h>

class SerialServoController : public BaseController {

private:
    uint8_t devicePin;
    Servo servo;
    String inputString;

public:
    explicit SerialServoController(uint8_t devicePin);

    void setup() override;

    void loop() override;
};

#endif //LIDAR_ESP_SERIALSERVOCONTROLLER_H
