import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../data/models/models.dart';
import '../providers/providers.dart';

enum ViewMode { cards, grid }

class RoutePlanScreen extends StatefulWidget {
  final String tripId;

  const RoutePlanScreen({super.key, required this.tripId});

  @override
  State<RoutePlanScreen> createState() => _RoutePlanScreenState();
}

class _RoutePlanScreenState extends State<RoutePlanScreen> {
  ViewMode _viewMode = ViewMode.cards;
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Plan'),
        actions: [
          IconButton(
            icon: Icon(_viewMode == ViewMode.cards ? Icons.grid_view : Icons.view_list),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == ViewMode.cards ? ViewMode.grid : ViewMode.cards;
              });
            },
          ),
          IconButton(
            icon: Icon(_isReordering ? Icons.check : Icons.reorder),
            onPressed: () {
              setState(() => _isReordering = !_isReordering);
            },
          ),
        ],
      ),
      body: Consumer<MarkerProvider>(
        builder: (context, provider, child) {
          final markers = provider.markers;

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!provider.hasMarkers) {
            return _buildEmptyState();
          }

          return _viewMode == ViewMode.cards
              ? _buildCardsView(markers, provider)
              : _buildGridView(markers, provider);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No markers yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add markers to the map to create a route',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsView(List<Marker> markers, MarkerProvider provider) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }

        final item = markers.removeAt(oldIndex);
        markers.insert(newIndex, item);

        final markerIds = markers.map((m) => m.id).toList();
        await provider.reorderMarkers(widget.tripId, markerIds);
      },
      itemCount: markers.length,
      itemBuilder: (context, index) {
        final marker = markers[index];
        return _buildMarkerCard(marker, index);
      },
    );
  }

  Widget _buildGridView(List<Marker> markers, MarkerProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: markers.length,
      itemBuilder: (context, index) {
        final marker = markers[index];
        return _buildMarkerGridItem(marker, index, provider);
      },
    );
  }

  Widget _buildMarkerCard(Marker marker, int index) {
    return Card(
      key: ValueKey(marker.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _parseColor(marker.color),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(marker.title),
        subtitle: Text(marker.address),
        trailing: marker.images.isNotEmpty
            ? Badge(
                label: Text('${marker.images.length}'),
                child: const Icon(Icons.photo_library),
              )
            : const Icon(Icons.photo_library_outlined),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarkerDetailScreen(
                markerId: marker.id,
                tripId: widget.tripId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMarkerGridItem(Marker marker, int index, MarkerProvider provider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarkerDetailScreen(
              markerId: marker.id,
              tripId: widget.tripId,
            ),
          ),
        );
      },
      child: Card(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (marker.images.isNotEmpty)
              Positioned.fill(
                child: Image.file(
                  File(marker.images.first.filePath),
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(color: Colors.grey[300]),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: CircleAvatar(
                backgroundColor: _parseColor(marker.color),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                marker.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.startsWith('#')) {
      buffer.write(hex.replaceFirst('#', '0xff'));
    } else {
      buffer.write('0xff$hex');
    }
    return Color(int.parse(buffer.toString()));
  }
}

// Import MarkerDetailScreen and fix the class name issue
import 'dart:io';
import 'marker_detail_screen.dart';
