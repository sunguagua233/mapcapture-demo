import 'package:flutter/material.dart';

import '../models/marker.dart';

class MockMapWidget extends StatefulWidget {
  final List<Marker> markers;
  final Marker? selectedMarker;
  final void Function(double lat, double lng) onMapTap;
  final void Function(Marker) onMarkerTap;

  const MockMapWidget({
    super.key,
    required this.markers,
    this.selectedMarker,
    required this.onMapTap,
    required this.onMarkerTap,
  });

  @override
  State<MockMapWidget> createState() => _MockMapWidgetState();
}

class _MockMapWidgetState extends State<MockMapWidget> {
  // Mock map center
  double _centerLat = 39.9042;
  double _centerLng = 116.4074;
  double _zoom = 15.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        // Convert screen position to mock coordinates
        final size = MediaQuery.of(context).size;
        final tapLat = _centerLat + (details.localPosition.dy - size.height / 2) / 10000;
        final tapLng = _centerLng + (details.localPosition.dx - size.width / 2) / 10000;
        widget.onMapTap(tapLat, tapLng);
      },
      child: Container(
        color: Colors.grey.shade100,
        child: Stack(
          children: [
            // Map background
            const _MapBackground(),

            // Map center indicator
            Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Markers
            ..._buildMarkerWidgets(),

            // Zoom controls
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ZoomButton(
                    icon: Icons.add,
                    onTap: () {
                      setState(() {
                        _zoom = (_zoom + 1).clamp(3.0, 18.0);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  _ZoomButton(
                    icon: Icons.remove,
                    onTap: () {
                      setState(() {
                        _zoom = (_zoom - 1).clamp(3.0, 18.0);
                      });
                    },
                  ),
                ],
              ),
            ),

            // Info overlay
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '缩放: ${_zoom.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '中心: ${_centerLat.toStringAsFixed(4)}, ${_centerLng.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),

            // Watermark
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '模拟地图',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMarkerWidgets() {
    final size = MediaQuery.of(context).size;

    return widget.markers.map((marker) {
      final isSelected = widget.selectedMarker?.id == marker.id;

      // Calculate mock screen position
      final dx = (marker.longitude - _centerLng) * 10000 + size.width / 2;
      final dy = (marker.latitude - _centerLat) * 10000 + size.height / 2;

      return Positioned(
        left: dx - 20,
        top: dy - 40,
        child: GestureDetector(
          onTap: () => widget.onMarkerTap(marker),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Marker icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: isSelected ? 32 : 24,
                ),
              ),
              // Marker label
              if (isSelected || widget.markers.length < 10)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    marker.title,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }
}

class _MapBackground extends StatelessWidget {
  const _MapBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _MapPainter(),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()..color = Colors.grey.shade200;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    const gridSize = 50.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Roads
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    // Main roads
    final roads = [
      [Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5)],
      [Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height)],
      [Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height)],
      [Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3)],
      [Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7)],
    ];

    for (final road in roads) {
      canvas.drawLine(road[0], road[1], roadPaint);
    }

    // Blocks
    final blockPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    final blocks = [
      Rect.fromLTWH(size.width * 0.35, size.height * 0.35, 80, 60),
      Rect.fromLTWH(size.width * 0.5, size.height * 0.55, 100, 70),
      Rect.fromLTWH(size.width * 0.15, size.height * 0.15, 70, 80),
      Rect.fromLTWH(size.width * 0.75, size.height * 0.2, 90, 60),
    ];

    for (final block in blocks) {
      canvas.drawRect(block, blockPaint);
    }

    // Parks
    final parkPaint = Paint()
      ..color = Colors.green.shade300
      ..style = PaintingStyle.fill;

    final parks = [
      Rect.fromCircle(center: Offset(size.width * 0.2, size.height * 0.6), radius: 40),
      Rect.fromCircle(center: Offset(size.width * 0.8, size.height * 0.4), radius: 50),
    ];

    for (final park in parks) {
      canvas.drawOval(park, parkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
