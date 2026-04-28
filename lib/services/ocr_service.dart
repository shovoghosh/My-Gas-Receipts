import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer();

  Future<Map<String, dynamic>> scanReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _recognizer.processImage(inputImage);

    String? total;
    String? date;

    final totalRegex = RegExp(
      r'total[\s:]*\$?(\d+[.,]\d{2})',
      caseSensitive: false,
    );
    final dateRegex = RegExp(
      r'\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b',
    );

    for (final block in recognizedText.blocks) {
      final text = block.text;
      final totalMatch = totalRegex.firstMatch(text);
      if (totalMatch != null && total == null) {
        total = totalMatch.group(1)?.replaceAll(',', '.');
      }
      final dateMatch = dateRegex.firstMatch(text);
      if (dateMatch != null && date == null) {
        date = dateMatch.group(1);
      }
    }

    return {'total': total, 'date': date};
  }

  void dispose() {
    _recognizer.close();
  }
}
