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

  bool get _isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  String _getFileName(String path) {
    final name = path.split('/').last.split('\\').last;
    return name.isEmpty ? path : name;
  }

  Future<void> _pickFile(
    BuildContext context,
    ImageSource source, {
    String documentType = 'Medical Bill',
  }) async {
    if (source == ImageSource.camera && (kIsWeb || _isDesktop)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera is not available on this device. Please select from Gallery.',
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
            : _getFileName(picked.path),
        documentType: documentType,
        localPath: picked.path,
        bytes: bytes,
        fileSizeBytes: bytes.length,
      );

      onFileSelected?.call(picked.path);
      onAttachmentAdded?.call(attachment);
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}: ${error.message ?? error.code}',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to select image.')),
      );
    }
  }

  void _showUploadOptions(BuildContext context) {
    if (!enabled) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: MedicalClaimsColors.accentBlue,
              ),
              title: const Text('Upload Medical Bill (Gallery)'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickFile(
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
              title: const Text('Upload Medical Report (Gallery)'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickFile(
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
              title: const Text('Take Photo (Camera)'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickFile(
                  context,
                  ImageSource.camera,
                  documentType: 'Medical Bill',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleOcrTap(BuildContext context) {
    if (onScanWithOcr != null) {
      onScanWithOcr!();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Bill OCR scanner is not connected yet.')),
    );
  }

  List<PendingMedicalAttachment> _currentFiles() {
    if (attachments.isNotEmpty) return attachments;
    final path = selectedFilePath?.trim();
    if (path != null && path.isNotEmpty) {
      return [
        PendingMedicalAttachment(
          fileName: _getFileName(path),
          localPath: path,
        ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final items = _currentFiles();

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
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? () => _showUploadOptions(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: MedicalClaimsColors.dashedBorder,
                width: 1.4,
              ),
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: enabled
                          ? () => _pickFile(context, ImageSource.camera)
                          : null,
                      icon: const Icon(Icons.photo_camera_outlined, size: 17),
                      label: const Text('Camera'),
                    ),
                    OutlinedButton.icon(
                      onPressed: enabled
                          ? () => _pickFile(context, ImageSource.gallery)
                          : null,
                      icon: const Icon(Icons.photo_library_outlined, size: 17),
                      label: const Text('Gallery'),
                    ),
                    OutlinedButton.icon(
                      onPressed: enabled ? () => _handleOcrTap(context) : null,
                      icon: const Icon(
                        Icons.document_scanner_outlined,
                        size: 17,
                      ),
                      label: const Text('Scan Bill with AI OCR'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        for (var i = 0; i < items.length; i++) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: MedicalClaimsColors.softBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MedicalClaimsColors.softBlueBorder),
            ),
            child: Row(
              children: [
                if (!kIsWeb &&
                    items[i].localPath != null &&
                    File(items[i].localPath!).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(items[i].localPath!),
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Icon(
                    Icons.description_outlined,
                    color: MedicalClaimsColors.navy,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].fileName,
                        style: const TextStyle(
                          color: MedicalClaimsColors.navy,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${items[i].formattedSize} · Uploaded',
                        style: const TextStyle(
                          color: MedicalClaimsColors.textSecondary,
                          fontSize: 11.5,
                        ),
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
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      if (onAttachmentRemoved != null &&
                          attachments.isNotEmpty) {
                        onAttachmentRemoved!(i);
                      } else {
                        onFileSelected?.call(null);
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
