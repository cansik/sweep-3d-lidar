#include <Arduino.h>

// serial
#define BAUD_RATE 115200


void setup() {
    Serial.begin(BAUD_RATE);

    // wait 3000 seconds for debugging
    delay(3000);

    Serial.println("setup finished!");
}

void loop() {

}