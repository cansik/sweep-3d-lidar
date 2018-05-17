import processing.serial.*;
import controlP5.*;

OscP5 oscP5;
NetAddress servoRemote = new NetAddress("192.168.1.24", 8000);

String servoSerialPortName = "/dev/tty.SLAB_USBtoUART";
Serial servoPort;

int servoPosition = 90;

void setupServo()
{
  //oscP5 = new OscP5(this, 9000);

  servoPort = new Serial(this, servoSerialPortName, 115200);
}

void setServo(float angle)
{
  // osc
  /*
  OscMessage myMessage = new OscMessage("/floje/servo/y");
   myMessage.add(angle);
   oscP5.send(myMessage, servoRemote);
   */

  // serial
  servoPort.write("m:" + Math.round(angle));
}

void moveServo(int angle)
{
  int delta = Math.abs(angle - servoPosition);
  int direction = (angle - servoPosition) > 0 ? 1 : -1;

  for (int i = 0; i < delta; i++)
  {
    servoPosition += direction;
    setServo(servoPosition);
    delay(50);
  }
}

void moveServoInstant(int angle)
{
  servoPosition = angle;
  setServo(servoPosition);
}
