import io.scanse.sweep.*;

List<SensorSample> readSweepSynchronous(SweepDevice device)
{
  List<SensorSample> result = new ArrayList<SensorSample>();

  for (SweepSample s : device.nextScan())
  {
    result.add(new SensorSample(s));
  }

  return result;
}
