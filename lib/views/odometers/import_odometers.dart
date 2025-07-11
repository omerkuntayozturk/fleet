import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'package:excel/excel.dart' as excel_package;
import '../../info_card.dart'; // InfoCard importu eklendi
import 'package:easy_localization/easy_localization.dart'; // Add Easy Localization import

/// Exports odometer records to Excel and triggers download.
/// [context] is required for showing messages.
/// [vehiclePlates] is a map of vehicleId to plate for display.
Future<void> exportOdometersToExcel(
  BuildContext context, {
  required Map<String, String> vehiclePlates,
}) async {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        tr('odometer_export_login_required'),
        Colors.red,
        icon: Icons.error,
      );
      return;
    }

    final querySnapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('odometers')
        .orderBy('date', descending: true)
        .get();

    Navigator.pop(context);

    if (querySnapshot.docs.isEmpty) {
      InfoCard.showInfoCard(
        context,
        tr('odometer_export_no_records'),
        Colors.orange,
        icon: Icons.info_outline,
      );
      return;
    }

    final excel = excel_package.Excel.createExcel();
    final sheet = excel[tr('odometer_export_sheet_name')];
    excel.setDefaultSheet(tr('odometer_export_sheet_name'));

    // Header
    sheet.appendRow([
      tr('odometer_export_column_vehicle'),
      tr('odometer_export_column_date'),
      tr('odometer_export_column_value'),
      tr('odometer_export_column_driver'),
    ]);

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final vehicleId = data['vehicleId'] ?? '';
      final plate = vehiclePlates[vehicleId] ?? vehicleId;
      final date = data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now();
      final value = data['value'] ?? '';
      final driver = data['driver'] ?? '';

      sheet.appendRow([
        plate,
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
        value.toString(),
        driver,
      ]);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', '${tr('odometer_export_filename')}_${DateTime.now().millisecondsSinceEpoch}.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);

      InfoCard.showInfoCard(
        context,
        tr('odometer_export_success', namedArgs: {'count': querySnapshot.docs.length.toString()}),
        Colors.green,
        icon: Icons.check_circle_outline,
      );
    } else {
      InfoCard.showInfoCard(
        context,
        tr('odometer_export_excel_error'),
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
      tr('odometer_export_error', namedArgs: {'error': e.toString()}),
      Colors.red,
      icon: Icons.error,
    );
  }
}
