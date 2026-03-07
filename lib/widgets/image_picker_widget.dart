import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../core/theme/app_theme.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repositories/image_repository.dart';

class ImagePickerWidget extends StatefulWidget {
  final String markerId;
  final List<MarkerImage> images;

  const ImagePickerWidget({
    super.key,
    required this.markerId,
    required this.images,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  final ImageRepository _imageRepository = ImageRepository();

  bool _isUploading = false;
  List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    _imagePaths = widget.images.map((e) => e.filePath).toList();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: AppConstants.imageQuality,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        setState(() => _isUploading = true);

        // Save image to app storage
        final file = File(image.path);
        final savedPath = await _imageRepository.saveImage(
          file,
          markerId: widget.markerId,
        );

        if (savedPath != null && mounted) {
          // Create MarkerImage and save to database
          final displayOrder = await _imageRepository.getMaxImageDisplayOrder
                  (widget.markerId) +
              1;

          final markerImage = MarkerImage.create(
            markerId: widget.markerId,
            filePath: savedPath,
            displayOrder: displayOrder,
          );

          await _imageRepository.addImage(markerImage);

          setState(() {
            _imagePaths.add(savedPath);
            _isUploading = false;
          });
        } else {
          setState(() => _isUploading = false);
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _removeImage(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Image'),
        content: const Text('Are you sure you want to remove this image?'),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final imagePath = _imagePaths[index];

      // Delete from database
      // This is a simplified approach - in production, you'd need the image ID
      await _imageRepository.deleteImageFile(imagePath);

      setState(() {
        _imagePaths.removeAt(index);
      });
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_imagePaths.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imagePaths.length + 1,
            itemBuilder: (context, index) {
              if (index == _imagePaths.length) {
                return _buildAddButton();
              }
              return _buildImageItem(index);
            },
          ),
        ),
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return InkWell(
      onTap: _isUploading ? null : _showImagePicker,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Add Photos',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: _isUploading ? null : _showImagePicker,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: _isUploading ? Colors.grey[300]! : AppTheme.primaryColor,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: _isUploading ? Colors.grey[400] : AppTheme.primaryColor,
              ),
              const SizedBox(height: 4),
              Text(
                'Add',
                style: TextStyle(
                  color: _isUploading ? Colors.grey[400] : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    final imagePath = _imagePaths[index];

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(imagePath),
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                );
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
