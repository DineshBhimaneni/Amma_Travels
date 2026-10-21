import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/bus.dart';

class RouteMapScreen extends StatefulWidget {
  final Bus bus;
  final String? boardingStop;
  final String? droppingStop;

  const RouteMapScreen({
    super.key,
    required this.bus,
    this.boardingStop,
    this.droppingStop,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  late List<RouteStop> _stops;

  @override
  void initState() {
    super.initState();
    if (widget.bus.stops.isNotEmpty) {
      _stops = widget.bus.stops;
    } else {
      // Fallback 2-stop route
      _stops = [
        RouteStop(
          id: 1,
          routeId: widget.bus.routeId,
          stopName: widget.bus.source,
          stopOrder: 1,
          departureTime: widget.bus.departureTime,
          fareFromSource: 0.0,
        ),
        RouteStop(
          id: 2,
          routeId: widget.bus.routeId,
          stopName: widget.bus.destination,
          stopOrder: 2,
          arrivalTime: widget.bus.arrivalTime,
          fareFromSource: widget.bus.fare,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandRed = Color(0xFF9E1A1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Map & Halts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.bus.source} ➔ ${widget.bus.destination}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: brandRed,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Map Header info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_bus, color: brandRed, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.bus.busName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '${_stops.length} Scheduled Stops',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Route Map Canvas Area
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFFEFF6FF),
              child: Stack(
                children: [
                  // Interactive Canvas for Pinch to zoom and pan
                  InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(80),
                    minScale: 0.6,
                    maxScale: 2.5,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1.2,
                        child: CustomPaint(
                          painter: RoutePathPainter(
                            stops: _stops,
                            boardingStop: widget.boardingStop ?? widget.bus.source,
                            droppingStop: widget.droppingStop ?? widget.bus.destination,
                          ),
                          child: Container(),
                        ),
                      ),
                    ),
                  ),

                  // Map Legend overlay
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendRow(Colors.green, 'Origin / Boarding'),
                          const SizedBox(height: 4),
                          _buildLegendRow(Colors.blue.shade700, 'Intermediate Halt'),
                          const SizedBox(height: 4),
                          _buildLegendRow(Colors.red.shade700, 'Dropping / Terminus'),
                        ],
                      ),
                    ),
                  ),

                  // Hint badge
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Pinch to zoom • Drag to pan',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Intermediate Stops List Timeline
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Route Stops Timeline',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'Total Fare: ₹${widget.bus.fare.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: brandRed, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _stops.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 64),
                      itemBuilder: (context, index) {
                        final stop = _stops[index];
                        final isBoarding = stop.stopName.toLowerCase() == (widget.boardingStop ?? '').toLowerCase();
                        final isDropping = stop.stopName.toLowerCase() == (widget.droppingStop ?? '').toLowerCase();
                        final isFirst = index == 0;
                        final isLast = index == _stops.length - 1;

                        Color nodeColor = Colors.blue;
                        if (isBoarding || isFirst) nodeColor = Colors.green;
                        if (isDropping || isLast) nodeColor = Colors.red;

                        return Container(
                          color: (isBoarding || isDropping) ? nodeColor.withOpacity(0.06) : null,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              // Order badge
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: nodeColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Stop Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          stop.stopName,
                                          style: TextStyle(
                                            fontWeight: (isBoarding || isDropping) ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (isBoarding) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Boarding',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                            ),
                                          ),
                                        ],
                                        if (isDropping) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Dropping',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Arr: ${stop.arrivalTime ?? "Start"} • Dep: ${stop.departureTime ?? "Terminus"}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Fare info
                              Text(
                                '₹${stop.fareFromSource.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

/// Custom painter that plots stops on a dynamic vector coordinate route map
class RoutePathPainter extends CustomPainter {
  final List<RouteStop> stops;
  final String boardingStop;
  final String droppingStop;

  RoutePathPainter({
    required this.stops,
    required this.boardingStop,
    required this.droppingStop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stops.isEmpty) return;

    // Draw coordinate grid pattern background
    final gridPaint = Paint()
      ..color = const Color(0xFFDBEAFE).withOpacity(0.5)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Determine geographic bounds or linear spacing
    final hasCoords = stops.every((s) => s.latitude != null && s.longitude != null);
    final List<Offset> points = [];

    const padding = 55.0;
    final drawWidth = size.width - (padding * 2);
    final drawHeight = size.height - (padding * 2);

    if (hasCoords && stops.length > 1) {
      double minLat = stops.first.latitude!;
      double maxLat = stops.first.latitude!;
      double minLng = stops.first.longitude!;
      double maxLng = stops.first.longitude!;

      for (final s in stops) {
        if (s.latitude! < minLat) minLat = s.latitude!;
        if (s.latitude! > maxLat) maxLat = s.latitude!;
        if (s.longitude! < minLng) minLng = s.longitude!;
        if (s.longitude! > maxLng) maxLng = s.longitude!;
      }

      final latSpan = (maxLat - minLat).abs();
      final lngSpan = (maxLng - minLng).abs();

      for (final s in stops) {
        final xNorm = lngSpan == 0 ? 0.5 : (s.longitude! - minLng) / lngSpan;
        // Invert latitude because canvas Y increases downwards
        final yNorm = latSpan == 0 ? 0.5 : (maxLat - s.latitude!) / latSpan;

        points.add(Offset(padding + (xNorm * drawWidth), padding + (yNorm * drawHeight)));
      }
    } else {
      // Linear layout with natural S-curve path
      for (int i = 0; i < stops.length; i++) {
        final fraction = i / (stops.length - 1);
        final x = padding + (fraction * drawWidth);
        // Slight wave for realism
        final y = (size.height / 2) + (math.sin(fraction * math.pi) * 35);
        points.add(Offset(x, y));
      }
    }

    // 1. Draw route polyline
    final routePaint = Paint()
      ..color = const Color(0xFF9E1A1A)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(path, routePaint);

    // 2. Draw route outer casing / glow
    final glowPaint = Paint()
      ..color = const Color(0xFF9E1A1A).withOpacity(0.2)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glowPaint);

    // 3. Draw pins and labels
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final stop = stops[i];
      final isFirst = i == 0;
      final isLast = i == points.length - 1;
      final isBoarding = stop.stopName.toLowerCase() == boardingStop.toLowerCase();
      final isDropping = stop.stopName.toLowerCase() == droppingStop.toLowerCase();

      Color pinColor = const Color(0xFF2563EB); // Royal Blue
      if (isBoarding || isFirst) pinColor = const Color(0xFF16A34A); // Green
      if (isDropping || isLast) pinColor = const Color(0xFFDC2626); // Red

      // Outer ripple for boarding / dropping
      if (isBoarding || isDropping || isFirst || isLast) {
        final ripplePaint = Paint()
          ..color = pinColor.withOpacity(0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(p, 16, ripplePaint);
      }

      // Marker Circle
      final pinPaint = Paint()
        ..color = pinColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 9, pinPaint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(p, 9, borderPaint);

      // Station Name Text Label
      final textSpan = TextSpan(
        text: stop.stopName,
        style: TextStyle(
          color: (isBoarding || isDropping || isFirst || isLast) ? Colors.black87 : const Color(0xFF334155),
          fontSize: 10,
          fontWeight: (isBoarding || isDropping || isFirst || isLast) ? FontWeight.bold : FontWeight.w600,
          backgroundColor: Colors.white.withOpacity(0.85),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Alternate label placement above and below to prevent collisions
      final labelY = (i % 2 == 0) ? p.dy - textPainter.height - 12 : p.dy + 12;
      final labelX = p.dx - (textPainter.width / 2);
      textPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant RoutePathPainter oldDelegate) {
    return oldDelegate.stops != stops ||
        oldDelegate.boardingStop != boardingStop ||
        oldDelegate.droppingStop != droppingStop;
  }
}
