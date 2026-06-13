import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/utils/head_cursor_controller.dart';

import 'graphs_page.dart';
import 'target_test_page.dart';

class CursorPage extends StatefulWidget {
  const CursorPage({
    super.key,
    required this.title,
    required this.stream,
    required this.cursorController,
  });

  final String title;
  final MyStream stream;
  final HeadCursorController cursorController;

  @override
  State<CursorPage> createState() => _CursorPageState();
}

class _CursorPageState extends State<CursorPage> {
  Timer? _uiRefreshTimer;

  final GlobalKey _calibrateButtonKey = GlobalKey();
  final GlobalKey _graphsButtonKey = GlobalKey();
  final GlobalKey _targetTestButtonKey = GlobalKey();

  bool hoverCalibrate = false;
  bool hoverGraphs = false;
  bool hoverTarget = false;

  @override
  void initState() {
    super.initState();

    widget.cursorController.addListener(_onCursorUpdated);

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
    hoverGraphs = controller.isInsideWidget(context, _graphsButtonKey);
    hoverTarget = controller.isInsideWidget(context, _targetTestButtonKey);
  }

  void _handleDwellClick() {
    final controller = widget.cursorController;

    if (hoverCalibrate) {
      controller.calibrate();
      return;
    }

    if (hoverGraphs) {
      controller.resetDwell();
      _openGraphs();
      return;
    }

    if (hoverTarget) {
      controller.resetDwell();
      _openTargetTest();
      return;
    }

    controller.setClickStatus('Clicked');
  }

  void _openGraphs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GraphsPage(
          title: 'Sensor Graphs',
          stream: widget.stream,
          cursorController: widget.cursorController,
        ),
      ),
    );
  }

  void _openTargetTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TargetTestPage(
          title: 'Target Test',
          stream: widget.stream,
          cursorController: widget.cursorController,
        ),
      ),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double dotX = controller.cursorX * constraints.maxWidth;
          final double dotY = controller.cursorY * constraints.maxHeight;

          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.black12,
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                top: 50,
                left: 20,
                child: Text(
                  controller.clickStatus,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
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
                            key: _graphsButtonKey,
                            text: 'Graphs',
                            onPressed: _openGraphs,
                            hovered: hoverGraphs,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _buildHoverButton(
                        key: _targetTestButtonKey,
                        text: 'Target Test',
                        onPressed: _openTargetTest,
                        hovered: hoverTarget,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: dotX - 28,
                top: dotY - 28,
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