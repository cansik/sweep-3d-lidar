class Timer {
  long previousMillis = 0;
  long waitTime;

  public Timer(long waitTime)
  {
    this.waitTime = waitTime;
  }

  public boolean elapsed() {
    long currentMillis = millis();
    boolean result = currentMillis - previousMillis >= waitTime;

    if (result)
      previousMillis = currentMillis;

    return result;
  }

  public void reset() {
    previousMillis = millis();
  }

  public  void setWaitTime( long waitTime) {
    this.waitTime = waitTime;
  }
}
