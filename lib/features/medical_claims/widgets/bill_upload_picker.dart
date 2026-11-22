import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BillUploadPicker extends StatelessWidget {
  const BillUploadPicker({
    super.key,
    required this.selectedFilePath,
    required this.onFileSelected,
    this.enabled = true,
  });

  final String? selectedFilePath;
  final ValueChanged<String?> onFileSelected;
  final bool enabled;

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked != null) {
        onFileSelected(picked.path);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to access ${source == ImageSource.camera ? 'camera' : 'gallery'}: $error',
          ),
        ),
      );
    }
  }

  String _fileNameFromPath(String path) {
    final segments = path
        .split(RegExp(r'[/\\]'))
        .where((part) => part.isNotEmpty)
        .toList();
    return segments.isNotEmpty ? segments.last : path;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasFile =
        selectedFilePath != null && selectedFilePath!.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Medical Bill Document',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasFile)
                  TextButton.icon(
                    onPressed: enabled ? () => onFileSelected(null) : null,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a clear photo of your hospital invoice, pharmacy receipt, or lab bill.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (hasFile) ...[
              _SelectedBillPreview(
                filePath: selectedFilePath!,
                fileName: _fileNameFromPath(selectedFilePath!),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: enabled
                      ? () => _pickImage(context, ImageSource.camera)
                      : null,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(hasFile ? 'Retake photo' : 'Take photo'),
                ),
                OutlinedButton.icon(
                  onPressed: enabled
                      ? () => _pickImage(context, ImageSource.gallery)
                      : null,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(hasFile ? 'Choose another' : 'Upload from gallery'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedBillPreview extends StatelessWidget {
  const _SelectedBillPreview({
    required this.filePath,
    required this.fileName,
  });

  final String filePath;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canPreviewFile = !kIsWeb && File(filePath).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canPreviewFile)
            SizedBox(
              height: 160,
              child: Image.file(
                File(filePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _PlaceholderPreview(colors: colors),
              ),
            )
          else
            _PlaceholderPreview(colors: colors),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderPreview extends StatelessWidget {
  const _PlaceholderPreview({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.description_outlined,
        size: 36,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}
