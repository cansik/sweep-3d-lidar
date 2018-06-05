import peasy.*;
import peasy.org.apache.commons.math.*;
import peasy.org.apache.commons.math.geometry.*;

import java.util.List;
import java.util.Map;

import peasy.PeasyCam;

import ch.bildspur.sweep.*;

SweepSensor sweep = new SweepSensor(this);

PGraphics space;
PeasyCam cam;

String sweepPath = "/dev/tty.usbserial-DO004HM4";
String servoPath = "/dev/tty.SLAB_USBtoUART";

boolean isSweepAvailable = false;
boolean isServoAvailable = false;

PreciseServo servo = new PreciseServo(this, servoPath);

boolean isReady = false;

float pointSize = 3.0f;

boolean camRotate = false;
boolean showLIDAR = true;
boolean isPointFilter = true;

Scan scan;

Timer recreationTimer = new Timer(1000);
float lastRecreatedAngle = 0.0f;

String softwareVersion = "0.1";

Timer devicesTimer = new Timer(3000);

void setup()
{
  size(1280, 800, P3D);
  pixelDensity(2);

  surface.setTitle("CSK LIDAR " + softwareVersion);

  cam = new PeasyCam(this, 400);
  cam.setSuppressRollRotationMode();

  createNewScan();

  space = createGraphics(10, 10, P3D);
}

void draw()
{
  background(54, 54, 54);

  if (camRotate)
    cam.rotateY(radians(0.5));

  if (scan.isScanning && !sweep.isRunning())
  {
    cam.beginHUD();
    textAlign(CENTER, CENTER);
    translate(width / 2, height / 2);
    fill(255);
    textSize(40);
    text("waiting for lidar...", 0, 0);
    cam.endHUD();
    return;
  }

  // check device status
  if (devicesTimer.elapsed())
  {
    checkDevices();
  }

  displayData();

  // show is scanning info
  if (scan.isScanning)
  {
    if (recreationTimer.elapsed() && lastRecreatedAngle != scan.currentAngle)
    { 
      lastRecreatedAngle = scan.currentAngle;
      scan.createPointCloudFromData();
    }

    cam.beginHUD();
    translate(width / 2, height / 2);

    rectMode(CENTER);
    noStroke();
    fill(0, 100);
    rect(0, 0, width, height);

    textAlign(CENTER, CENTER);
    textSize(40);
    fill(255);
    text("scanning " + scan.currentAngle + "°...", 0, 0);
    cam.endHUD();
  }

  // show infos
  cam.beginHUD();

  textSize(14);

  if (isSweepAvailable && isServoAvailable)
    fill(168, 230, 206);
  else
    fill(232, 23, 93);
  textAlign(LEFT, CENTER);

  String infoText = "FPS: " + frameRate 
    + "\nLIDAR: " + isSweepAvailable + " Servo: " + isServoAvailable
    + "\nVertex Count: " + scan.cloud.getVertexCount() 
    + "\nCaptured Vertices: " + scan.points.size()
    + "\nTime: " + formatTime(scan.watch.elapsed()) 
    + "\nEstimated: " + formatTime(scan.estimatedTime);

  text(infoText, 20, height - 90);

  try
  {
    cp5.draw();
  }
  catch(Exception ex) {
  }
  cam.endHUD();
}

void displayData()
{
  pushMatrix();
  translate(0, 0);

  // draw floor grid
  strokeWeight(1);
  stroke(255);
  noFill();
  box(scan.scanArea.x, scan.scanArea.y, scan.scanArea.z);

  if (showLIDAR)
  {
    // show sweep position
    stroke(167, 34, 110);
    noFill();
    sphereDetail(5);
    sphere(10);

    // render axis marker
    showAxisMarker();
  }

  // render cloud
  shape(scan.cloud);

  popMatrix();
}

void showAxisMarker()
{
  int axisLength = 100;
  strokeWeight(3);

  // x
  stroke(236, 32, 73);
  line(0, 0, 0, axisLength, 0, 0);

  // y
  stroke(47, 149, 153);
  line(0, 0, 0, 0, axisLength, 0);

  // z
  stroke(247, 219, 79);
  line(0, 0, 0, 0, 0, axisLength);
}

void createNewScan()
{
  isReady = false;
  cp5 = new ControlP5(this); 
  scan = new Scan(this);
  setupUI();
  isReady = true;
}

void checkDevices()
{
  isSweepAvailable = new File(sweepPath).exists();
  isServoAvailable = new File(servoPath).exists();
}
