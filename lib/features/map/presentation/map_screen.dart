import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/map_controller.dart';
import 'widgets/marker_form.dart';
import 'widgets/mock_map_widget.dart';

/// Map screen - main map view with marker management
class MapScreen extends ConsumerStatefulWidget {
  final int tripId;
  final String tripName;

  const MapScreen({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  @override
  void initState() {
    super.initState();
    // Load markers when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapControllerProvider.notifier).loadMarkers(widget.tripId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapControllerProvider);
    final mapController = ref.read(mapControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tripName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // View switch button (placeholder)
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () {
              // TODO: Switch to list view
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('切换到列表视图（待实现）')),
              );
            },
          ),
          // More options
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  _showClearAllDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('清空所有标记'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map widget
          MockMapWidget(
            markers: mapState.markers,
            selectedMarker: mapState.selectedMarker,
            onMapTap: _handleMapTap,
            onMarkerTap: (marker) {
              mapController.selectMarker(marker);
            },
          ),

          // Loading indicator
          if (mapState.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Error message
          if (mapState.error != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          mapState.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          mapController.clearError();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Marker count indicator
          Positioned(
            top: 16,
            right: 16,
            child: Material(
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
                      '${mapState.markers.length} 个标记',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Selected marker info card
          if (mapState.selectedMarker != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _MarkerInfoCard(
                marker: mapState.selectedMarker!,
                onClose: () => mapController.selectMarker(null),
                onEdit: () => _showMarkerForm(mapState.selectedMarker!),
                onDelete: () => _deleteMarker(mapState.selectedMarker!.id!),
              ),
            ),

          // Add marker hint
          if (mapState.markers.isEmpty && !mapState.isLoading)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Center(
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      '点击地图添加标记',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Center the map (mock functionality)
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
    ref.read(mapControllerProvider.notifier).addMarker(
          widget.tripId,
          latitude,
          longitude,
        );
  }

  void _showMarkerForm(marker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MarkerForm(
        marker: marker,
        onSave: (updatedMarker) async {
          final success = await ref
              .read(mapControllerProvider.notifier)
              .updateMarker(updatedMarker);
          if (success && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('标记已更新')),
            );
          }
        },
      ),
    );
  }

  void _deleteMarker(int markerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个标记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(mapControllerProvider.notifier)
          .deleteMarker(markerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '标记已删除' : '删除失败'),
          ),
        );
      }
    }
  }

  void _showClearAllDialog() {
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
              Navigator.pop(context);
              // TODO: Implement clear all
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('清空功能（待实现）')),
              );
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}

/// Marker info card widget
class _MarkerInfoCard extends StatelessWidget {
  final marker;
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
                    LocationService.formatCoordinates(
                        marker.latitude, marker.longitude),
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
