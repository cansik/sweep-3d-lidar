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

PreciseServo servo = new PreciseServo(this, servoPath);

boolean isReady = false;

float pointSize = 3.0f;

boolean camRotate = false;
boolean showLIDAR = true;
boolean isPointFilter = true;

Scan scan;

Timer recreationTimer = new Timer(1000);
float lastRecreatedAngle = 0.0f;

void setup()
{
  size(1280, 800, P3D);
  pixelDensity(2);

  cam = new PeasyCam(this, 400);
  cam.setSuppressRollRotationMode();

  createNewScan();

  space = createGraphics(10, 10, P3D);
}

void draw()
{
  background(0);

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
  fill(0, 255, 0);
  textAlign(LEFT, CENTER);
  text("FPS: " + frameRate 
    + "\nVertex Count: " + scan.cloud.getVertexCount() 
    + "\nCaptured Vertices: " + scan.points.size(), 20, height - 70);

  cp5.draw();
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
  box(300);

  if (showLIDAR)
  {
    // show sweep position
    stroke(255, 255, 0);
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
  stroke(255, 0, 0);
  line(0, 0, 0, axisLength, 0, 0);

  // y
  stroke(0, 255, 0);
  line(0, 0, 0, 0, axisLength, 0);

  // z
  stroke(0, 0, 255);
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
