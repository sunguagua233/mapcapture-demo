import 'package:flutter/material.dart';

import '../models/marker.dart';
import '../models/trip.dart';
import '../services/data_service.dart';
import '../widgets/marker_form.dart';
import '../widgets/mock_map_widget.dart';

class MapScreen extends StatefulWidget {
  final Trip trip;

  const MapScreen({super.key, required this.trip});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final DataService _dataService = DataService();
  List<Marker> _markers = [];
  Marker? _selectedMarker;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _markers = _dataService.getMarkersByTripId(widget.trip.id);
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // View toggle
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () {
              _showListView();
            },
            tooltip: '列表视图',
          ),
          // More options
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_markers':
                  _showClearMarkersDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_markers',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 12),
                    Text('清空标记'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map widget
          MockMapWidget(
            markers: _markers,
            selectedMarker: _selectedMarker,
            onMapTap: _handleMapTap,
            onMarkerTap: _handleMarkerTap,
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Marker count indicator
          if (!_isLoading)
            Positioned(
              top: 16,
              right: 16,
              child: _MarkerCountIndicator(count: _markers.length),
            ),

          // Selected marker info card
          if (_selectedMarker != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _MarkerInfoCard(
                marker: _selectedMarker!,
                onClose: () => setState(() => _selectedMarker = null),
                onEdit: () => _showMarkerForm(_selectedMarker!),
                onDelete: () => _deleteMarker(_selectedMarker!),
              ),
            ),

          // Empty hint
          if (_markers.isEmpty && !_isLoading)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: const Center(
                child: _AddMarkerHint(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('地图已居中')),
          );
        },
        icon: const Icon(Icons.my_location),
        label: const Text('定位'),
      ),
    );
  }

  void _handleMapTap(double latitude, double longitude) {
    setState(() {
      _isLoading = true;
    });

    // Simulate geocoding delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final marker = _dataService.createMarker(
        tripId: widget.trip.id,
        title: '位置 ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
        address: '纬度: ${latitude.toStringAsFixed(4)}, 经度: ${longitude.toStringAsFixed(4)}',
        latitude: latitude,
        longitude: longitude,
      );

      setState(() {
        _markers = _dataService.getMarkersByTripId(widget.trip.id);
        _selectedMarker = marker;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('标记已添加')),
        );
      }
    });
  }

  void _handleMarkerTap(Marker marker) {
    setState(() {
      _selectedMarker = marker;
    });
  }

  void _showMarkerForm(Marker marker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MarkerForm(
        marker: marker,
        onSave: (updatedMarker) {
          _dataService.updateMarker(
            marker.id,
            title: updatedMarker.title,
            address: updatedMarker.address,
            notes: updatedMarker.notes,
            link: updatedMarker.link,
          );
          _loadMarkers();
          setState(() {
            _selectedMarker = updatedMarker;
          });
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('标记已更新')),
            );
          }
        },
      ),
    );
  }

  void _deleteMarker(Marker marker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${marker.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _dataService.deleteMarker(marker.id);
              Navigator.pop(context);
              _loadMarkers();
              setState(() {
                _selectedMarker = null;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('标记已删除')),
                );
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showListView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      builder: (context) => _MarkerListView(
        markers: _markers,
        onMarkerTap: (marker) {
          Navigator.pop(context);
          setState(() {
            _selectedMarker = marker;
          });
        },
      ),
    );
  }

  void _showClearMarkersDialog() {
    if (_markers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无标记可清空')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有标记'),
        content: const Text('确定要清空所有标记吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // Delete all markers for this trip
              for (final marker in _markers) {
                _dataService.deleteMarker(marker.id);
              }
              Navigator.pop(context);
              _loadMarkers();
              setState(() {
                _selectedMarker = null;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('所有标记已清空')),
                );
              }
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}

class _MarkerCountIndicator extends StatelessWidget {
  final int count;

  const _MarkerCountIndicator({required this.count});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              '$count 个标记',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkerInfoCard extends StatelessWidget {
  final Marker marker;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MarkerInfoCard({
    required this.marker,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      marker.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    marker.address,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    marker.coordinateString,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                  if (marker.notes != null && marker.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      marker.notes!,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (marker.link != null && marker.link!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.link, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            marker.link!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (marker.imagePaths.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${marker.imagePaths.length} 张图片',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('编辑'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('删除',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMarkerHint extends StatelessWidget {
  const _AddMarkerHint();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, color: Colors.white),
            SizedBox(width: 8),
            Text(
              '点击地图添加标记',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkerListView extends StatelessWidget {
  final List<Marker> markers;
  final Function(Marker) onMarkerTap;

  const _MarkerListView({
    required this.markers,
    required this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (markers.isEmpty) {
      return DraggableScrollableSheet(
        maxChildSize: 0.5,
        initialChildSize: 0.3,
        minChildSize: 0.2,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const Center(
            child: Text('暂无标记'),
          ),
        ),
      );
    }

    return DraggableScrollableSheet(
      maxChildSize: 0.8,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '标记列表',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${markers.length} 个',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: markers.length,
                itemBuilder: (context, index) {
                  final marker = markers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.location_on),
                      ),
                      title: Text(marker.title),
                      subtitle: Text(marker.address),
                      trailing:
                          Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                      onTap: () => onMarkerTap(marker),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
