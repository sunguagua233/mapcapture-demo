import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapcapture/core/constants/app_constants.dart';
import 'package:mapcapture/data/providers/database_providers.dart';
import 'package:mapcapture/data/repositories/trip_repository.dart';
import 'package:mapcapture/features/map/presentation/map_screen.dart';

/// Trip list screen - main entry point showing all trips
class TripListScreen extends ConsumerStatefulWidget {
  const TripListScreen({super.key});

  @override
  ConsumerState<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends ConsumerState<TripListScreen> {
  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(_tripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MapCapture'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Open settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置（待实现）')),
              );
            },
          ),
        ],
      ),
      body: tripsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(_tripsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (trips) {
          if (trips.isEmpty) {
            return _EmptyState(
              onCreateTrip: _showCreateTripDialog,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_tripsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length + 1, // +1 for FAB space
              itemBuilder: (context, index) {
                if (index >= trips.length) {
                  return const SizedBox(height: 80); // Space for FAB
                }

                final tripWithCount = trips[index];
                return _TripCard(
                  trip: tripWithCount.trip,
                  markerCount: tripWithCount.markerCount,
                  onTap: () => _openTrip(tripWithCount.trip),
                  onEdit: () => _showEditTripDialog(tripWithCount.trip),
                  onDelete: () => _deleteTrip(tripWithCount.trip.id!),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTripDialog,
        icon: const Icon(Icons.add),
        label: const Text('创建行程'),
      ),
    );
  }

  Future<void> _showCreateTripDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _TripDialog(
        controller: controller,
        title: '创建新行程',
        confirmText: '创建',
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      final tripRepo = ref.read(tripRepositoryProvider);

      // Find max display order
      final trips = await tripRepo.getAllTrips();
      final maxOrder = trips.isEmpty
          ? -1
          : trips.map((t) => t.displayOrder).reduce((a, b) => a > b ? a : b);

      await tripRepo.createTrip(
        TripsCompanion(
          name: Value(controller.text.trim()),
          displayOrder: Value(maxOrder + 1),
        ),
      );

      if (mounted) {
        ref.invalidate(_tripsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('行程已创建')),
        );
      }
    }

    controller.dispose();
  }

  Future<void> _showEditTripDialog(trip) async {
    final controller = TextEditingController(text: trip.name);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _TripDialog(
        controller: controller,
        title: '编辑行程',
        confirmText: '保存',
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      final tripRepo = ref.read(tripRepositoryProvider);
      final updated = trip.copyWith(name: controller.text.trim());
      await tripRepo.updateTrip(updated);

      if (mounted) {
        ref.invalidate(_tripsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('行程已更新')),
        );
      }
    }

    controller.dispose();
  }

  Future<void> _deleteTrip(int tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除行程将同时删除所有相关标记，此操作不可撤销。确定要删除吗？'),
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
      final tripRepo = ref.read(tripRepositoryProvider);
      await tripRepo.deleteTrip(tripId);

      if (mounted) {
        ref.invalidate(_tripsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('行程已删除')),
        );
      }
    }
  }

  void _openTrip(trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          tripId: trip.id!,
          tripName: trip.name,
        ),
      ),
    );
  }
}

/// Provider for trips with marker count
final _tripsProvider = FutureProvider.autoDispose((ref) async {
  final tripRepo = ref.read(tripRepositoryProvider);
  return tripRepo.getTripsWithMarkerCount();
});

/// Empty state widget
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTrip;

  const _EmptyState({
    required this.onCreateTrip,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有行程',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('创建一个新行程开始规划吧'),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onCreateTrip,
            icon: const Icon(Icons.add),
            label: const Text('创建行程'),
          ),
        ],
      ),
    );
  }
}

/// Trip card widget
class _TripCard extends StatelessWidget {
  final trip;
  final int markerCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TripCard({
    required this.trip,
    required this.markerCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Cover image placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: trip.coverImagePath != null
                    ? const Icon(Icons.image, size: 32)
                    : Icon(
                        Icons.map_outlined,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
              ),
              const SizedBox(width: 16),

              // Trip info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '$markerCount 个标记',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (trip.startDate != null || trip.endDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateRange(trip.startDate, trip.endDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('编辑'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    if (start == null) return '至 ${_formatDate(end)}';
    if (end == null) return '${_formatDate(start)} 起';
    if (start.isAtSameMomentAs(end)) {
      return _formatDate(start);
    }
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}月${date.day}日';
  }
}

/// Trip dialog widget
class _TripDialog extends StatefulWidget {
  final TextEditingController controller;
  final String title;
  final String confirmText;

  const _TripDialog({
    required this.controller,
    required this.title,
    required this.confirmText,
  });

  @override
  State<_TripDialog> createState() => _TripDialogState();
}

class _TripDialogState extends State<_TripDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: widget.controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '行程名称',
          hintText: '例如：云南之旅',
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _handleConfirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _handleConfirm,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }

  void _handleConfirm() {
    if (widget.controller.text.trim().isNotEmpty) {
      Navigator.pop(context, true);
    }
  }
}
