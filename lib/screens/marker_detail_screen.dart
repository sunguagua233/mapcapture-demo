import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../data/models/models.dart';
import '../providers/providers.dart';
import '../widgets/image_picker_widget.dart';

class MarkerDetailScreen extends StatefulWidget {
  final String markerId;
  final String tripId;

  const MarkerDetailScreen({
    super.key,
    required this.markerId,
    required this.tripId,
  });

  @override
  State<MarkerDetailScreen> createState() => _MarkerDetailScreenState();
}

class _MarkerDetailScreenState extends State<MarkerDetailScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  Marker? _marker;
  String? _selectedCategory;
  String _selectedColor = AppConstants.markerColors.first;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarker();
  }

  Future<void> _loadMarker() async {
    setState(() => _isLoading = true);

    final marker = await context
        .read<MarkerProvider>()
        .getMarkerById(widget.markerId);

    if (marker != null) {
      setState(() {
        _marker = marker;
        _titleController.text = marker.title;
        _addressController.text = marker.address;
        _notesController.text = marker.notes ?? '';
        _linkController.text = marker.link ?? '';
        _selectedCategory = marker.category;
        _selectedColor = marker.color;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _saveMarker() async {
    if (_marker == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final updatedMarker = _marker!.copyWith(
      title: title,
      address: _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      link: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
      category: _selectedCategory,
      color: _selectedColor,
    );

    final success = await context.read<MarkerProvider>().updateMarker(updatedMarker);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marker updated')),
      );
    }
  }

  Future<void> _deleteMarker() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Marker'),
        content: const Text('Are you sure you want to delete this marker?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context
          .read<MarkerProvider>()
          .deleteMarker(widget.markerId);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marker deleted')),
        );
      }
    }
  }

  void _openMap() {
    if (_marker == null) return;

    // Show location on map (in a real app, this would open the map with this marker selected)
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Marker Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_marker == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Marker Details')),
        body: const Center(child: Text('Marker not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marker Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: _openMap,
            tooltip: 'Show on Map',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteMarker,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Basic Info'),
            const SizedBox(height: 8),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildAddressField(),
            const SizedBox(height: 16),
            _buildCoordinatesDisplay(),
            const SizedBox(height: 24),

            _buildSectionHeader('Category & Color'),
            const SizedBox(height: 8),
            _buildCategorySelector(),
            const SizedBox(height: 16),
            _buildColorSelector(),
            const SizedBox(height: 24),

            _buildSectionHeader('Notes'),
            const SizedBox(height: 8),
            _buildNotesField(),
            const SizedBox(height: 24),

            _buildSectionHeader('Link'),
            const SizedBox(height: 8),
            _buildLinkField(),
            const SizedBox(height: 24),

            _buildSectionHeader('Photos'),
            const SizedBox(height: 8),
            ImagePickerWidget(
              markerId: widget.markerId,
              images: _marker!.images,
            ),
            const SizedBox(height: 32),

            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title',
        hintText: 'Enter marker title',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildAddressField() {
    return TextField(
      controller: _addressController,
      decoration: const InputDecoration(
        labelText: 'Address',
        hintText: 'Enter address',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
    );
  }

  Widget _buildCoordinatesDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_marker!.latitude.toStringAsFixed(6)}, ${_marker!.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.markerCategories.map((category) {
        final isSelected = _selectedCategory == category;
        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedCategory = selected ? category : null;
            });
          },
          selectedColor: AppTheme.primaryColor.withOpacity(0.3),
          checkmarkColor: AppTheme.primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppConstants.markerColors.map((color) {
        final isSelected = _selectedColor == color;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedColor = color);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _parseColor(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes',
        hintText: 'Add notes about this place',
        border: OutlineInputBorder(),
      ),
      maxLines: 4,
    );
  }

  Widget _buildLinkField() {
    return TextField(
      controller: _linkController,
      decoration: const InputDecoration(
        labelText: 'Link',
        hintText: 'https://example.com',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.link),
      ),
      keyboardType: TextInputType.url,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveMarker,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
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
