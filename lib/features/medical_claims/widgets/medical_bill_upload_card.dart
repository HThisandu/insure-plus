import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/medical_bill_document.dart';
import 'medical_status_badge.dart';

class MedicalBillUploadCard extends StatelessWidget {
  const MedicalBillUploadCard({
    super.key,
    this.selectedFilePath,
    this.onFileSelected,
    this.attachments = const [],
    this.onAttachmentAdded,
    this.onAttachmentRemoved,
    this.onScanWithOcr,
    this.enabled = true,
  });

  final String? selectedFilePath;
  final ValueChanged<String?>? onFileSelected;
  final List<PendingMedicalAttachment> attachments;
  final ValueChanged<PendingMedicalAttachment>? onAttachmentAdded;
  final ValueChanged<int>? onAttachmentRemoved;
  final VoidCallback? onScanWithOcr;
  final bool enabled;

  bool get _isDesktopPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  String _fileNameFromPath(String path) {
    final segments = path
        .split(RegExp(r'[/\\]'))
        .where((part) => part.isNotEmpty)
        .toList();
    return segments.isNotEmpty ? segments.last : path;
  }

  Future<void> _pickImage(
    BuildContext context,
    ImageSource source, {
    String documentType = 'Medical Bill',
  }) async {
    if (source == ImageSource.camera && (kIsWeb || _isDesktopPlatform)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera capture is not supported on this device. Please select from Gallery.',
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
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final attachment = PendingMedicalAttachment(
        fileName: picked.name.isNotEmpty
            ? picked.name
            : _fileNameFromPath(picked.path),
        documentType: documentType,
        localPath: picked.path,
        bytes: bytes,
        fileSizeBytes: bytes.length,
      );

      onFileSelected?.call(picked.path);
      onAttachmentAdded?.call(attachment);
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      final isDenied =
          error.code.toLowerCase().contains('denied') ||
          error.code.toLowerCase().contains('permission');
      final message = isDenied
          ? 'Permission denied. Enable ${source == ImageSource.camera ? 'camera' : 'photo library'} access in settings.'
          : 'Could not select document: ${error.message ?? error.code}';
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

  void _showUploadSourceSheet(BuildContext context) {
    if (!enabled) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: MedicalClaimsColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Upload Medical Document',
                    style: TextStyle(
                      color: MedicalClaimsColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: MedicalClaimsColors.accentBlue,
                ),
                title: const Text('Upload Medical Bill from Gallery'),
                subtitle: const Text('Hospital invoice or pharmacy receipt'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(
                    context,
                    ImageSource.gallery,
                    documentType: 'Medical Bill',
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.assignment_outlined,
                  color: MedicalClaimsColors.accentBlue,
                ),
                title: const Text('Upload Medical Report from Gallery'),
                subtitle: const Text('Discharge summary or lab report'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(
                    context,
                    ImageSource.gallery,
                    documentType: 'Medical Report',
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: MedicalClaimsColors.navy,
                ),
                title: const Text('Take Photo with Camera'),
                subtitle: const Text('Capture medical bill or report directly'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(
                    context,
                    ImageSource.camera,
                    documentType: 'Medical Bill',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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

  List<PendingMedicalAttachment> _resolvedAttachments() {
    if (attachments.isNotEmpty) return attachments;
    final path = selectedFilePath?.trim();
    if (path != null && path.isNotEmpty) {
      return [
        PendingMedicalAttachment(
          fileName: _fileNameFromPath(path),
          documentType: 'Medical Bill',
          localPath: path,
        ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final items = _resolvedAttachments();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Supporting documents',
          style: TextStyle(
            color: MedicalClaimsColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        CustomPaint(
          painter: _DashedRoundedRectPainter(
            color: MedicalClaimsColors.dashedBorder,
            radius: 14,
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: enabled ? () => _showUploadSourceSheet(context) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 22,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.upload_rounded,
                      size: 28,
                      color: MedicalClaimsColors.accentBlue,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap to upload documents',
                      style: TextStyle(
                        color: MedicalClaimsColors.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Medical bills or reports · JPG, PNG · Up to 10 MB each',
                      style: TextStyle(
                        color: MedicalClaimsColors.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: enabled
                              ? () => _pickImage(context, ImageSource.camera)
                              : null,
                          icon: const Icon(
                            Icons.photo_camera_outlined,
                            size: 17,
                          ),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MedicalClaimsColors.navy,
                            side: const BorderSide(
                              color: MedicalClaimsColors.border,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: enabled
                              ? () => _pickImage(context, ImageSource.gallery)
                              : null,
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 17,
                          ),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MedicalClaimsColors.navy,
                            side: const BorderSide(
                              color: MedicalClaimsColors.border,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: enabled
                              ? () => _handleOcrPressed(context)
                              : null,
                          icon: const Icon(
                            Icons.document_scanner_outlined,
                            size: 17,
                          ),
                          label: const Text('Scan Bill with AI OCR'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MedicalClaimsColors.accentBlue,
                            side: const BorderSide(
                              color: MedicalClaimsColors.softBlueBorder,
                            ),
                            backgroundColor: MedicalClaimsColors.softBlue,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        for (var i = 0; i < items.length; i++) ...[
          const SizedBox(height: 10),
          _AttachedDocumentRow(
            attachment: items[i],
            enabled: enabled,
            onRemove: () {
              if (onAttachmentRemoved != null && attachments.isNotEmpty) {
                onAttachmentRemoved!(i);
              } else {
                onFileSelected?.call(null);
              }
            },
          ),
        ],
      ],
    );
  }
}

class _AttachedDocumentRow extends StatelessWidget {
  const _AttachedDocumentRow({
    required this.attachment,
    required this.enabled,
    required this.onRemove,
  });

  final PendingMedicalAttachment attachment;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final localPath = attachment.localPath;
    final hasLocalThumb =
        !kIsWeb &&
        localPath != null &&
        localPath.isNotEmpty &&
        File(localPath).existsSync();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MedicalClaimsColors.softBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MedicalClaimsColors.softBlueBorder),
      ),
      child: Row(
        children: [
          if (hasLocalThumb)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(localPath),
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.description_outlined,
                  color: MedicalClaimsColors.navy,
                ),
              ),
            )
          else
            const Icon(
              Icons.description_outlined,
              color: MedicalClaimsColors.navy,
              size: 22,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: const TextStyle(
                    color: MedicalClaimsColors.navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${attachment.formattedSize} · Ready for Supabase upload',
                  style: const TextStyle(
                    color: MedicalClaimsColors.textSecondary,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_rounded,
            color: MedicalClaimsColors.successFg,
            size: 20,
          ),
          if (enabled)
            IconButton(
              tooltip: 'Remove document',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: MedicalClaimsColors.textSecondary,
              ),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 6.0;
    const dashSpace = 4.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
