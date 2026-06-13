import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/cursor_page.dart';
import 'package:smart_wearables_app/graphs_page.dart';
import 'package:smart_wearables_app/target_test_page.dart';
import 'package:smart_wearables_app/utils/head_cursor_controller.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    required this.stream,
    required this.cursorController,
  });

  final MyStream stream;
  final HeadCursorController cursorController;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  late final PageController _pageController;
  Timer? _gestureTimer;

  static const int _initialVirtualPage = 3000;

  int _virtualPageIndex = _initialVirtualPage;
  bool _isChangingPage = false;

  DateTime _ignoreGesturesUntil = DateTime.fromMillisecondsSinceEpoch(0);

  double _lastCursorX = 0.5;
  DateTime _lastCursorSampleTime = DateTime.now();

  double _swipeStartX = 0.5;
  DateTime? _swipeStartTime;

  static const double _minSwipeDistance = 0.45;
  static const double _minSwipeSpeed = 0.9;
  static const int _maxSwipeMs = 900;
  static const double _accelConfirmThreshold = 1800;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: _initialVirtualPage);

    _gestureTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _handleCursorSwipeNavigation(),
    );
  }

  void _handleCursorSwipeNavigation() {
    if (_isChangingPage || DateTime.now().isBefore(_ignoreGesturesUntil)) {
      _resetSwipeTracking();
      return;
    }

    final DateTime now = DateTime.now();
    final double currentX = widget.cursorController.cursorX;

    final int dtMs = now.difference(_lastCursorSampleTime).inMilliseconds;
    if (dtMs <= 0) return;

    final double dx = currentX - _lastCursorX;
    final double speed = dx.abs() / (dtMs / 1000.0);

    _lastCursorX = currentX;
    _lastCursorSampleTime = now;

    if (speed < _minSwipeSpeed) {
      return;
    }

    _swipeStartTime ??= now;
    _swipeStartX = _swipeStartTime == now ? currentX : _swipeStartX;

    final int swipeElapsed =
        now.difference(_swipeStartTime!).inMilliseconds;

    if (swipeElapsed > _maxSwipeMs) {
      _resetSwipeTracking();
      return;
    }

    final double totalDx = currentX - _swipeStartX;

    if (totalDx.abs() < _minSwipeDistance) {
      return;
    }

    final bool accelConfirmed = widget.cursorController.hasRecentAccelShake(
      threshold: _accelConfirmThreshold,
      withinMs: 1000,
    );

    if (!accelConfirmed) {
      _resetSwipeTracking();
      return;
    }

    if (totalDx < 0) {
      // Cursore da destra verso sinistra -> pagina successiva
      _goNext();
    } else {
      // Cursore da sinistra verso destra -> pagina precedente
      _goPrevious();
    }

    _resetSwipeTracking();
  }

  void _resetSwipeTracking() {
    _swipeStartTime = null;
    _swipeStartX = widget.cursorController.cursorX;
    _lastCursorX = widget.cursorController.cursorX;
    _lastCursorSampleTime = DateTime.now();
  }

  void _goNext() {
    _changePage(_virtualPageIndex + 1);
  }

  void _goPrevious() {
    _changePage(_virtualPageIndex - 1);
  }

  void _changePage(int targetVirtualPage) {
    if (_isChangingPage) return;

    _isChangingPage = true;

    _ignoreGesturesUntil = DateTime.now().add(
      const Duration(milliseconds: 1300),
    );

    _virtualPageIndex = targetVirtualPage;

    widget.cursorController.centerCursor(lockMs: 500);

    _pageController
        .animateToPage(
      _virtualPageIndex,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    )
        .whenComplete(() {
      Future.delayed(const Duration(milliseconds: 850), () {
        if (!mounted) return;
        _resetSwipeTracking();
        _isChangingPage = false;
      });
    });
  }

  Widget _buildPage(int virtualIndex) {
    final int pageIndex = virtualIndex % 3;

    if (pageIndex == 0) {
      return CursorPage(
        title: "Cursor Control",
        stream: widget.stream,
        cursorController: widget.cursorController,
      );
    }

    if (pageIndex == 1) {
      return GraphsPage(
        title: "Graphs",
        stream: widget.stream,
        cursorController: widget.cursorController,
      );
    }

    return TargetTestPage(
      title: "Target Test",
      stream: widget.stream,
      cursorController: widget.cursorController,
    );
  }

  @override
  void dispose() {
    _gestureTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildPage(index);
      },
    );
  }
}