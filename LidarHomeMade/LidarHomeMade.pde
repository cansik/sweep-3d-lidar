import peasy.*;
import peasy.org.apache.commons.math.*;
import peasy.org.apache.commons.math.geometry.*;

import oscP5.*;
import netP5.*;

import java.util.List;

import peasy.PeasyCam;

import ch.bildspur.sweep.*;

import controlP5.*;

OscP5 oscP5;
NetAddress servoRemote = new NetAddress("192.168.1.24", 8000);

SweepSensor sweep;

PGraphics space;

PeasyCam cam;

List<CloudPoint> points = new ArrayList<CloudPoint>();

PShape cloud;

boolean isScanning = false;
int startAngle = 15; //15;
int endAngle = 175; //170;
int currentAngle;

float motorZCorrection = 10.5; // cm

int scanWaitTime = 3000;
int sampleStep = 3;
float pointSize = 3.0f;

int motorSpeed = 1;
int sampleRate = 1000;

boolean camRotate = false;
boolean showLIDAR = true;

ControlP5 cp5;

void setup()
{
  size(1280, 800, P3D);

  oscP5 = new OscP5(this, 9000);

  cam = new PeasyCam(this, 400);
  cam.setSuppressRollRotationMode();

  space = createGraphics(10, 10, P3D);
  cloud = createShape();

  sweep = new SweepSensor(this);
  sweep.startAsync("/dev/tty.usbserial-DO004HM4", motorSpeed, sampleRate);

  cp5 = new ControlP5(this);
  cp5.setAutoDraw(false);

  cp5.addSlider("sampleStep", 10, 150, 10, 10, 100, 15)
    .setRange(1, 15)
    .setLabel("Sample Step");

  cp5.addSlider("pointSize", 10, 150, 10, 30, 100, 15)
    .setRange(0.5, 5)
    .setLabel("Point Size");

  cp5.addSlider("scanWaitTime", 10, 150, 10, 50, 100, 15)
    .setRange(0, 5000)
    .setLabel("Wait Time");

  cp5.addToggle("camRotate")
    .setPosition(10, 70)
    .setSize(50, 20)
    .setCaptionLabel("Cam Rotate");

  cp5.addToggle("showLIDAR")
    .setPosition(10, 110)
    .setSize(50, 20)
    .setCaptionLabel("Show LIDAR");
}

void draw()
{
  background(0);

  if (camRotate)
    cam.rotateY(radians(0.5));

  if (!sweep.isRunning())
  {
    cam.beginHUD();
    textAlign(CENTER, CENTER);
    translate(width / 2, height / 2);
    textSize(40);
    text("waiting for sweep...", 0, 0);
    cam.endHUD();
    return;
  }

  if (isScanning)
  {
    performScan();
  }

  displayData();

  // show is scanning info
  if (isScanning)
  {
    cam.beginHUD();
    translate(width / 2, height / 2);

    rectMode(CENTER);
    noStroke();
    fill(0, 100);
    rect(0, 0, width, height);

    textAlign(CENTER, CENTER);
    textSize(40);
    fill(255);
    text("scanning (" + currentAngle + "°)...", 0, 0);
    cam.endHUD();
  }

  // show infos
  cam.beginHUD();
  cp5.draw();

  textSize(14);
  fill(0, 255, 0);
  textAlign(LEFT, CENTER);
  text("FPS: " + frameRate + "\nPoints: " + points.size(), 20, height - 70);
  cam.endHUD();
}

void performScan()
{
  // move to location
  moveServo(currentAngle);

  // wait for scanning area
  delay(scanWaitTime);

  // reading samples
  List<SensorSample> samples = sweep.getSamples();

  println("scanning " + currentAngle + "° with " + samples.size() + " points..:");
  for (SensorSample sample : samples)
  {
    points.add(new CloudPoint(sample, currentAngle));
  }

  // show and move to next angle
  currentAngle += sampleStep;

  if (currentAngle > endAngle)
  {
    println("finished scanning!");
    isScanning = false;
    moveServo(90);

    println("creating point cloud...");
    createPointCloudFromData();

    println("finished!");
  }
}

void createPointCloudFromData()
{
  cloud = createShape();
  cloud.beginShape(POINTS);

  for (CloudPoint point : points)
  {
    space.pushMatrix();

    space.rotateZ(radians(180));
    space.rotateX(radians(-point.recordAngle));

    space.translate(point.sample.getLocation().x, point.sample.getLocation().y, motorZCorrection);

    cloud.fill(255, 0, point.sample.getSignalStrength());
    cloud.stroke(255, 0, point.sample.getSignalStrength());
    cloud.strokeWeight(pointSize);

    float x = space.modelX(0f, 0f, 0f);
    float y = space.modelY(0f, 0f, 0f);
    float z = space.modelZ(0f, 0f, 0f);

    cloud.vertex(x, y, z);
    space.popMatrix();
  }
  cloud.endShape();
}

void displayData()
{
  pushMatrix();
  translate(0, 0);

  // draw floor grid
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
  }

  // render cloud
  shape(cloud);
  popMatrix();
}

void keyPressed()
{
  if (key == 's')
  {
    println("start scanning...");

    isScanning = true;
    currentAngle = startAngle;

    points.clear();
  }
}

void mousePressed() {

  // suppress cam on UI
  if (mouseX > 0 && mouseX < 300 && mouseY > 0 && mouseY < 300) {
    cam.setActive(false);
  } else {
    cam.setActive(true);
  }
}
