import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:open_filex/open_filex.dart';
import 'package:excel/excel.dart' as excel_package;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // <-- Easy Localization import
import 'info_card.dart';  // <-- Custom InfoCard import

Future<void> exportToExcel({
  required List<Map<String, dynamic>> data,
  required String fileName,
  required String sheetName, // this parameter will be ignored
  required BuildContext context,
}) async {
  try {
    // Create a new Excel workbook
    var excel = excel_package.Excel.createExcel();
    
    // Get the default sheet name and rename it
    var defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, 'Data'); // Rename default sheet to avoid issues
      excel_package.Sheet sheetObject = excel['Data']; 
      
      // Başlıkları ekleyin (header)
      if (data.isNotEmpty) {
        sheetObject.appendRow(data.first.keys.toList());
      }

      // Verileri ekleyin (data rows)
      for (var row in data) {
        sheetObject.appendRow(row.values.toList());
      }
    }

    // Web platformu için
    if (kIsWeb) {
      try {
        final blob = excel.encode();
        if (blob != null) {
          final content = base64Encode(blob);
          html.AnchorElement(
            href: 'data:application/octet-stream;base64,$content',
          )
            ..setAttribute('download', '$fileName.xlsx')
            ..click();

          // Başarılı dışa aktarma mesajı
          InfoCard.showInfoCard(
            context,
            tr("excel.export_success"), // <-- easy localization
            Colors.green,
            icon: Icons.check_circle,
          );
        }
      } catch (webError) {
        debugPrint('Web export error: $webError'); // Geliştirici log
        // Web'de export hatası mesajı
        InfoCard.showInfoCard(
          context,
          tr("excel.web_export_error", args: [webError.toString()]), // <-- easy localization
          Colors.red,
          icon: Icons.error,
        );
      }
    } 
    // Mobil / Masaüstü (Flutter non-web) platformlar için
    else {
      var fileBytes = excel.encode();
      if (fileBytes != null) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final path = "${directory.path}/$fileName.xlsx";
          final file = File(path);
          await file.writeAsBytes(fileBytes);

          await OpenFilex.open(file.path);

          // Başarılı dosya kaydı mesajı
          InfoCard.showInfoCard(
            context,
            tr("excel.file_saved", args: [path]), // <-- easy localization
            Colors.green,
            icon: Icons.check_circle,
          );
        } catch (fileError) {
          debugPrint("Dosya işlem hatası: $fileError"); // Geliştirici log
          // Dosya hatası mesajı
          InfoCard.showInfoCard(
            context,
            tr("excel.file_error", args: [fileError.toString()]), // <-- easy localization
            Colors.red,
            icon: Icons.error,
          );
        }
      }
    }
  } catch (e) {
    debugPrint("Excel dışa aktarma hatası: $e"); // Geliştirici log
    // Genel dışa aktarma hatası mesajı
    InfoCard.showInfoCard(
      context,
      tr("excel.export_error", args: [e.toString()]), // <-- easy localization
      Colors.red,
      icon: Icons.error,
    );
  }
}

void downloadExcelTemplate({
  required String fileName,
  required List<String> headers,
  required List<String> exampleData,
  required BuildContext context,
}) {
  try {
    // Create a new Excel workbook
    final excel = excel_package.Excel.createExcel();
    
    // Get the default sheet
    final sheet = excel['Sheet1'];
    
    // Add headers to the first row - create a new mutable list
    List<dynamic> headerRow = [];
    for (var header in headers) {
      headerRow.add(header);
    }
    sheet.appendRow(headerRow);
    
    // Add example data to the second row - create a new mutable list
    List<dynamic> dataRow = [];
    for (var data in exampleData) {
      dataRow.add(data);
    }
    sheet.appendRow(dataRow);
    
    // Generate Excel file bytes
    final bytes = excel.encode();
    if (bytes != null) {
      // Create blob and download link
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Trigger download
      html.AnchorElement(href: url)
        ..setAttribute('download', '$fileName.xlsx')
        ..click();
      
      // Clean up the URL
      html.Url.revokeObjectUrl(url);
    } else {
      throw Exception('Excel dosyası oluşturulamadı');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Şablon oluşturulurken hata: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
