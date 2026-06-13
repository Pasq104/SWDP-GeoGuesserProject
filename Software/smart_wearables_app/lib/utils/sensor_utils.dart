// lib/utils/sensor_utils.dart

/// Returns a readable name for a given sensor data type.
String getSensorNameFromType(String dataType) {
  switch (dataType) {
    case 'a':
      return 'Ext Accelerometer';

    case 'g':
      return 'Ext Gyroscope';

    case 'M':
      return 'Magnetometer';

    default:
      return 'Unknown ($dataType)';
  }
}