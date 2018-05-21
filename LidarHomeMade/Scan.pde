import java.nio.file.Path;
import java.nio.file.Paths;
import org.jengineering.sjmply.PLY;

import static org.jengineering.sjmply.PLYType.*;
import static org.jengineering.sjmply.PLYFormat.*;

class Scan implements Runnable {
  List<CloudPoint> points;
  PShape cloud;

  boolean isScanning = false;
  boolean isCancel = false;

  float motorZCorrection = 0; // cm

  // stand filter
  int standFilterSize = 80;
  int signalStrengthFilter = 50;

  float startAngle = 0f;
  float endAngle = 180f;
  float currentAngle;
  float angleStepSize = 1.0f;

  int scanWaitTime = 50;
  int sampleStep = 1;
  int scanIterationCount = 1;

  int motorSpeed = 5;
  int sampleRate = 500;

  PApplet parent;

  Thread scanThread;

  public Scan(PApplet parent)
  {
    this.parent = parent;
    points = new ArrayList<CloudPoint>();
    cloud = createShape();
  }

  public void start()
  {
    scanThread = new Thread(this);
    scanThread.start();
  }

  public void cancel()
  {
    isCancel = true;

    try
    {
      scanThread.join();
    } 
    catch(Exception ex)
    {
    }
  }

  public void run() {
    prepareScan();
    while (isScanning && !isCancel)
    {
      performScan();
    }
  }

  public void prepareScan()
  {
    if (!isReady)
      return;

    isScanning = true;

    println("starting sweep with Speed " + motorSpeed + " Hz and Sample Rate " + sampleRate + " Hz...");

    // setup servo and sweep sensor
    servo.attach();
    sweep.startAsync(sweepPath, motorSpeed, sampleRate);

    println("start scanning...");
    currentAngle = startAngle;

    // move and wait at angle
    servo.move(currentAngle);
    delay(1000);

    points.clear();
  }

  public void performScan()
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
    currentAngle += (sampleStep * angleStepSize);

    if (currentAngle > endAngle)
    {
      finishedScanning();
    }
  }

  void finishedScanning()
  {
    println("finished scanning!");
    servo.move(90);

    println("finished!");
    isScanning = false;

    servo.detach();
    sweep.stop();

    println("creating point cloud...");
    createPointCloudFromData();
  }

  public void createPointCloudFromData()
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

  public void savePointCloud(String fileName)
  {
    Path path = Paths.get(fileName);
    PLY ply = new PLY();

    PLYElementList vertex = new PLYElementList(cloud.getVertexCount());

    // coordinates
    float[] x = vertex.addProperty(FLOAT32, "x");
    float[] y = vertex.addProperty(FLOAT32, "y");
    float[] z = vertex.addProperty(FLOAT32, "z");

    // colors
    byte[] r = vertex.addProperty(UINT8, "red");
    byte[] g = vertex.addProperty(UINT8, "green");
    byte[] b = vertex.addProperty(UINT8, "blue");

    for (int i = 0; i < cloud.getVertexCount(); i++)
    {
      PVector v = cloud.getVertex(i);
      color c = cloud.getFill(i);

      // coordinates
      x[i] = v.x;
      y[i] = v.y;
      z[i] = v.z;

      // colors
      r[i] = (byte)red(c);
      g[i] = (byte)green(c);
      b[i] = (byte)blue(c);
    }

    ply.elements.put("vertex", vertex);
    //ply.setFormat(ASCII);
    ply.setFormat(BINARY_LITTLE_ENDIAN);
    println(ply);

    try
    {
      ply.save(path);
    } 
    catch (Exception ex) {
      ex.printStackTrace();
    }
  }

  public void loadPointCloud(String fileName)
  {
    Path path = Paths.get(fileName);
    PLY ply = new PLY();

    try
    {
      ply = PLY.load(path);
    } 
    catch (Exception ex) {
      ex.printStackTrace();
    }

    PLYElementList vertex = ply.elements("vertex");

    // coordinates
    float[] x = vertex.property(FLOAT32, "x");
    float[] y = vertex.property(FLOAT32, "y");
    float[] z = vertex.property(FLOAT32, "z");

    // colors
    byte[] r = vertex.property(UINT8, "red");
    byte[] g = vertex.property(UINT8, "green");
    byte[] b = vertex.property(UINT8, "blue");

    cloud = createShape();
    cloud.beginShape(POINTS);

    for (int i = 0; i < x.length; i++)
    {
      int rv = r[i] & 0xFF;
      int gv = g[i] & 0xFF;
      int bv = b[i] & 0xFF;

      cloud.stroke(rv, gv, bv);
      cloud.vertex(x[i], y[i], z[i]);
    }

    cloud.endShape();
  }
}
