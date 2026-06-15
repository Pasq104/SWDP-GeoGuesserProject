import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:smart_wearables_app/utils/head_gesture_detector.dart';

class HeadCursorController extends ChangeNotifier {
  double cursorX = 0.5;
  double cursorY = 0.5;

  double gyroOffsetY = 0.0;
  double gyroOffsetZ = 0.0;

  double filteredGY = 0.0;
  double filteredGZ = 0.0;

  double calibrationSumY = 0.0;
  double calibrationSumZ = 0.0;
  int calibrationSamples = 0;

  bool isCalibrating = false;

  final double gyroSensitivity = 250.0 / 32767.0;

  final double sensitivityX = 0.0016;
  final double sensitivityY = 0.0016;

  final double smoothingX = 0.90;
  final double smoothingY = 0.90;

  final double deadZoneX = 0.50;
  final double deadZoneY = 0.50;

  final int calibrationRequiredSamples = 40;

  final int dwellDelayMs = 500;
  final int dwellTimeMs = 700;
  final double stillThreshold = 0.03;

  double lastStillX = 0.5;
  double lastStillY = 0.5;

  DateTime? dwellStartTime;
  double dwellProgress = 0.0;
  bool dwellTriggered = false;

  String clickStatus = '';

  bool hasNewData = false;

  DateTime? _cursorLockedUntil;

  final HeadGestureDetector gestureDetector = HeadGestureDetector();

  HeadGesture lastGesture = HeadGesture.none;

  double _lastAccelZ = 0.0;
  double _lastAccelPeak = 0.0;
  DateTime? _lastAccelPeakTime;

  bool hasRecentAccelShake({
    double threshold = 2500,
    int withinMs = 1000,
  }) {
    if (_lastAccelPeakTime == null) return false;

    final int elapsed =
        DateTime.now().difference(_lastAccelPeakTime!).inMilliseconds;

    return elapsed <= withinMs && _lastAccelPeak >= threshold;
  }

  HeadGesture consumeGesture() {
    final HeadGesture gesture = lastGesture;
    lastGesture = HeadGesture.none;
    return gesture;
  }

  bool get isCursorLocked {
    if (_cursorLockedUntil == null) return false;
    return DateTime.now().isBefore(_cursorLockedUntil!);
  }

  void centerCursor({int lockMs = 0}) {
    cursorX = 0.5;
    cursorY = 0.5;

    lastStillX = cursorX;
    lastStillY = cursorY;

    filteredGY = 0.0;
    filteredGZ = 0.0;

    resetDwell();

    if (lockMs > 0) {
      _cursorLockedUntil =
          DateTime.now().add(Duration(milliseconds: lockMs));
    } else {
      _cursorLockedUntil = null;
    }

    _markUpdated();
  }

  void parsePacket(List<int> packet) {
    if (packet.length < 8) return;
    if (packet[0] != 123) return;

    final String type = String.fromCharCode(packet[1]);

    final byteData =
        Uint8List.fromList(packet.sublist(2)).buffer.asByteData();

    final int rawX = byteData.getInt16(0, Endian.little);
    final int rawY = byteData.getInt16(2, Endian.little);
    final int rawZ = byteData.getInt16(4, Endian.little);

    if (type == 'a') {
      final double accelZ = rawZ.toDouble();
      final double deltaAccelZ = (accelZ - _lastAccelZ).abs();

      _lastAccelZ = accelZ;

      if (deltaAccelZ > _lastAccelPeak) {
        _lastAccelPeak = deltaAccelZ;
        _lastAccelPeakTime = DateTime.now();
      }

      if (_lastAccelPeakTime != null &&
          DateTime.now().difference(_lastAccelPeakTime!).inMilliseconds >
              1000) {
        _lastAccelPeak = 0.0;
        _lastAccelPeakTime = null;
      }

      return;
    }

    if (type != 'g') return;

    final double gy = rawY * gyroSensitivity;
    final double gz = rawZ * gyroSensitivity;

    if (isCalibrating) {
      calibrationSumY += gy;
      calibrationSumZ += gz;
      calibrationSamples++;

      if (calibrationSamples >= calibrationRequiredSamples) {
        gyroOffsetY = calibrationSumY / calibrationSamples;
        gyroOffsetZ = calibrationSumZ / calibrationSamples;

        calibrationSumY = 0.0;
        calibrationSumZ = 0.0;
        calibrationSamples = 0;

        filteredGY = 0.0;
        filteredGZ = 0.0;

        cursorX = 0.5;
        cursorY = 0.5;

        lastStillX = cursorX;
        lastStillY = cursorY;

        isCalibrating = false;
        clickStatus = 'Calibrated';

        resetDwell();
        _markUpdated();

        Future.delayed(const Duration(milliseconds: 700), () {
          clickStatus = '';
          _markUpdated();
        });
      }

      return;
    }

    if (isCursorLocked) {
      cursorX = 0.5;
      cursorY = 0.5;
      lastStillX = cursorX;
      lastStillY = cursorY;
      resetDwell();
      _markUpdated();
      return;
    }

    final double correctedGY = gy - gyroOffsetY;
    final double correctedGZ = gz - gyroOffsetZ;

    filteredGY =
        filteredGY * smoothingX + correctedGY * (1.0 - smoothingX);

    filteredGZ =
        filteredGZ * smoothingY + correctedGZ * (1.0 - smoothingY);

    final double moveX = _applyDynamicGain(-filteredGZ, deadZoneX);
    final double moveY = _applyDynamicGain(-filteredGY, deadZoneY);

    cursorX += moveX * sensitivityX;
    cursorY += moveY * sensitivityY;

    cursorX = cursorX.clamp(0.0, 1.0);
    cursorY = cursorY.clamp(0.0, 1.0);

    _markUpdated();
  }

  double _applyDynamicGain(double value, double deadZone) {
    final double absValue = value.abs();

    if (absValue < deadZone) {
      return 0.0;
    }

    final double sign = value.sign;
    final double normalized = absValue - deadZone;

    const double accelerationFactor = 0.20;
    const double maxGain = 3.0;

    double gain = 1.0 + normalized * accelerationFactor;

    if (gain > maxGain) {
      gain = maxGain;
    }

    return sign * normalized * gain;
  }

  void updateDwell({
    required VoidCallback onDwellClick,
  }) {
    if (isCursorLocked) {
      resetDwell();
      _markUpdated();
      return;
    }

    final double dx = cursorX - lastStillX;
    final double dy = cursorY - lastStillY;

    final double distance = math.sqrt(dx * dx + dy * dy);

    if (distance < stillThreshold) {
      dwellStartTime ??= DateTime.now();

      final int elapsed =
          DateTime.now().difference(dwellStartTime!).inMilliseconds;

      if (elapsed < dwellDelayMs) {
        dwellProgress = 0.0;
        _markUpdated();
        return;
      }

      final int activeElapsed = elapsed - dwellDelayMs;

      dwellProgress = activeElapsed / dwellTimeMs;

      if (dwellProgress > 1.0) {
        dwellProgress = 1.0;
      }

      if (dwellProgress >= 1.0 && !dwellTriggered) {
        dwellTriggered = true;
        onDwellClick();
      }
    } else {
      lastStillX = cursorX;
      lastStillY = cursorY;
      resetDwell();
    }

    _markUpdated();
  }

  void calibrate() {
    calibrationSumY = 0.0;
    calibrationSumZ = 0.0;
    calibrationSamples = 0;

    filteredGY = 0.0;
    filteredGZ = 0.0;

    cursorX = 0.5;
    cursorY = 0.5;

    lastStillX = cursorX;
    lastStillY = cursorY;

    isCalibrating = true;
    clickStatus = 'Calibrating...';

    resetDwell();
    _markUpdated();
  }

  void resetDwell() {
    dwellStartTime = null;
    dwellProgress = 0.0;
    dwellTriggered = false;
  }

  bool isInsideWidget(BuildContext context, GlobalKey key) {
    final BuildContext? widgetContext = key.currentContext;

    if (widgetContext == null) {
      return false;
    }

    final RenderBox? box = widgetContext.findRenderObject() as RenderBox?;

    if (box == null || !box.hasSize) {
      return false;
    }

    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;
    final Size screenSize = MediaQuery.of(context).size;

    final double cursorPixelX = cursorX * screenSize.width;
    final double cursorPixelY = cursorY * screenSize.height;

    return cursorPixelX >= position.dx &&
        cursorPixelX <= position.dx + size.width &&
        cursorPixelY >= position.dy &&
        cursorPixelY <= position.dy + size.height;
  }

  void setClickStatus(String value, {int clearAfterMs = 600}) {
    clickStatus = value;
    _markUpdated();

    Future.delayed(Duration(milliseconds: clearAfterMs), () {
      clickStatus = '';
      _markUpdated();
    });
  }

  void _markUpdated() {
    hasNewData = true;
    notifyListeners();
  }
}