import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_list_viewport/page_list_viewport.dart';
import 'dart:math' as math;

class FrameTimePlotter extends StatefulWidget {
  const FrameTimePlotter({super.key, required this.controller});
  final PageListViewportController controller;

  @override
  State<FrameTimePlotter> createState() => _FrameTimePlotterState();
}

class _FrameTimePlotterState extends State<FrameTimePlotter> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant FrameTimePlotter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_onControllerChanged);
  }

  List<double> _timeDeltas = [];
  final _stopwatch = Stopwatch();

  int? _lastElapsedMicrosecond;

  void _onControllerChanged() {
    if (_stopwatch.isRunning == false) {
      _stopwatch.start();
    }
    if (_lastElapsedMicrosecond != null) {
      final delta = (_stopwatch.elapsedMicroseconds - _lastElapsedMicrosecond!) / 1000000;
      print((delta * 10000).roundToDouble() / 10000);
      _timeDeltas.add(delta);
    }
    _lastElapsedMicrosecond = _stopwatch.elapsedMicroseconds;
    setState(() {});
  }

  void _onClear() {
    setState(() {
      _timeDeltas = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onClear,
      onTap: () {
        _timeDeltas.forEach((p) => print);
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PlotterPainter(
                points: _timeDeltas,
                color: Colors.black,
                paintZeroLine: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlotterPainter extends CustomPainter {
  _PlotterPainter({
    required this.points,
    required this.color,
    required this.paintZeroLine,
  });
  final Iterable<double> points;
  final Color color;
  final bool paintZeroLine;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    final largestPoint = points.skip(1).fold(points.first, math.max);
    final smallestPoint = points.skip(1).fold(points.first, math.min);
    final averagePoint = points.fold(0.0, (sum, p) => sum + p) / points.length;
    final max =
        (largestPoint - averagePoint).abs() > (smallestPoint - averagePoint).abs() ? largestPoint : smallestPoint;
    final scaleX = size.width / 300;
    final scaleY = size.height / (max * 2);

    final pointPainter = Paint()..color = color;

    var timestep = 0;
    for (var point in points) {
      final plotPoint = Offset(timestep * scaleX, size.height - ((point + max) * scaleY));
      canvas.drawCircle(plotPoint, 1, pointPainter);
      if ((point - averagePoint).abs() / averagePoint > 1) {
        canvas.drawLine(
          Offset(timestep * scaleX, 0),
          Offset(timestep * scaleX, size.height),
          Paint()..color = Colors.orange,
        );
      }
      timestep += 1;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
