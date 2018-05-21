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

void mousePressed() {

  // suppress cam on UI
  if (mouseX > 0 && mouseX < 300 && mouseY > 0 && mouseY < 300) {
    cam.setActive(false);
  } else {
    cam.setActive(true);
  }
}
