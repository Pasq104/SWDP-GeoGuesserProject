enum HeadGesture {
  none,
  shakeLeft,
  shakeRight,
}

class HeadGestureDetector {
  HeadGestureDetector({
    this.accelThreshold = 2500,
    this.gyroThreshold = 120,
    this.cooldownMs = 1000,
    this.gestureWindowMs = 220,
  });

  final double accelThreshold;
  final double gyroThreshold;

  final int cooldownMs;
  final int gestureWindowMs;

  int _lastGestureTime = 0;
  int _lastAccelPeakTime = 0;

  bool _waitingForGyroDirection = false;

  double? _lastAz;

  HeadGesture detectGesture({
    required double accelZ,
    required double gyroZ,
  }) {
    final int now = DateTime.now().millisecondsSinceEpoch;

    if (_lastAz == null) {
      _lastAz = accelZ;
      return HeadGesture.none;
    }

    final double deltaAccel = accelZ - _lastAz!;
    _lastAz = accelZ;

    // Cooldown globale
    if (now - _lastGestureTime < cooldownMs) {
      return HeadGesture.none;
    }

    // Rilevamento shake tramite accelerometro
    if (deltaAccel.abs() > accelThreshold) {
      _waitingForGyroDirection = true;
      _lastAccelPeakTime = now;
    }

    // Timeout finestra gesture
    if (_waitingForGyroDirection &&
        now - _lastAccelPeakTime > gestureWindowMs) {
      _waitingForGyroDirection = false;
    }

    // Se abbiamo shake recente, usiamo gyro per direzione
    if (_waitingForGyroDirection) {
      if (gyroZ > gyroThreshold) {
        _waitingForGyroDirection = false;
        _lastGestureTime = now;
        return HeadGesture.shakeRight;
      }

      if (gyroZ < -gyroThreshold) {
        _waitingForGyroDirection = false;
        _lastGestureTime = now;
        return HeadGesture.shakeLeft;
      }
    }

    return HeadGesture.none;
  }

  void reset() {
    _lastGestureTime = 0;
    _lastAccelPeakTime = 0;
    _waitingForGyroDirection = false;
    _lastAz = null;
  }
}