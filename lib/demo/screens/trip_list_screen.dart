import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../services/data_service.dart';
import 'map_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final DataService _dataService = DataService();
  List<Trip> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _trips = _dataService.getAllTrips();
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MapCapture'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '刷新',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'demo_data':
                  _addDemoData();
                  break;
                case 'clear_all':
                  _clearAllData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'demo_data',
                child: Row(
                  children: [
                    Icon(Icons.dataset, size: 20),
                    SizedBox(width: 12),
                    Text('添加示例数据'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('清空所有数据', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTripDialog,
        icon: const Icon(Icons.add),
        label: const Text('创建行程'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_trips.isEmpty) {
      return _EmptyState(onCreateTrip: _showCreateTripDialog);
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _trips.length + 1,
        itemBuilder: (context, index) {
          if (index >= _trips.length) {
            return const SizedBox(height: 80);
          }

          final trip = _trips[index];
          final markerCount = _dataService.getMarkerCountForTrip(trip.id);

          return _TripCard(
            trip: trip,
            markerCount: markerCount,
            onTap: () => _openTrip(trip),
            onEdit: () => _showEditTripDialog(trip),
            onDelete: () => _deleteTrip(trip),
          );
        },
      ),
    );
  }

  void _addDemoData() {
    _dataService.addDemoData();
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('示例数据已添加')),
      );
    }
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有数据吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _dataService.clearAll();
              Navigator.pop(context);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('所有数据已清空')),
                );
              }
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  void _showCreateTripDialog() async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _TripDialog(controller: controller),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      _dataService.createTrip(name: controller.text.trim());
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('行程已创建')),
        );
      }
    }

    controller.dispose();
  }

  void _showEditTripDialog(Trip trip) async {
    final controller = TextEditingController(text: trip.name);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _TripDialog(
        controller: controller,
        title: '编辑行程',
        confirmText: '保存',
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      _dataService.updateTrip(trip.id, name: controller.text.trim());
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('行程已更新')),
        );
      }
    }

    controller.dispose();
  }

  void _deleteTrip(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除行程"${trip.name}"将同时删除所有相关标记，此操作不可撤销。确定要删除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _dataService.deleteTrip(trip.id);
              Navigator.pop(context);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('行程已删除')),
                );
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _openTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(trip: trip),
      ),
    ).then((_) => _loadData());
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTrip;

  const _EmptyState({required this.onCreateTrip});

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

class _TripCard extends StatelessWidget {
  final Trip trip;
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
                child: Icon(
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
                    const SizedBox(height: 8),
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

class _TripDialog extends StatefulWidget {
  final TextEditingController controller;
  final String title;
  final String confirmText;

  const _TripDialog({
    required this.controller,
    this.title = '创建新行程',
    this.confirmText = '创建',
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
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _confirm,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }

  void _confirm() {
    if (widget.controller.text.trim().isNotEmpty) {
      Navigator.pop(context, true);
    }
  }
}
