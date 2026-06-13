import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/utils/head_cursor_controller.dart';

class TargetTestPage extends StatefulWidget {
  const TargetTestPage({
    super.key,
    required this.title,
    required this.stream,
    required this.cursorController,
  });

  final String title;
  final MyStream stream;
  final HeadCursorController cursorController;

  @override
  State<TargetTestPage> createState() => _TargetTestPageState();
}

class _TargetTestPageState extends State<TargetTestPage> {
  Timer? _uiRefreshTimer;

  final GlobalKey _calibrateButtonKey = GlobalKey();
  final GlobalKey _resetButtonKey = GlobalKey();
  final GlobalKey _backButtonKey = GlobalKey();

  final math.Random _random = math.Random();

  double targetX = 0.5;
  double targetY = 0.5;

  int score = 0;
  int attempts = 0;

  DateTime targetStartTime = DateTime.now();

  double averageHitTimeMs = 0.0;

  bool hoverCalibrate = false;
  bool hoverReset = false;
  bool hoverBack = false;

  @override
  void initState() {
    super.initState();

    widget.cursorController.addListener(_onCursorUpdated);

    _generateNewTarget();

    _uiRefreshTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (ModalRoute.of(context)?.isCurrent != true) {
        return;
      }

      _updateHoverStates();

      widget.cursorController.updateDwell(
        onDwellClick: _handleDwellClick,
      );
    });
  }

  void _onCursorUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  void _updateHoverStates() {
    final controller = widget.cursorController;

    hoverCalibrate = controller.isInsideWidget(context, _calibrateButtonKey);
    hoverReset = controller.isInsideWidget(context, _resetButtonKey);
    hoverBack = controller.isInsideWidget(context, _backButtonKey);
  }

  void _handleDwellClick() {
    final controller = widget.cursorController;

    if (hoverCalibrate) {
      controller.calibrate();
      return;
    }

    if (hoverReset) {
      _resetTest();
      return;
    }

    if (hoverBack) {
      controller.resetDwell();
      Navigator.pop(context);
      return;
    }

    attempts++;

    if (_isCursorInsideTarget()) {
      score++;

      final int hitTime =
          DateTime.now().difference(targetStartTime).inMilliseconds;

      if (score == 1) {
        averageHitTimeMs = hitTime.toDouble();
      } else {
        averageHitTimeMs =
            ((averageHitTimeMs * (score - 1)) + hitTime) / score;
      }

      controller.setClickStatus('Hit!');

      _generateNewTarget();
    } else {
      controller.setClickStatus('Miss!');
    }

    controller.resetDwell();

    if (mounted) {
      setState(() {});
    }
  }

  bool _isCursorInsideTarget() {
    final controller = widget.cursorController;

    final double dx = controller.cursorX - targetX;
    final double dy = controller.cursorY - targetY;

    final double distance = math.sqrt(dx * dx + dy * dy);

    return distance < 0.10;
  }

  void _generateNewTarget() {
    targetX = 0.12 + _random.nextDouble() * 0.76;
    targetY = 0.16 + _random.nextDouble() * 0.58;

    targetStartTime = DateTime.now();

    widget.cursorController.resetDwell();

    if (mounted) {
      setState(() {});
    }
  }

  void _resetTest() {
    final controller = widget.cursorController;

    score = 0;
    attempts = 0;
    averageHitTimeMs = 0.0;

    controller.setClickStatus('Reset');

    _generateNewTarget();

    controller.resetDwell();

    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildHoverButton({
    required GlobalKey key,
    required String text,
    required VoidCallback onPressed,
    required bool hovered,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: hovered
            ? [
                BoxShadow(
                  blurRadius: 20,
                  spreadRadius: 2,
                  color: Colors.orange.withValues(alpha: 0.6),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        key: key,
        style: ElevatedButton.styleFrom(
          backgroundColor: hovered ? Colors.orangeAccent : null,
          foregroundColor: hovered ? Colors.black : null,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }

  @override
  void dispose() {
    widget.cursorController.removeListener(_onCursorUpdated);
    _uiRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.cursorController;

    final String statusText =
        controller.isCalibrating ? 'Calibrating...' : 'Ready';

    final double accuracy =
        attempts == 0 ? 0.0 : (score / attempts) * 100.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double cursorPixelX =
              controller.cursorX * constraints.maxWidth;

          final double cursorPixelY =
              controller.cursorY * constraints.maxHeight;

          final double targetPixelX = targetX * constraints.maxWidth;
          final double targetPixelY = targetY * constraints.maxHeight;

          const double targetRadius = 36.0;

          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.black12,
                ),
              ),
              Positioned(
                left: targetPixelX - targetRadius,
                top: targetPixelY - targetRadius,
                child: Container(
                  width: targetRadius * 2,
                  height: targetRadius * 2,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.shade900,
                      width: 3,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      controller.clickStatus,
                      style: TextStyle(
                        fontSize: 18,
                        color: controller.clickStatus == 'Hit!' ||
                                controller.clickStatus == 'Calibrated'
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Score: $score'),
                      Text('Attempts: $attempts'),
                      Text('Accuracy: ${accuracy.toStringAsFixed(1)}%'),
                      Text(
                        'Avg time: ${(averageHitTimeMs / 1000.0).toStringAsFixed(2)} s',
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 30,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildHoverButton(
                            key: _calibrateButtonKey,
                            text: 'Calibrate',
                            onPressed: controller.calibrate,
                            hovered: hoverCalibrate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildHoverButton(
                            key: _resetButtonKey,
                            text: 'Reset Test',
                            onPressed: _resetTest,
                            hovered: hoverReset,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _buildHoverButton(
                        key: _backButtonKey,
                        text: 'Back',
                        onPressed: () {
                          controller.resetDwell();
                          Navigator.pop(context);
                        },
                        hovered: hoverBack,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: cursorPixelX - 28,
                top: cursorPixelY - 28,
                child: IgnorePointer(
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (controller.dwellProgress > 0.0)
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: CircularProgressIndicator(
                              value: controller.dwellProgress,
                              strokeWidth: 4,
                            ),
                          ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 12,
                                color: Colors.blue.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}