import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../medical_claims/models/ocr_bill_data.dart';
import 'ocr_bill_parser.dart';

/// Service interfacing with Google ML Kit Text Recognition on device.
class MlKitOcrService {
  MlKitOcrService({TextRecognizer? recognizer})
      : _recognizer = recognizer ??
            TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;
  bool _disposed = false;

  /// Recognizes text from a local image file and parses medical bill fields.
  Future<OcrBillData> processBillImage(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw ArgumentError('Bill image file does not exist at $filePath');
    }

    final inputImage = InputImage.fromFilePath(filePath);
    final RecognizedText recognizedText =
        await _recognizer.processImage(inputImage);

    final rawText = recognizedText.text;
    debugPrint('ML Kit OCR Extracted Text:\n$rawText');

    return OcrBillParser.parseText(rawText, imagePath: filePath);
  }

  /// Closes the ML Kit recognizer resources.
  void dispose() {
    if (!_disposed) {
      _recognizer.close();
      _disposed = true;
    }
  }
}
