import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_list_viewport/page_list_viewport.dart';

class VelocityPlotter extends StatefulWidget {
  const VelocityPlotter({super.key, required this.controller, required this.max});
  final PageListViewportController controller;
  final Offset max;

  @override
  State<VelocityPlotter> createState() => _VelocityPlotterState();
}

class _VelocityPlotterState extends State<VelocityPlotter> {
  List<Offset> _instantaneousVelocities = [];
  List<Offset> _instantaneousAcceleration = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant VelocityPlotter oldWidget) {
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

  Offset? _lastVelocity;
  final _stopwatch = Stopwatch();

  void _onControllerChanged() {
    if (_stopwatch.isRunning == false) {
      _stopwatch.start();
    }
    final velocity = widget.controller.velocity;
    _instantaneousVelocities.add(velocity);
    if (_lastVelocity != null) {
      _instantaneousAcceleration.add((velocity - _lastVelocity!) / (_stopwatch.elapsedMilliseconds / 1000));
    }
    _lastVelocity = velocity;
    _stopwatch.reset();
    setState(() {});
  }

  void _onClear() {
    setState(() {
      _instantaneousVelocities = [];
      _instantaneousAcceleration = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onClear,
      onTap: () {
        _instantaneousVelocities.forEach((p) => print("${p.dx},${p.dy}"));
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PlotterPainter(
                points: _instantaneousVelocities,
                max: widget.max,
                color: Colors.black,
                paintZeroLine: true,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _PlotterPainter(
                points: _instantaneousAcceleration,
                max: widget.max,
                color: Colors.red,
                paintZeroLine: false,
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
    required this.max,
    required this.points,
    required this.color,
    required this.paintZeroLine,
  });
  final Offset max;
  final Iterable<Offset> points;
  final Color color;
  final bool paintZeroLine;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 300;
    final scaleY = size.height / (max.dy * 2);

    final pointPainter = Paint()..color = color;

    var timestep = 0;
    for (var point in points) {
      final plotPoint = Offset(timestep * scaleX, size.height - ((point.dy + max.dy) * scaleY));
      canvas.drawCircle(plotPoint, 1, pointPainter);
      if (paintZeroLine && point == Offset.zero) {
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
