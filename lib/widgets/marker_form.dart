import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../data/models/models.dart';
import '../providers/providers.dart';
import '../services/geocoding_service.dart';

class MarkerForm extends StatefulWidget {
  final String tripId;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final Marker? existingMarker;

  const MarkerForm({
    super.key,
    required this.tripId,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.existingMarker,
  });

  @override
  State<MarkerForm> createState() => _MarkerFormState();
}

class _MarkerFormState extends State<MarkerForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _linkController = TextEditingController();

  final GeocodingService _geocodingService = GeocodingService();

  String? _selectedCategory;
  String _selectedColor = AppConstants.markerColors.first;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingMarker != null) {
      _titleController.text = widget.existingMarker!.title;
      _addressController.text = widget.existingMarker!.address;
      _notesController.text = widget.existingMarker!.notes ?? '';
      _linkController.text = widget.existingMarker!.link ?? '';
      _selectedCategory = widget.existingMarker!.category;
      _selectedColor = widget.existingMarker!.color;
    } else if (widget.initialAddress != null) {
      _addressController.text = widget.initialAddress!;
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final marker = widget.existingMarker != null
          ? widget.existingMarker!.copyWith(
              title: _titleController.text.trim(),
              address: _addressController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              link: _linkController.text.trim().isEmpty
                  ? null
                  : _linkController.text.trim(),
              category: _selectedCategory,
              color: _selectedColor,
            )
          : Marker.create(
              tripId: widget.tripId,
              title: _titleController.text.trim(),
              address: _addressController.text.trim(),
              latitude: widget.initialLatitude ?? AppConstants.defaultLatitude,
              longitude: widget.initialLongitude ?? AppConstants.defaultLongitude,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              link: _linkController.text.trim().isEmpty
                  ? null
                  : _linkController.text.trim(),
              category: _selectedCategory,
              color: _selectedColor,
            );

      final provider = context.read<MarkerProvider>();

      bool success;
      if (widget.existingMarker != null) {
        success = await provider.updateMarker(marker);
      } else {
        final result = await provider.addMarker(marker);
        success = result != null;
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingMarker != null
                ? 'Marker updated'
                : 'Marker added'),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Text(
                  widget.existingMarker != null ? 'Edit Marker' : 'Add Marker',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Location preview
                _buildLocationPreview(),
                const SizedBox(height: 16),

                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Enter a title for this place',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Address field
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter address',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: _fetchAddress,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Category selector
                _buildCategorySelector(),
                const SizedBox(height: 16),

                // Color selector
                _buildColorSelector(),
                const SizedBox(height: 16),

                // Notes field
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Add notes about this place',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Link field
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Link',
                    hintText: 'https://example.com',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveMarker,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.existingMarker != null ? 'Update' : 'Add Marker'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPreview() {
    final lat = widget.existingMarker?.latitude ?? widget.initialLatitude;
    final lng = widget.existingMarker?.longitude ?? widget.initialLongitude;

    if (lat == null || lng == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
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
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
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
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _fetchAddress() async {
    final lat = widget.existingMarker?.latitude ?? widget.initialLatitude;
    final lng = widget.existingMarker?.longitude ?? widget.initialLongitude;

    if (lat == null || lng == null) return;

    final result = await _geocodingService.getAddressFromCoordinates(lat, lng);

    if (result != null && mounted) {
      _addressController.text = result.address;
    }
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
