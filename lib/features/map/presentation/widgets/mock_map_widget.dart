import 'package:flutter/material.dart';
import 'package:mapcapture/data/models/marker_model.dart';

/// Mock map widget for testing without actual map SDK
///
/// This widget provides a visual placeholder that mimics map functionality.
/// In production, replace with actual amap_flutter_map widget.
class MockMapWidget extends StatefulWidget {
  final List<MarkerEntity> markers;
  final MarkerEntity? selectedMarker;
  final void Function(double lat, double lng) onMapTap;
  final void Function(MarkerEntity) onMarkerTap;

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
  // Mock map center (Beijing)
  double _centerLat = 39.9042;
  double _centerLng = 116.4074;
  double _zoom = 15.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        // Convert screen position to mock coordinates
        final tapLat = _centerLat + (details.localPosition.dy - 200) / 100000;
        final tapLng = _centerLng + (details.localPosition.dx - 200) / 100000;
        widget.onMapTap(tapLat, tapLng);
      },
      child: Container(
        color: Colors.grey.shade200,
        child: Stack(
          children: [
            // Map background (grid pattern)
            CustomPaint(
              size: Size.infinite,
              painter: _MapGridPainter(),
            ),

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
    return widget.markers.map((marker) {
      final isSelected = widget.selectedMarker?.id == marker.id;

      // Calculate mock screen position
      final dx = (marker.longitude - _centerLng) * 100000 + 200;
      final dy = (marker.latitude - _centerLat) * 100000 + 200;

      return Positioned(
        left: dx,
        top: dy,
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

/// Zoom button widget
class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
  });

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

/// Map grid painter for background
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    // Draw grid lines
    const gridSize = 50.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw some "roads"
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    // Horizontal road
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      roadPaint,
    );

    // Vertical road
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      roadPaint,
    );

    // Draw some "blocks"
    final blockPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    final blocks = [
      const Rect.fromLTWH(50, 50, 100, 80),
      const Rect.fromLTWH(200, 150, 120, 100),
      const Rect.fromLTWH(80, 250, 90, 70),
      const Rect.fromLTWH(250, 50, 80, 90),
    ];

    for (final block in blocks) {
      canvas.drawRect(block, blockPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
