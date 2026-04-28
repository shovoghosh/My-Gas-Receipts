import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer();

  final List<String> _stationKeywords = [
    'Shell',
    'BP',
    'Chevron',
    'Exxon',
    'Texaco',
    'Costco',
    'Mobil',
    '76',
    'Arco',
    'Valero',
    'Phillips 66',
    'Marathon',
    ' Speedway',
    'Love\'s',
    'Pilot',
    'Flying J',
    'Circle K',
    '7-Eleven',
    'Sheetz',
    'Wawa',
    'QuikTrip',
    'Kwik Trip',
    'Casey\'s',
    'Murphy',
    'Sam\'s Club',
    'Buc-ee\'s',
  ];

  Future<Map<String, dynamic>> scanReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _recognizer.processImage(inputImage);

    String? total;
    String? date;
    String? stationName;

    final totalRegex = RegExp(
      r'total[\s:]*\$?(\d+[.,]\d{2})',
      caseSensitive: false,
    );
    final dateRegex = RegExp(
      r'\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b',
    );

    final allText = recognizedText.text;

    // Look for station name across all text first
    for (final keyword in _stationKeywords) {
      if (allText.toLowerCase().contains(keyword.toLowerCase())) {
        stationName = keyword;
        break;
      }
    }

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

      // Also check per-block for station name
      if (stationName == null) {
        for (final keyword in _stationKeywords) {
          if (text.toLowerCase().contains(keyword.toLowerCase())) {
            stationName = keyword;
            break;
          }
        }
      }
    }

    return {'total': total, 'date': date, 'stationName': stationName};
  }

  void dispose() {
    _recognizer.close();
  }
}
