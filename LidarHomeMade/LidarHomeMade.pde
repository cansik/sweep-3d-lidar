import peasy.*;
import peasy.org.apache.commons.math.*;
import peasy.org.apache.commons.math.geometry.*;

import oscP5.*;
import netP5.*;

import controlP5.*;

import java.util.List;
import java.util.Map;

import peasy.PeasyCam;

import ch.bildspur.sweep.*;

SweepSensor sweep;

PGraphics space;

PeasyCam cam;

PreciseServo servo = new PreciseServo(this, "/dev/tty.SLAB_USBtoUART");

List<CloudPoint> points = new ArrayList<CloudPoint>();

PShape cloud;

boolean isReady = false;
boolean isScanning = false;
int startAngle = 0;
int endAngle = 180;
int currentAngle;

// stand filter
int standFilterSize = 100;
int signalStrengthFilter = 125;

float motorZCorrection = 0; // cm

int scanWaitTime = 50;
int sampleStep = 1;
int scanIterationCount = 1;
float pointSize = 3.0f;

int motorSpeed = 5;
int sampleRate = 500;

boolean camRotate = false;
boolean showLIDAR = true;
boolean isPointFilter = true;

ControlP5 cp5;
ButtonBar sampleRateBar;
ButtonBar speedBar;

void setup()
{
  size(1280, 800, P3D);
  pixelDensity(2);

  cam = new PeasyCam(this, 400);
  cam.setSuppressRollRotationMode();

  space = createGraphics(10, 10, P3D);
  cloud = createShape();

  cp5 = new ControlP5(this);
  cp5.setAutoDraw(false);

  int h = 10;
  cp5.addSlider("sampleStep", 10, 150, 10, h, 100, 15)
    .setRange(1, 15)
    .setLabel("Sample Step");

  h += 20;
  cp5.addSlider("scanIterationCount", 10, 150, 10, h, 100, 15)
    .setRange(1, 15)
    .setLabel("Iteration Count");

  h += 20;
  cp5.addSlider("scanWaitTime", 10, 150, 10, h, 100, 15)
    .setRange(0, 5000)
    .setLabel("Wait Time");

  h += 20;
  speedBar = cp5.addButtonBar("onMotorSpeedChanged")
    .setPosition(10, h)
    .setSize(200, 20)
    .setCaptionLabel("Speed")
    ;
  for (int i = 1; i <= 10; i++)
  {
    speedBar.addItem(i + " Hz", i);
  }
  speedBar.setValue(4);

  h += 25;
  sampleRateBar = cp5.addButtonBar("onSampleRateChanged")
    .setPosition(10, h)
    .setSize(200, 20)
    .setCaptionLabel("Sample Rate")
    ;
  sampleRateBar.addItem("500 Hz", 500);
  sampleRateBar.addItem("750 Hz", 750);
  sampleRateBar.addItem("1000 Hz", 1000);
  sampleRateBar.setValue(0);

  h += 25;
  cp5.addButton("startScan")
    .setValue(100)
    .setPosition(10, h)
    .setSize(80, 19)
    .setCaptionLabel("Scan")
    ;

  cp5.addButton("createPointCloud")
    .setValue(100)
    .setPosition(10 + 85, h)
    .setSize(100, 19)
    .setCaptionLabel("Create Pointcloud")
    ;

  h += 30;
  cp5.addSlider("standFilterSize", 10, 150, 10, h, 100, 15)
    .setRange(0, 180)
    .setLabel("Stand Filter Angle");

  h += 20;
  cp5.addSlider("signalStrengthFilter", 10, 150, 10, h, 100, 15)
    .setRange(0, 255)
    .setLabel("Min Signal Strength");

  h += 20;
  cp5.addSlider("pointSize", 10, 150, 10, h, 100, 15)
    .setRange(0.5, 5)
    .setLabel("Point Size");

  h += 25;
  cp5.addToggle("camRotate")
    .setPosition(10, h)
    .setSize(50, 20)
    .setCaptionLabel("Cam Rotate");

  cp5.addToggle("showLIDAR")
    .setPosition(10 + 55, h)
    .setSize(50, 20)
    .setCaptionLabel("Show LIDAR");

  cp5.addToggle("isPointFilter")
    .setPosition(10 + (2 * 55), h)
    .setSize(50, 20)
    .setCaptionLabel("Point Filter");

  h += 45;
  cp5.addButton("saveCloud")
    .setValue(100)
    .setPosition(10, h)
    .setSize(75, 19)
    .setCaptionLabel("Save Cloud")
    ;

  cp5.addButton("loadCloud")
    .setValue(100)
    .setPosition(10 + 80, h)
    .setSize(75, 19)
    .setCaptionLabel("Load Cloud")
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
    fill(255);
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
    text("scanning " + currentAngle + "°...", 0, 0);
    cam.endHUD();
  }

  // show infos
  cam.beginHUD();

  textSize(14);
  fill(0, 255, 0);
  textAlign(LEFT, CENTER);
  text("FPS: " + frameRate 
    + "\nVertex Count: " + cloud.getVertexCount() 
    + "\nCaptured Vertices: " + points.size(), 20, height - 70);

  cp5.draw();
  cam.endHUD();
}

void performScan()
{
  // move to location
  servo.move(currentAngle);

  // wait for motor to be in area
  delay(scanWaitTime);

  for (int i = 0; i < scanIterationCount; i++)
  {
    // reading samples
    List<SensorSample> samples = readSweepSynchronous(sweep.getDevice());

    println("scanning " + currentAngle + "° with " + samples.size() + " points (" + (i + 1) + ")..:");
    for (SensorSample sample : samples)
    {
      points.add(new CloudPoint(sample, currentAngle));
    }
  }

  // show and move to next angle
  currentAngle += sampleStep;

  if (currentAngle > endAngle)
  {
    println("finished scanning!");
    isScanning = false;
    servo.move(90);

    servo.detach();
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

  int filteredCount = 0;

  float filterStartAngle = 180 - (standFilterSize / 2f);
  float filterEndAngle = 180 + (standFilterSize / 2f);

  for (CloudPoint point : points)
  {
    // check if has to been filtered
    float angle = Math.abs(point.sample.getAngle());
    boolean filteredbyStand = angle >= filterStartAngle && angle <= filterEndAngle;
    boolean fileredbySignal = point.sample.getSignalStrength() < signalStrengthFilter;
    if (isPointFilter && (filteredbyStand || fileredbySignal))
    {
      filteredCount++;
      continue;
    }

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

  println("filtered " + filteredCount + " points!");
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

void onMotorSpeedChanged(int n)
{
  Map<String, Object> values = (Map<String, Object>)speedBar.getItems().get(n);
  motorSpeed = (int)values.get("value");
}

void onSampleRateChanged(int n)
{
  Map<String, Object> values = (Map<String, Object>)sampleRateBar.getItems().get(n);
  sampleRate = (int)values.get("value");
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

void createPointCloud(int value)
{
  if (!isReady)
    return;

  createPointCloudFromData();
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

  println("starting sweep with Speed " + motorSpeed + " Hz and Sample Rate " + sampleRate + " Hz...");

  // setup servo and sweep sensor
  servo.attach();

  sweep = new SweepSensor(this);
  sweep.startAsync("/dev/tty.usbserial-DO004HM4", motorSpeed, sampleRate);

  println("start scanning...");

  isScanning = true;
  currentAngle = startAngle;

  // move and wait at angle
  servo.move(currentAngle);
  delay(1000);

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
