import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class MedicalBillUploadCard extends StatelessWidget {
  const MedicalBillUploadCard({
    super.key,
    required this.selectedFilePath,
    required this.onFileSelected,
    this.onScanWithOcr,
    this.enabled = true,
  });

  final String? selectedFilePath;
  final ValueChanged<String?> onFileSelected;
  final VoidCallback? onScanWithOcr;
  final bool enabled;

  bool get _isDesktopPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    if (source == ImageSource.camera && (kIsWeb || _isDesktopPlatform)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera capture is not supported on this device. Please choose an image from Gallery.',
          ),
        ),
      );
      return;
    }

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
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      final isDenied =
          error.code.toLowerCase().contains('denied') ||
          error.code.toLowerCase().contains('permission');
      final message = isDenied
          ? 'Permission denied. Please enable ${source == ImageSource.camera ? 'camera' : 'photo library'} access in device settings.'
          : 'Could not select medical bill image: ${error.message ?? error.code}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open ${source == ImageSource.camera ? 'camera' : 'gallery'} on this device.',
          ),
        ),
      );
    }
  }

  void _handleOcrPressed(BuildContext context) {
    final callback = onScanWithOcr;
    if (callback != null) {
      callback();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'AI Bill OCR scanner is ready for Member 06\'s Google ML Kit module integration.',
        ),
      ),
    );
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Medical Bill Upload',
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
            const SizedBox(height: 6),
            Text(
              'Attach a clear photo of your hospital invoice, pharmacy receipt, or lab bill.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (hasFile) ...[
              _BillThumbnailPreview(
                filePath: selectedFilePath!,
                fileName: _fileNameFromPath(selectedFilePath!),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: enabled
                      ? () => _pickImage(context, ImageSource.camera)
                      : null,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(hasFile ? 'Replace via Camera' : 'Camera'),
                ),
                OutlinedButton.icon(
                  onPressed: enabled
                      ? () => _pickImage(context, ImageSource.gallery)
                      : null,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(hasFile ? 'Replace via Gallery' : 'Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: enabled ? () => _handleOcrPressed(context) : null,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Scan Bill with AI OCR'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillThumbnailPreview extends StatelessWidget {
  const _BillThumbnailPreview({
    required this.filePath,
    required this.fileName,
  });

  final String filePath;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canRenderLocalImage = !kIsWeb && File(filePath).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: canRenderLocalImage
                ? Image.file(
                    File(filePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _ThumbnailFallback(colors: colors),
                  )
                : _ThumbnailFallback(colors: colors),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Ready to upload',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.description_outlined,
          size: 32,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
