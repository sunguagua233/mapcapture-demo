import 'package:flutter/material.dart';
import 'package:mapcapture/data/models/marker_model.dart';

/// Marker form widget - for adding/editing marker details
class MarkerForm extends StatefulWidget {
  final MarkerEntity? marker;
  final Future<void> Function(MarkerEntity) onSave;

  const MarkerForm({
    super.key,
    this.marker,
    required this.onSave,
  });

  @override
  State<MarkerForm> createState() => _MarkerFormState();
}

class _MarkerFormState extends State<MarkerForm> {
  late TextEditingController _titleController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  late TextEditingController _linkController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.marker?.title ?? '');
    _addressController = TextEditingController(text: widget.marker?.address ?? '');
    _notesController = TextEditingController(text: widget.marker?.notes ?? '');
    _linkController = TextEditingController(text: widget.marker?.link ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedMarker = (widget.marker ?? MarkerEntity(
        tripId: 0, // Will be set by parent
        title: '',
        address: '',
        latitude: 0,
        longitude: 0,
      )).copyWith(
        title: _titleController.text.trim(),
        address: _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        link: _linkController.text.trim().isEmpty
            ? null
            : _linkController.text.trim(),
      );

      await widget.onSave(updatedMarker);

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  widget.marker == null ? '添加标记' : '编辑标记',
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Form
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Title field
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '标题',
                    hintText: '输入地点名称',
                    prefixIcon: Icon(Icons.edit),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Address field
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: '地址',
                    hintText: '详细地址',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Notes field
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    hintText: '添加备注信息（可选）',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Link field
                TextField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: '链接',
                    hintText: '参考链接（可选）',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),

                // Image upload placeholder
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.image_outlined,
                          size: 48, color: theme.colorScheme.primary),
                      const SizedBox(height: 8),
                      const Text('点击上传图片'),
                      Text(
                        '支持多张图片',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('保存'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
