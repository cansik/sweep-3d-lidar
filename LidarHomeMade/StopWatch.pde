class StopWatch
{
  long startTime = 0;
  long endTime = 0;

  boolean isRunning = false;

  public void start()
  {
    startTime = millis();
    isRunning = true;
  }

  public void stop()
  {
    endTime = millis();
    isRunning = false;
  }

  public long elapsed()
  {
    if (isRunning)
      endTime = millis();
    return endTime - startTime;
  }
}
