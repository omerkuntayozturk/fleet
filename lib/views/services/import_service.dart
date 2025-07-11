import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html;
import 'package:excel/excel.dart' as excel_package;
import '../../services/firestore_service.dart';
import '../../info_card.dart'; // InfoCard importu eklendi
import 'package:easy_localization/easy_localization.dart'; // Add Easy Localization import

class ServiceImportExport {
  static final FirestoreService _firestoreService = FirestoreService();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> exportServices(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        Navigator.pop(context);
        InfoCard.showInfoCard(
          context,
          tr('service_export_login_required'),
          Colors.red,
          icon: Icons.error,
        );
        return;
      }

      // Fetch services and vehicles for mapping
      final services = await _firestoreService.fetchServices(userId: currentUser.uid);
      final vehicles = await _firestoreService.fetchVehiclesWithDetails(userId: currentUser.uid);
      final vehicleMap = {for (var v in vehicles) v.id: v.model};

      if (services.isEmpty) {
        Navigator.pop(context);
        InfoCard.showInfoCard(
          context,
          tr('service_export_no_records'),
          Colors.orange,
          icon: Icons.info_outline,
        );
        return;
      }

      // Create Excel workbook and sheet
      final excel = excel_package.Excel.createExcel();
      final sheet = excel[tr('service_export_sheet_name')];
      excel.setDefaultSheet(tr('service_export_sheet_name'));

      // Add header row
      sheet.appendRow([
        tr('service_export_column_vehicle'),
        tr('service_export_column_date'),
        tr('service_export_column_type'),
        tr('service_export_column_cost'),
        tr('service_export_column_notes'),
      ]);

      // Add service rows
      for (final s in services) {
        sheet.appendRow([
          vehicleMap[s['vehicleId']] ?? s['vehicleId'] ?? '',
          s['date'] is DateTime
              ? '${s['date'].day.toString().padLeft(2, '0')}.${s['date'].month.toString().padLeft(2, '0')}.${s['date'].year}'
              : '',
          s['serviceType'] ?? '',
          s['cost']?.toString() ?? '',
          s['notes'] ?? '',
        ]);
      }

      // Encode and trigger download
      final bytes = excel.encode();
      if (bytes != null) {
        final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', '${tr('service_export_filename')}_${DateTime.now().millisecondsSinceEpoch}.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
        Navigator.pop(context);
        InfoCard.showInfoCard(
          context,
          tr('service_export_success', namedArgs: {'count': services.length.toString()}),
          Colors.green,
          icon: Icons.check_circle_outline,
        );
      } else {
        Navigator.pop(context);
        InfoCard.showInfoCard(
          context,
          tr('service_export_excel_error'),
          Colors.red,
          icon: Icons.error_outline,
        );
      }
    } catch (e) {
      Navigator.pop(context);
      InfoCard.showInfoCard(
        context,
        tr('service_export_error', namedArgs: {'error': e.toString()}),
        Colors.red,
        icon: Icons.error,
      );
    }
  }
}
