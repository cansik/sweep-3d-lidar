class CustomColorPicker extends ColorPicker {
  CustomColorPicker(ControlP5 cp5, String theName) {
    super(cp5, cp5.getTab("default"), theName, 0, 0, 100, 10);
  }

  void setItemSize(int w, int h) {
    sliderRed.setSize(w, h);
    sliderGreen.setSize(w, h);
    sliderBlue.setSize(w, h);
    sliderAlpha.setSize(w, h);

    // you gotta move the sliders as well or they will overlap
    /*
    sliderGreen.setPosition(PVector.add(sliderGreen.getPosition(), new PVector(0, h-10)));
     sliderBlue.setPosition(PVector.add(sliderBlue.getPosition(), new PVector(0, 2*(h-10))));
     sliderAlpha.setPosition(PVector.add(sliderAlpha.getPosition(), new PVector(0, 3*(h-10))));
     */
  }
}
