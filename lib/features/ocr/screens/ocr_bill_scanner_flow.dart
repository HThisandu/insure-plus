import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../medical_claims/models/ocr_bill_data.dart';
import '../services/mlkit_ocr_service.dart';
import 'ocr_bill_review_screen.dart';

/// Orchestrates image capture/picking, ML Kit text recognition,
/// and presents the review screen to produce a verified [OcrBillData].
class OcrBillScannerFlow {
  const OcrBillScannerFlow();

  /// Prompts the user to pick or capture an image, runs OCR,
  /// and opens the verification screen.
  static Future<OcrBillData?> startOcrFlow(BuildContext context) async {
    final imagePicker = ImagePicker();

    // 1. Choose Camera or Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo with Camera'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;

    final picked = await imagePicker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2048,
    );

    if (picked == null || !context.mounted) return null;

    // 2. Show OCR processing indicator
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Scanning Medical Bill...',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Extracting bill number, date, amount, and hospital...',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final ocrService = MlKitOcrService();
    OcrBillData extractedData;
    try {
      extractedData = await ocrService.processBillImage(picked.path);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read image with OCR: $e')),
        );
      }
      ocrService.dispose();
      return null;
    } finally {
      ocrService.dispose();
    }

    if (!context.mounted) return null;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog

    // 3. Open user verification and correction screen
    return await Navigator.of(context).push<OcrBillData>(
      MaterialPageRoute(
        builder: (_) => OcrBillReviewScreen(
          initialData: extractedData,
          onRetake: () {
            Navigator.of(context).pop();
            startOcrFlow(context);
          },
        ),
      ),
    );
  }
}
