import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_helper.dart';
import '../providers/providers.dart';
import '../widgets/trip_card.dart';
import 'map_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateTripDialog() {
    final nameController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Trip Name',
                    hintText: 'Enter trip name',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setDialogState(() => startDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                    ),
                    child: Text(
                      startDate != null
                          ? DateHelper.formatDisplayDate(startDate)
                          : 'Select start date',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setDialogState(() => endDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                    ),
                    child: Text(
                      endDate != null
                          ? DateHelper.formatDisplayDate(endDate)
                          : 'Select end date',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a trip name')),
                  );
                  return;
                }

                final trip = await context.read<TripProvider>().createTrip(
                      name: name,
                      startDate: startDate,
                      endDate: endDate,
                    );

                if (trip != null && mounted) {
                  Navigator.pop(context);
                  _openTrip(trip.id);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _openTrip(String tripId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(tripId: tripId),
      ),
    );
  }

  void _showTripOptions(Trip trip) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Trip'),
              onTap: () {
                Navigator.pop(context);
                _editTrip(trip);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Trip'),
              textColor: AppTheme.errorColor,
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteTrip(trip);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editTrip(Trip trip) {
    final nameController = TextEditingController(text: trip.name);
    DateTime? startDate = trip.startDate;
    DateTime? endDate = trip.endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Trip Name',
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setDialogState(() => startDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                    ),
                    child: Text(
                      startDate != null
                          ? DateHelper.formatDisplayDate(startDate)
                          : 'Not set',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setDialogState(() => endDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                    ),
                    child: Text(
                      endDate != null
                          ? DateHelper.formatDisplayDate(endDate)
                          : 'Not set',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a trip name')),
                  );
                  return;
                }

                final updatedTrip = trip.copyWith(
                  name: name,
                  startDate: startDate,
                  endDate: endDate,
                );

                await context.read<TripProvider>().updateTrip(updatedTrip);

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTrip(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text(
          'Are you sure you want to delete "${trip.name}"? This will also delete all markers in this trip.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<TripProvider>().deleteTrip(trip.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trip deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MapCapture'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clean') {
                // Clean temp files
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clean',
                child: Text('Clean Temp Files'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<TripProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.initialize(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!provider.hasTrips) {
            return _buildEmptyState();
          }

          final trips = _searchQuery.isEmpty
              ? provider.trips
              : provider.trips
                  .where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();

          if (trips.isEmpty) {
            return _buildNoResultsState();
          }

          return _isGridView ? _buildGrid(trips) : _buildList(trips);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTripDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No trips yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first trip to start capturing locations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No trips found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Trip> trips) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return TripCard(
          trip: trips[index],
          onTap: () => _openTrip(trips[index].id),
          onLongPress: () => _showTripOptions(trips[index]),
        );
      },
    );
  }

  Widget _buildList(List<Trip> trips) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TripCard(
            trip: trips[index],
            onTap: () => _openTrip(trips[index].id),
            onLongPress: () => _showTripOptions(trips[index]),
            isListMode: true,
          ),
        );
      },
    );
  }
}

// Import the DateHelper
import '../core/utils/date_helper.dart';
