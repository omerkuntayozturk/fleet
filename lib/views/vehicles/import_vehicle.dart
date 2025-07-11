import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html;
import 'package:excel/excel.dart' as excel_package;
import '../../info_card.dart'; // InfoCard importu eklendi
import 'package:easy_localization/easy_localization.dart'; // Add Easy Localization import

class VehicleImportExport {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static void exportVehicles(BuildContext context) async {
    // Show loading indicator
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
          tr('vehicle_export_login_required'),
          Colors.red,
          icon: Icons.error,
        );
        return;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('vehicles')
          .get();

      Navigator.pop(context);

      if (querySnapshot.docs.isEmpty) {
        InfoCard.showInfoCard(
          context,
          tr('vehicle_export_no_records'),
          Colors.orange,
          icon: Icons.info_outline,
        );
        return;
      }

      final excel = excel_package.Excel.createExcel();
      final sheet = excel[tr('vehicle_export_sheet_name')];
      excel.setDefaultSheet(tr('vehicle_export_sheet_name'));

      // Add headers
      sheet.appendRow([
        tr('vehicle_export_column_model'),
        tr('vehicle_export_column_plate'),
        tr('vehicle_export_column_year'),
      ]);

      // Add vehicle data
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        sheet.appendRow([
          data['model'] ?? '',
          data['plate'] ?? '',
          data['year']?.toString() ?? '',
        ]);
      }

      final bytes = excel.encode();
      if (bytes != null) {
        final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', '${tr('vehicle_export_filename')}_${DateTime.now().millisecondsSinceEpoch}.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);

        InfoCard.showInfoCard(
          context,
          tr('vehicle_export_success', namedArgs: {'count': querySnapshot.docs.length.toString()}),
          Colors.green,
          icon: Icons.check_circle_outline,
        );
      } else {
        InfoCard.showInfoCard(
          context,
          tr('vehicle_export_excel_error'),
          Colors.red,
          icon: Icons.error_outline,
        );
      }
    } catch (e) {
      try {
        Navigator.pop(context);
      } catch (_) {}
      InfoCard.showInfoCard(
        context,
        tr('vehicle_export_error', namedArgs: {'error': e.toString()}),
        Colors.red,
        icon: Icons.error,
      );
    }
  }
}
