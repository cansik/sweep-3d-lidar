import java.nio.file.Path;
import java.nio.file.Paths;
import org.jengineering.sjmply.PLY;

import static org.jengineering.sjmply.PLYType.*;
import static org.jengineering.sjmply.PLYFormat.*;

void savePointCloud(PShape cloud, String fileName)
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
  println(ply);

  try
  {
    ply.save(path);
  } 
  catch (Exception ex) {
    ex.printStackTrace();
  }
}

PShape loadPointCloud(String fileName)
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
  return cloud;
}
