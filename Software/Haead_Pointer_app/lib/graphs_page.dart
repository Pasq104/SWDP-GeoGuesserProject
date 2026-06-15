import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/utils/head_cursor_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smart_wearables_app/utils/sensor_utils.dart';

class GraphsPage extends StatefulWidget {
  const GraphsPage({
    super.key,
    required this.title,
    required this.stream,
    required this.cursorController,
  });

  final String title;
  final MyStream stream;
  final HeadCursorController cursorController;

  @override
  State<GraphsPage> createState() => _GraphsPageState();
}

class ChartData {
  ChartData(this.x, this.y);
  final int x;
  final double y;
}

class SensorDataSet {
  final List<ChartData> x = [];
  final List<ChartData> y = [];
  final List<ChartData> z = [];

  double filteredX = 0.0;
  double filteredY = 0.0;
  double filteredZ = 0.0;

  bool initialized = false;
}

class _GraphsPageState extends State<GraphsPage> {
  late StreamSubscription _dataSubscription;
  Timer? _uiRefreshTimer;

  final ScrollController _scrollController = ScrollController();

  final Map<String, SensorDataSet> sensorData = {};
  final List<String> sensorTypes = ['a', 'g', 'M'];

  final int maxDataPoints = 100;
  int xCounter = 0;

  bool _hasNewGraphData = false;

  final double filterAlpha = 0.85;

  final double edgeZone = 0.10;
  final double scrollSpeed = 5.0;

  double _getSensitivity(String type) {
    switch (type) {
      case 'a':
        return 2.0 / 32767.0;
      case 'g':
        return 250.0 / 32767.0;
      case 'M':
        return 1.5;
      default:
        return 1.0;
    }
  }

  @override
  void initState() {
    super.initState();

    for (final type in sensorTypes) {
      sensorData[type] = SensorDataSet();
    }

    widget.cursorController.addListener(_onCursorUpdated);

    _dataSubscription = widget.stream.controller.stream.listen((packet) {
      _parseGraphPacket(packet);
    });

    _uiRefreshTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _handleEdgeScrolling();

      if ((_hasNewGraphData || widget.cursorController.hasNewData) && mounted) {
        setState(() {});
        _hasNewGraphData = false;
        widget.cursorController.hasNewData = false;
      }
    });
  }

  void _onCursorUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  void _parseGraphPacket(List<int> packet) {
    if (packet.length < 8) return;

    final String type = String.fromCharCode(packet[1]);

    if (!sensorTypes.contains(type)) return;

    final byteData = Uint8List.fromList(packet.sublist(2)).buffer.asByteData();

    final int rawX = byteData.getInt16(0, Endian.little);
    final int rawY = byteData.getInt16(2, Endian.little);
    final int rawZ = byteData.getInt16(4, Endian.little);

    final double sensitivity = _getSensitivity(type);

    final double valueX = rawX * sensitivity;
    final double valueY = rawY * sensitivity;
    final double valueZ = rawZ * sensitivity;

    final dataSet = sensorData[type]!;

    if (!dataSet.initialized) {
      dataSet.filteredX = valueX;
      dataSet.filteredY = valueY;
      dataSet.filteredZ = valueZ;
      dataSet.initialized = true;
    } else {
      dataSet.filteredX =
          dataSet.filteredX * filterAlpha + valueX * (1.0 - filterAlpha);
      dataSet.filteredY =
          dataSet.filteredY * filterAlpha + valueY * (1.0 - filterAlpha);
      dataSet.filteredZ =
          dataSet.filteredZ * filterAlpha + valueZ * (1.0 - filterAlpha);
    }

    dataSet.x.add(ChartData(xCounter, dataSet.filteredX));
    dataSet.y.add(ChartData(xCounter, dataSet.filteredY));
    dataSet.z.add(ChartData(xCounter, dataSet.filteredZ));

    xCounter++;

    while (dataSet.x.length > maxDataPoints) {
      dataSet.x.removeAt(0);
      dataSet.y.removeAt(0);
      dataSet.z.removeAt(0);
    }

    _hasNewGraphData = true;
  }

  void _handleEdgeScrolling() {
    if (!_scrollController.hasClients) return;

    final controller = widget.cursorController;

    double delta = 0.0;

    if (controller.cursorY < edgeZone) {
      final double intensity = (edgeZone - controller.cursorY) / edgeZone;
      delta = -scrollSpeed * intensity;
    } else if (controller.cursorY > 1.0 - edgeZone) {
      final double intensity =
          (controller.cursorY - (1.0 - edgeZone)) / edgeZone;
      delta = scrollSpeed * intensity;
    }

    if (delta == 0.0) return;

    final double newOffset = (_scrollController.offset + delta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.jumpTo(newOffset);
  }

  @override
  void dispose() {
    widget.cursorController.removeListener(_onCursorUpdated);
    _dataSubscription.cancel();
    _uiRefreshTimer?.cancel();
    _scrollController.dispose();
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
              ListView(
                controller: _scrollController,
                children: [
                  const SizedBox(height: 10),
                  for (final type in sensorTypes) _buildSensorSection(type),
                  const SizedBox(height: 120),
                ],
              ),

              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Graphs cursor: $statusText\nEdge scroll enabled',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Positioned(
                right: 16,
                bottom: 24,
                child: ElevatedButton(
                  onPressed: controller.calibrate,
                  child: const Text('Calibrate'),
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

  Widget _buildSensorSection(String type) {
    final dataSet = sensorData[type]!;

    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              getSensorNameFromType(type),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildChart(type, "X-Axis", dataSet.x, Colors.red),
            _buildChart(type, "Y-Axis", dataSet.y, Colors.green),
            _buildChart(type, "Z-Axis", dataSet.z, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    String type,
    String title,
    List<ChartData> data,
    Color color,
  ) {
    double minY;
    double maxY;

    switch (type) {
      case 'a':
        minY = -2.0;
        maxY = 2.0;
        break;
      case 'g':
        minY = -250.0;
        maxY = 250.0;
        break;
      case 'M':
        minY = -1000.0;
        maxY = 1000.0;
        break;
      default:
        minY = -1.0;
        maxY = 1.0;
    }

    return SizedBox(
      height: 180,
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: NumericAxis(
                isVisible: false,
              ),
              primaryYAxis: NumericAxis(
                minimum: minY,
                maximum: maxY,
                labelFormat: '{value}',
              ),
              series: <LineSeries<ChartData, int>>[
                LineSeries<ChartData, int>(
                  dataSource: List<ChartData>.from(data),
                  xValueMapper: (ChartData d, _) => d.x,
                  yValueMapper: (ChartData d, _) => d.y,
                  color: color,
                  animationDuration: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}