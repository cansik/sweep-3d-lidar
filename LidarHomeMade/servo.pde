// low => 15 high => 170
int servoPosition = 90;

void setServo(float angle)
{
  OscMessage myMessage = new OscMessage("/floje/servo/y");
  myMessage.add(angle);
  oscP5.send(myMessage, servoRemote);
}

void moveServo(int angle)
{
  int delta = Math.abs(angle - servoPosition);
  int direction = (angle - servoPosition) > 0 ? 1 : -1;
  
  for(int i = 0; i < delta; i++)
  {
      servoPosition += direction;
      setServo(servoPosition);
      delay(50);
  }
}
