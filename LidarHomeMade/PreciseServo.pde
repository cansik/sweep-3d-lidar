import processing.serial.*;

class PreciseServo
{
  int minPulse = 500;
  int maxPulse = 2570;

  int currentPulse = 0;

  int minDegree = 0;
  int maxDegree = 180;

  String portName;
  Serial servoPort;

  PApplet parent;

  public PreciseServo(PApplet parent, String portName)
  {
    currentPulse = getMidPulse();
    this.portName = portName;
    this.parent = parent;
  }

  public void attach()
  {
    servoPort = new Serial(parent, portName, 115200);
  }

  public void detach()
  {
    servoPort.stop();
    servoPort = null;
  }

  public void move(float angle)
  {
    int degreeRange = maxDegree - minDegree;
    int pulseRange = maxPulse - minPulse;

    float minStepSize = pulseRange / (float)degreeRange;
    float step = angle * minStepSize;

    currentPulse = minPulse + Math.round(step);

    writePulse(currentPulse);
  }

  public int getMidPulse()
  {
    return (maxPulse - minPulse) / 2;
  }

  void writePulse(int pulse)
  {
    servoPort.write("p:" + pulse);
  }
}
