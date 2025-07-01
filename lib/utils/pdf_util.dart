import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfUtil {
  /// Loads the OpenSans font family for PDF generation with Turkish character support
  static Future<pw.ThemeData> loadTurkishSupportFont() async {
    // Load font files
    final ByteData regular = await rootBundle.load('assets/fonts/opensans/OpenSans-Regular.ttf');
    final ByteData bold = await rootBundle.load('assets/fonts/opensans/OpenSans-Bold.ttf');
    final ByteData italic = await rootBundle.load('assets/fonts/opensans/OpenSans-Italic.ttf');
    
    // Convert to font objects
    final ttf = pw.Font.ttf(regular.buffer.asByteData());
    final ttfBold = pw.Font.ttf(bold.buffer.asByteData());
    final ttfItalic = pw.Font.ttf(italic.buffer.asByteData());
    
    // Create PDF theme with custom font
    return pw.ThemeData.withFont(
      base: ttf,
      bold: ttfBold,
      italic: ttfItalic,
    );
  }
}
