import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/providers.dart';
import '../services/geocoding_service.dart';
import '../widgets/marker_form.dart';
import 'marker_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final String tripId;

  const MapScreen({super.key, required this.tripId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GeocodingService _geocodingService = GeocodingService();
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    final tripProvider = context.read<TripProvider>();
    final trip = await tripProvider.getTripById(widget.tripId);
    if (trip != null) {
      tripProvider.setCurrentTrip(trip);
    }

    context.read<MarkerProvider>().loadMarkers(widget.tripId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng position) async {
    // Show dialog to add marker at this location
    final address = await _geocodingService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (mounted) {
      _showAddMarkerDialog(position, address?.address ?? 'Unknown location');
    }
  }

  void _showAddMarkerDialog(LatLng position, String address) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MarkerForm(
        tripId: widget.tripId,
        initialLatitude: position.latitude,
        initialLongitude: position.longitude,
        initialAddress: address,
      ),
    ).then((_) {
      context.read<MarkerProvider>().loadMarkers(widget.tripId);
    });
  }

  void _onMarkerTap(MarkerData marker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkerDetailScreen(
          markerId: marker.id,
          tripId: widget.tripId,
        ),
      ),
    );
  }

  Future<void> _onSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Use search service to find location
    final coords = await _geocodingService.getCoordinatesFromAddress(query);

    if (coords != null) {
      context.read<MapProvider>().animateCamera(coords, zoom: 15.0);
      setState(() => _showSearchBar = false);
      _searchController.clear();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<TripProvider>(
          builder: (context, provider, child) {
            final trip = provider.currentTrip;
            return Text(trip?.name ?? 'Map');
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _showSearchBar = !_showSearchBar);
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              // Open route plan screen
            },
          ),
          PopupMenuButton<MapType>(
            onSelected: (type) {
              context.read<MapProvider>().setMapType(type);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: MapType.normal,
                child: Text('Standard'),
              ),
              const PopupMenuItem(
                value: MapType.satellite,
                child: Text('Satellite'),
              ),
              const PopupMenuItem(
                value: MapType.night,
                child: Text('Night'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMap(),
          if (_showSearchBar) _buildSearchBar(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            onPressed: () {
              final provider = context.read<MapProvider>();
              provider.setZoomLevel(provider.zoomLevel + 1);
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoom_out',
            mini: true,
            onPressed: () {
              final provider = context.read<MapProvider>();
              provider.setZoomLevel((provider.zoomLevel - 1).clamp(3.0, 20.0));
            },
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'my_location',
            onPressed: () {
              context.read<MapProvider>().moveToCurrentLocation();
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer2<MarkerProvider, MapProvider>(
      builder: (context, markerProvider, mapProvider, child) {
        final markers = markerProvider.markers;

        return AMapWidget(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              AppConstants.defaultLatitude,
              AppConstants.defaultLongitude,
            ),
            zoom: AppConstants.defaultZoom,
          ),
          onMapCreated: (controller) {
            mapProvider.setMapController(controller);
            // Fit bounds if there are markers
            if (markers.isNotEmpty) {
              final positions = markers
                  .map((m) => LatLng(m.latitude, m.longitude))
                  .toList();
              mapProvider.fitBounds(positions);
            }
          },
          onCameraMove: (position) {
            mapProvider._cameraPosition = position.target;
            mapProvider._zoomLevel = position.zoom;
          },
          onTap: _onMapTap,
          mapType: mapProvider.mapType,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          scaleControlsEnabled: true,
          markers: markers.map((marker) {
            return Marker(
              markerId: MarkerId(marker.id),
              position: LatLng(marker.latitude, marker.longitude),
              infoWindow: InfoWindow(
                title: marker.title,
                snippet: marker.address,
                onTap: () => _onMarkerTap(marker),
              ),
              icon: _createMarkerIcon(marker.color),
            );
          }).toSet(),
          polylines: mapProvider.showRoute && markers.length > 1
              ? {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    color: AppTheme.primaryColor,
                    width: 4,
                    points: markers
                        .map((m) => LatLng(m.latitude, m.longitude))
                        .toList(),
                  ),
                }
              : {},
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search location...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _onSearch,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BitmapDescriptor _createMarkerIcon(String color) {
    // In a real implementation, you'd create a custom marker
    // For now, use default
    return BitmapDescriptor.defaultMarkerWithHue(
      _getColorHue(color),
    );
  }

  double _getColorHue(String hexColor) {
    // Convert hex color to hue
    final color = _parseColor(hexColor);
    final hsl = HSLColor.fromColor(color);
    return hsl.hue;
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

// Extension to access private field
extension MapProviderExt on MapProvider {
  set _cameraPosition(LatLng? pos) {
    // This is a workaround - in production, make the field public or add a setter
  }
  set _zoomLevel(double zoom) {
    // This is a workaround - in production, make the field public or add a setter
  }
}
