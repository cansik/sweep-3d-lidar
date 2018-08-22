import controlP5.*;

ControlP5 cp5;

ButtonBar sampleRateBar;
ButtonBar speedBar;
ButtonBar angleStepSizeBar;
CustomColorPicker pointColorPicker;

int uiHeight;

void setupUI()
{
  cp5.setAutoDraw(false);

  int h = 10;
  cp5.addSlider("sampleStep", 10, 150, 10, h, 100, 15)
    .setRange(1, 15)
    .setLabel("Sample Step")
    .plugTo(scan)
    .setValue(scan.sampleStep);

  h += 25;
  angleStepSizeBar = cp5.addButtonBar("onAngleStepSizeChanged")
    .setPosition(10, h)
    .setSize(200, 20)
    .setCaptionLabel("Angle Step");
  angleStepSizeBar.addItem("0.25°", 0.25f);
  angleStepSizeBar.addItem("0.5°", 0.5f);
  angleStepSizeBar.addItem("0.75°", 0.75f);
  angleStepSizeBar.addItem("1°", 1f);
  angleStepSizeBar.changeItem("1°", "selected", true);

  h += 25;
  cp5.addSlider("scanIterationCount", 10, 150, 10, h, 100, 15)
    .setRange(1, 15)
    .setLabel("Iteration Count")
    .plugTo(scan)
    .setValue(scan.scanIterationCount);

  h += 20;
  cp5.addSlider("scanWaitTime", 10, 150, 10, h, 100, 15)
    .setRange(0, 5000)
    .setLabel("Wait Time")
    .plugTo(scan)
    .setValue(scan.scanWaitTime);

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
  speedBar.changeItem("5 Hz", "selected", true);

  h += 25;
  sampleRateBar = cp5.addButtonBar("onSampleRateChanged")
    .setPosition(10, h)
    .setSize(200, 20)
    .setCaptionLabel("Sample Rate")
    ;
  sampleRateBar.addItem("500 Hz", 500);
  sampleRateBar.addItem("750 Hz", 750);
  sampleRateBar.addItem("1000 Hz", 1000);
  sampleRateBar.changeItem("500 Hz", "selected", true);

  h += 30;
  cp5.addButton("startScan")
    .setValue(100)
    .setPosition(10, h)
    .setSize(80, 19)
    .setCaptionLabel("Scan")
    ;

  cp5.addButton("cancelScan")
    .setValue(100)
    .setPosition(10 + 85, h)
    .setSize(75, 19)
    .setCaptionLabel("Cancel Scan")
    ;

  h += 30;
  cp5.addSlider("standFilterSize", 10, 150, 10, h, 100, 15)
    .setRange(0, 180)
    .setLabel("Stand Filter Angle")
    .plugTo(scan)
    .setValue(scan.standFilterSize);

  h += 20;
  cp5.addSlider("signalStrengthFilter", 10, 150, 10, h, 100, 15)
    .setRange(0, 255)
    .setLabel("Min Signal Strength")
    .plugTo(scan)
    .setValue(scan.signalStrengthFilter);

  h += 25;
  cp5.addSlider("x", 10, 150, 10, h, 100, 15)
    .setRange(0, 5000)
    .setLabel("Area Width")
    .plugTo(scan.scanArea)
    .setValue(scan.scanArea.x);

  h += 20;
  cp5.addSlider("z", 10, 150, 10, h, 100, 15)
    .setRange(0, 5000)
    .setLabel("Area Length")
    .plugTo(scan.scanArea)
    .setValue(scan.scanArea.z);

  h += 20;
  cp5.addSlider("y", 10, 150, 10, h, 100, 15)
    .setRange(0, 5000)
    .setLabel("Area Height")
    .plugTo(scan.scanArea)
    .setValue(scan.scanArea.y);

  h += 25;
  cp5.addSlider("pointSize", 10, 150, 10, h, 100, 15)
    .setRange(0.5, 5)
    .setLabel("Point Size");

  h += 25;
  cp5.addSlider("cloudScale", 10, 150, 10, h, 100, 15)
    .setRange(0.2, 3)
    .setLabel("Cloud Scale");

  h += 25;
  /*
  cp5.addColorPicker("colorPicker")
   .setWidth(100)
   .setPosition(10, h)
   .setColorValue(pointColor);
   */
  pointColorPicker = new CustomColorPicker(cp5, "colorPicker");
  pointColorPicker.setItemSize(100, 10);
  pointColorPicker.setPosition(10, h);
  pointColorPicker.setColorValue(pointColor);


  h += 100;
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
  cp5.addToggle("changePowerSafeMode")
    .setPosition(10, h)
    .setSize(50, 20)
    .setCaptionLabel("Power Safe")
    .setValue(powerSafeMode);

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

  h += 30;
  cp5.addButton("newScanPressed")
    .setValue(100)
    .setPosition(10, h)
    .setSize(75, 19)
    .setCaptionLabel("New Scan")
    ;

  cp5.addButton("createPointCloud")
    .setValue(100)
    .setPosition(10 + 80, h)
    .setSize(100, 19)
    .setCaptionLabel("Create Pointcloud")
    ;

  uiHeight = h;
}

void onMotorSpeedChanged(int n)
{
  Map<String, Object> values = (Map<String, Object>)speedBar.getItems().get(n);
  scan.motorSpeed = (int)values.get("value");
}

void onSampleRateChanged(int n)
{
  Map<String, Object> values = (Map<String, Object>)sampleRateBar.getItems().get(n);
  scan.sampleRate = (int)values.get("value");
}

void onAngleStepSizeChanged(int n)
{
  Map<String, Object> values = (Map<String, Object>)angleStepSizeBar.getItems().get(n);
  scan.angleStepSize = (float)values.get("value");
}

void createPointCloud(int value)
{
  if (!isReady)
    return;

  scan.createPointCloudFromData();
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

void saveFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    String path = selection.getAbsolutePath();
    scan.savePointCloud(path);
  }
}

void openFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    String path = selection.getAbsolutePath();

    createNewScan();
    scan.loadPointCloud(path);
  }
}

void startScan(int value)
{
  if (!isReady)
    return;
  scan.start();
}

void newScanPressed(int value)
{
  if (!isReady)
    return;
  createNewScan();
}

void cancelScan(int value)
{
  if (!isReady)
    return;

  scan.cancel();
}

void changePowerSafeMode(int value)
{
  if (!isReady)
    return;

  powerSafeMode = !powerSafeMode;
  powerModeSwitched = true;
}

void colorPicker(int col) {
  if (!isReady)
    return;

  pointColor = col;
}

public String formatTime(long millis)
{
  long second = (millis / 1000) % 60;
  long minute = (millis / (1000 * 60)) % 60;
  long hour = (millis / (1000 * 60 * 60)) % 24;

  if (minute == 0 && hour == 0 && second == 0)
    return String.format("%02dms", millis);

  if (minute == 0 && hour == 0)
    return String.format("%02ds", second);

  if (hour == 0)
    return String.format("%02dm %02ds", minute, second);

  return String.format("%02dh %02dm %02ds", hour, minute, second);
}
