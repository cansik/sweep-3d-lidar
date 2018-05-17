import peasy.*;
import peasy.org.apache.commons.math.*;
import peasy.org.apache.commons.math.geometry.*;

import oscP5.*;
import netP5.*;

import java.util.List;

import peasy.PeasyCam;

import ch.bildspur.sweep.*;

SweepSensor sweep;

PGraphics space;

PeasyCam cam;

List<CloudPoint> points = new ArrayList<CloudPoint>();

PShape cloud;

boolean isReady = false;
boolean isScanning = false;
int startAngle = 0; //15;
int endAngle = 180;
int currentAngle;

float motorZCorrection = 0; // cm

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

  cam = new PeasyCam(this, 400);
  cam.setSuppressRollRotationMode();

  space = createGraphics(10, 10, P3D);
  cloud = createShape();

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

  cp5.addButton("saveCloud")
    .setValue(100)
    .setPosition(10, 150)
    .setSize(200, 19)
    .setCaptionLabel("Save Cloud")
    ;

  cp5.addButton("loadCloud")
    .setValue(100)
    .setPosition(10, 175)
    .setSize(200, 19)
    .setCaptionLabel("Load Cloud")
    ;

  cp5.addButton("startScan")
    .setValue(100)
    .setPosition(10, 200)
    .setSize(200, 19)
    .setCaptionLabel("Scan")
    ;
}

void draw()
{
  background(0);

  // set ready!
  if (!isReady)
    isReady = true;

  if (camRotate)
    cam.rotateY(radians(0.5));

  if (isScanning && !sweep.isRunning())
  {
    cam.beginHUD();
    textAlign(CENTER, CENTER);
    translate(width / 2, height / 2);
    textSize(40);
    text("waiting for lidar...", 0, 0);
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
  moveServoInstant(currentAngle);

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
    moveServoInstant(90);

    closeServo();
    sweep.stop();

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

    // fix rotational things
    space.rotateY(radians(-90));
    space.rotateZ(radians(-90));

    // add servo movement
    space.rotateX(radians(-point.recordAngle));

    // correct translation
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
  shape(cloud);

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

void keyPressed()
{
  if (key == 'c')
  {
    startScan(100);
  }

  if (key == 's')
  {
    saveCloud(100);
  }
}

void saveCloud(int value)
{
  if (!isReady)
    return;

  selectOutput("PLY file to store cloud:", "saveFileSelected");
}

void loadCloud(int value)
{
  if (!isReady)
    return;

  selectInput("PLY file to load cloud:", "openFileSelected");
}

void startScan(int value)
{
  if (!isReady)
    return;

  // setup servo and sweep sensor
  setupServo();

  sweep = new SweepSensor(this);
  sweep.startAsync("/dev/tty.usbserial-DO004HM4", motorSpeed, sampleRate);

  println("start scanning...");

  isScanning = true;
  currentAngle = startAngle;

  points.clear();
}

void mousePressed() {

  // suppress cam on UI
  if (mouseX > 0 && mouseX < 300 && mouseY > 0 && mouseY < 300) {
    cam.setActive(false);
  } else {
    cam.setActive(true);
  }
}

void saveFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    String path = selection.getAbsolutePath();
    savePointCloud(cloud, path);
  }
}

void openFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    String path = selection.getAbsolutePath();
    cloud = loadPointCloud(path);
  }
}
