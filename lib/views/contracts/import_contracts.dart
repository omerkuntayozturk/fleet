import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:excel/excel.dart' as excel_package;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/contract.dart';
import '../../core/enums.dart' as enums;
import '../../info_card.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_localization/easy_localization.dart'; // Add Easy Localization import

class ContractImportExport {
  static final FirestoreService _firestoreService = FirestoreService();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final uuid = Uuid();

  static void importContracts(BuildContext context, Function refreshContracts) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.upload_file,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('contracts_import_title'), // 'Sözleşmeleri İçe Aktar'
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('contracts_import_subtitle'), // 'Excel veya CSV dosyasından sözleşmeleri içe aktarın'
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Örnek şablon indirme bölümü
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          tr('contracts_import_download_template'), // 'Şablon İndir'
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr('contracts_import_template_description'), // 'Sözleşme içe aktarma işlemi için örnek Excel şablonunu indirin. Bu şablonu doldurarak sözleşmelerinizi kolayca ekleyebilirsiniz.'
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: Text(tr('contracts_import_download_template_button')), // 'Şablon İndir'
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _downloadContractTemplate(context),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Dosya yükleme bölümü
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.upload_file, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Text(
                          tr('contracts_import_upload_file'), // 'Dosya Yükle'
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr('contracts_import_upload_description'), // 'Doldurduğunuz şablonu veya mevcut bir Excel/CSV dosyasını yükleyin. Sistem dosyanızı işleyerek sözleşmeleri otomatik olarak ekleyecektir.'
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.file_upload),
                        label: Text(tr('contracts_import_select_file')), // 'Dosya Seç'
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _selectAndUploadFile(context, refreshContracts);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bilgi notu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.amber, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr('contracts_import_note'), // 'Not: İçe aktarma işlemi sırasında en az "Çalışan", "Sözleşme Türü", "Başlangıç Tarihi" ve "Bitiş Tarihi" alanlarının dolu olduğundan emin olun.'
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void exportContracts(BuildContext context, List<Map<String, dynamic>> contracts) {
    // Check if user is authenticated
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showInfoCard(
        context,
        tr('common_login_required'), // 'Oturum açmanız gerekiyor'
        Colors.red,
        icon: Icons.error,
      );
      return;
    }
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Fetch actual contracts from Firestore
    _firestoreService.fetchContracts(userId: currentUser.uid)
      .then((contractsList) {
        // Close loading dialog
        Navigator.pop(context);
        
        if (contractsList.isEmpty) {
          _showInfoCard(
            context,
            tr('contracts_export_no_contracts'), // 'Dışa aktarılacak sözleşme bulunamadı.'
            Colors.orange,
            icon: Icons.warning,
          );
          return;
        }
        
        try {
          // Log the number of contracts being exported (for debugging)
          debugPrint(tr('contracts_export_debug_count', args: [contractsList.length.toString()])); // 'Dışa aktarılacak sözleşme sayısı: ${contractsList.length}'
          
          // Create an Excel workbook
          final excel = excel_package.Excel.createExcel();
            
          // Create sheet for contracts and set as default
          final sheet = excel[tr('contracts_export_sheet_name')]; // 'Sözleşmeler'
          excel.setDefaultSheet(tr('contracts_export_sheet_name')); // 'Sözleşmeler'
          
          // Add headers (EKLENDİ: Çalışan Adı, Araç ID, Oluşturulma Tarihi)
          sheet.appendRow([
            tr('contracts_column_employee'), // 'Çalışan'
            tr('contracts_column_employee_name'), // 'Çalışan Adı'
            tr('contracts_column_vehicle_id'), // 'Araç ID'
            tr('contracts_column_type'), // 'Sözleşme Türü'
            tr('contracts_column_start_date'), // 'Başlangıç Tarihi'
            tr('contracts_column_end_date'), // 'Bitiş Tarihi'
            tr('contracts_column_status'), // 'Durum'
            tr('contracts_column_created_at'), // 'Oluşturulma Tarihi'
          ]);
      
          // Add contract data (EKLENDİ: employeeName, vehicleId, createdAt)
          int exportedCount = 0;
          for (var contract in contractsList) {
            enums.ContractStatus actualStatus = _mapModelStatusToEnums(contract.status);
            String statusText = _getStatusText(
              actualStatus,
              contract: contract,
            );
            if (actualStatus == enums.ContractStatus.ongoing && 
                DateTime.now().isAfter(contract.endDate) &&
                statusText == tr('contracts_status_active')) {
              statusText = tr('contracts_status_completed');
            }
            sheet.appendRow([
              contract.employeeId,
              contract.employeeName,
              contract.vehicleId,
              contract.reference,
              _formatDate(contract.startDate),
              _formatDate(contract.endDate),
              statusText,
              _formatDate(contract.createdAt),
            ]);
            exportedCount++;
          }
      
          // Generate Excel file bytes
          final bytes = excel.encode();
          if (bytes != null) {
            // Create blob and download link
            final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
            final url = html.Url.createObjectUrlFromBlob(blob);
            
            // Create an anchor element with download attribute to properly trigger the download
            html.AnchorElement(href: url)
              ..setAttribute('download', '${tr('contracts_export_filename')}_${DateTime.now().millisecondsSinceEpoch}.xlsx') // 'Sozlesmeler'
              ..click();
              
            // Clean up the URL object after download starts
            html.Url.revokeObjectUrl(url);
            
            _showInfoCard(
              context,
              tr('contracts_export_success', args: [exportedCount.toString()]), // '$exportedCount sözleşme başarıyla dışa aktarıldı.'
              Colors.green,
              icon: Icons.check_circle,
            );
          } else {
            throw Exception(tr('contracts_export_file_creation_error')); // 'Dosya oluşturulurken bir hata oluştu.'
          }
        } catch (e) {
          _showInfoCard(
            context,
            tr('contracts_export_error', args: [e.toString()]), // 'Dışa aktarma işlemi sırasında bir hata oluştu: ${e.toString()}'
            Colors.red,
            icon: Icons.error,
          );
        }
      })
      .catchError((error) {
        // Close loading dialog
        Navigator.pop(context);
        
        _showInfoCard(
          context,
          tr('contracts_fetch_error', args: [error.toString()]), // 'Sözleşmeler alınırken bir hata oluştu: ${error.toString()}'
          Colors.red,
          icon: Icons.error,
        );
      });
  }
  
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
  
  // Yeni: Sözleşme durumunu Excel için uygun şekilde döndür
  static String _getStatusText(enums.ContractStatus status, {Contract? contract}) {
    // Eğer contract parametresi verilmişse, bitiş tarihi ve bugüne göre yakında bitecek kontrolü yap
    if (contract != null) {
      final now = DateTime.now();
      final oneMonthFromNow = now.add(const Duration(days: 30));
      final twoMonthsFromNow = now.add(const Duration(days: 60));
      // Sözleşme bitmemiş ve 1 ay içinde bitiyorsa
      if (contract.endDate.isAfter(now) && contract.endDate.isBefore(oneMonthFromNow)) {
        return tr('contracts_status_expiring_soon'); // 'Yakında Bitecek'
      }
      // Sözleşme bitmemiş ve 2 ay içinde bitiyorsa
      if (contract.endDate.isAfter(now) && contract.endDate.isBefore(twoMonthsFromNow)) {
        return tr('contracts_status_expiring_soon'); // 'Yakında Bitecek'
      }
    }
    // Standart durumlar
    switch (status) {
      case enums.ContractStatus.ongoing:
        return tr('contracts_status_active'); // 'Aktif'
      case enums.ContractStatus.completed:
        return tr('contracts_status_completed'); // 'Tamamlandı'
      case enums.ContractStatus.terminated:
        return tr('contracts_status_terminated'); // 'Feshedildi'
      default:
        return tr('contracts_status_active'); // 'Aktif'
    }
  }
  
  static enums.ContractStatus _parseStatusText(String statusText) {
    if (statusText.toLowerCase() == tr('contracts_status_completed').toLowerCase() ||
        statusText.toLowerCase() == 'completed' ||
        statusText.toLowerCase() == tr('contracts_status_ended').toLowerCase() ||
        statusText.toLowerCase() == tr('contracts_status_expired').toLowerCase()) {
      return enums.ContractStatus.completed;
    } else if (statusText.toLowerCase() == tr('contracts_status_terminated').toLowerCase() ||
        statusText.toLowerCase() == 'terminated' ||
        statusText.toLowerCase() == tr('contracts_status_cancelled').toLowerCase()) {
      return enums.ContractStatus.terminated;
    } else {
      return enums.ContractStatus.ongoing;
    }
  }

  // Helper to map models.ContractStatus to enums.ContractStatus
  static enums.ContractStatus _mapModelStatusToEnums(ContractStatus status) {
    switch (status) {
      case ContractStatus.ongoing:
        return enums.ContractStatus.ongoing;
      case ContractStatus.expired:
        return enums.ContractStatus.completed;
      case ContractStatus.terminated:
        return enums.ContractStatus.terminated;
      case ContractStatus.renewed:
        return enums.ContractStatus.ongoing;
      default:
        return enums.ContractStatus.ongoing;
    }
  }

  // Helper to map enums.ContractStatus to models.ContractStatus
  static ContractStatus _mapEnumsStatusToModel(enums.ContractStatus statusEnum) {
    switch (statusEnum) {
      case enums.ContractStatus.ongoing:
        return ContractStatus.ongoing;
      case enums.ContractStatus.completed:
        return ContractStatus.expired;
      case enums.ContractStatus.terminated:
        return ContractStatus.terminated;
      default:
        return ContractStatus.ongoing;
    }
  }

  static void _downloadContractTemplate(BuildContext context) {
    // Define column headers for the template (EKLENDİ: Çalışan Adı, Araç ID, Oluşturulma Tarihi)
    List<String> headers = [
      tr('contracts_column_employee'), // 'Çalışan'
      tr('contracts_column_employee_name'), // 'Çalışan Adı'
      tr('contracts_column_vehicle_id'), // 'Araç ID'
      tr('contracts_column_type'), // 'Sözleşme Türü'
      tr('contracts_column_start_date'), // 'Başlangıç Tarihi'
      tr('contracts_column_end_date'),  // 'Bitiş Tarihi'
      tr('contracts_column_status'), // 'Durum'
      tr('contracts_column_created_at'), // 'Oluşturulma Tarihi'
    ];

    // Define an example row with sample data (EKLENDİ: employeeName, vehicleId, createdAt)
    List<String> exampleData = [
      tr('contracts_template_example_id'), // 'EMP001'
      tr('contracts_template_example_name'), // 'Ahmet Yılmaz'
      tr('contracts_template_example_vehicle_id'), // 'VH001'
      tr('contracts_template_example_type'), // 'Tam Zamanlı'
      tr('contracts_template_example_start_date'), // '01.01.2023'
      tr('contracts_template_example_end_date'),  // '01.01.2024'
      tr('contracts_status_active'), // 'Aktif'
      tr('contracts_template_example_created_at'), // '01.01.2023'
    ];
    
    // Create an Excel workbook
    final excel = excel_package.Excel.createExcel();
    final sheet = excel[tr('contracts_template_sheet_name')]; // 'Sözleşme Şablonu'
    excel.setDefaultSheet(tr('contracts_template_sheet_name')); // 'Sözleşme Şablonu'
    sheet.appendRow(headers);
    sheet.appendRow(exampleData);
    
    // Generate Excel file bytes
    final bytes = excel.encode();
    if (bytes != null) {
      // Create blob and download link
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Create an anchor element with download attribute to trigger the download
      html.AnchorElement(href: url)
        ..setAttribute('download', tr('contracts_template_filename')) // 'Sozlesme_Sablonu.xlsx'
        ..click();
        
      // Clean up the URL object after download starts
      html.Url.revokeObjectUrl(url);
      
      _showInfoCard(
        context,
        tr('contracts_template_download_success'), // 'Sözleşme şablonu indirildi.'
        Colors.green,
        icon: Icons.check_circle,
      );
    } else {
      _showInfoCard(
        context,
        tr('contracts_template_error'), // 'Şablon oluşturulurken bir hata oluştu.'
        Colors.red,
        icon: Icons.error,
      );
    }
  }
  
  static void _selectAndUploadFile(BuildContext context, Function refreshContracts) {
    final input = html.FileUploadInputElement()
      ..accept = '.csv,.xlsx,.xls'
      ..click();
    
    input.onChange.listen((event) {
      if (input.files != null && input.files!.isNotEmpty) {
        final file = input.files!.first;
        final reader = html.FileReader();
        final fileExt = file.name.split('.').last.toLowerCase();
        
        reader.onLoadEnd.listen((e) {
          if (reader.result != null) {
            if (fileExt == 'csv') {
              final csvData = reader.result as String;
              _parseCsvDataAndAddContracts(context, csvData, refreshContracts);
            } else if (fileExt == 'xlsx' || fileExt == 'xls') {
              // Handle Excel files
              final excelData = reader.result as Uint8List;
              _parseExcelDataAndAddContracts(context, excelData, refreshContracts);
            } else {
              _showInfoCard(
                context,
                tr('contracts_import_unsupported_format'), // 'Desteklenmeyen dosya formatı. Lütfen Excel veya CSV dosyası yükleyin.'
                Colors.orange,
                icon: Icons.warning,
              );
            }
          }
        });
        
        if (fileExt == 'csv') {
          reader.readAsText(file);
        } else {
          reader.readAsArrayBuffer(file);
        }
      }
    });
  }

  static Future<void> _parseExcelDataAndAddContracts(BuildContext context, Uint8List bytes, Function refreshContracts) async {
    try {
      // Check if user is authenticated
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showInfoCard(
          context,
          tr('common_login_required'), // 'Oturum açmanız gerekiyor'
          Colors.red,
          icon: Icons.error,
        );
        return;
      }
      
      _showInfoCard(
        context,
        tr('contracts_import_processing_excel'), // 'Excel dosyası işleniyor...'
        Colors.blue,
        icon: Icons.hourglass_top,
        duration: const Duration(seconds: 2),
      );
      
      // Use the Excel package to decode the file
      final excel = excel_package.Excel.decodeBytes(bytes);
      
      if (excel.tables.isEmpty) {
        _showExcelErrorDialog(context, tr('contracts_import_excel_empty'), tr('contracts_import_file_read_error')); // 'Excel dosyası boş veya okunamıyor.', 'Dosya Okuma Hatası'
        return;
      }
      
      // Get the first sheet
      final sheet = excel.tables.entries.first.value;
      final rows = sheet.rows;
      
      if (rows.isEmpty) {
        _showExcelErrorDialog(context, tr('contracts_import_no_data'), tr('contracts_import_no_data_found')); // 'Excel dosyasında veri bulunamadı.', 'Veri Bulunamadı'
        return;
      }
      
      // Validate header row (EN AZ 6 alan bekleniyor)
      final headerRow = rows[0];
      if (headerRow.length < 6 || 
          headerRow[0]?.value?.toString() == null ||
          headerRow[1]?.value?.toString() == null ||
          headerRow[2]?.value?.toString() == null ||
          headerRow[3]?.value?.toString() == null ||
          headerRow[4]?.value?.toString() == null ||
          headerRow[5]?.value?.toString() == null) {
        _showExcelErrorDialog(
          context, 
          tr('contracts_import_invalid_headers'),
          tr('contracts_import_invalid_headers_title')
        );
        return;
      }
      
      // Collect errors during import
      List<String> errorRows = [];
      int skippedRows = 0;
      
      // Skip the header row and process data rows
      int importedCount = 0;
      List<Contract> contractsToImport = [];
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        
        // Skip empty rows
        if (row.isEmpty || row[0]?.value == null) {
          skippedRows++;
          continue;
        }
        
        try {
          // Extract values, handle nulls properly (EKLENDİ: employeeName, vehicleId, createdAt)
          final employee = row[0]?.value?.toString() ?? '';
          final employeeName = row.length > 1 ? row[1]?.value?.toString() ?? '' : '';
          final vehicleId = row.length > 2 ? row[2]?.value?.toString() ?? '' : '';
          final type = row.length > 3 ? row[3]?.value?.toString() ?? '' : '';
          final startDateStr = row.length > 4 ? row[4]?.value?.toString() ?? '' : '';
          final endDateStr = row.length > 5 ? row[5]?.value?.toString() ?? '' : '';
          String statusText = row.length > 6 ? row[6]?.value?.toString() ?? tr('contracts_status_active') : tr('contracts_status_active');
          final createdAtStr = row.length > 7 ? row[7]?.value?.toString() ?? '' : '';

          // Skip if required fields are empty
          if (employee.isEmpty || type.isEmpty || startDateStr.isEmpty || endDateStr.isEmpty) {
            errorRows.add(tr('contracts_import_row_missing_fields', args: [(i+1).toString()]));
            continue;
          }

          // Parse dates
          DateTime? startDate = _parseDateFromString(startDateStr);
          DateTime? endDate = _parseDateFromString(endDateStr);
          DateTime? createdAt = createdAtStr.isNotEmpty ? _parseDateFromString(createdAtStr) : null;

          if (startDate == null || endDate == null) {
            errorRows.add(tr('contracts_import_row_invalid_date', args: [(i+1).toString()]));
            continue;
          }
          if (startDate.isAfter(endDate)) {
            errorRows.add(tr('contracts_import_row_date_error', args: [(i+1).toString(), _formatDate(startDate), _formatDate(endDate)]));
            continue;
          }
          enums.ContractStatus statusEnum = _parseStatusText(statusText);
          ContractStatus contractStatus = _mapEnumsStatusToModel(statusEnum);

          final contractId = uuid.v4();
          final contract = Contract(
            id: contractId,
            employeeId: employee,
            employeeName: employeeName.isNotEmpty ? employeeName : employee,
            vehicleId: vehicleId,
            reference: type,
            startDate: startDate,
            endDate: endDate,
            status: contractStatus,
            createdAt: createdAt,
          );
          contractsToImport.add(contract);
          importedCount++;
        } catch (rowError) {
          errorRows.add(tr('contracts_import_row_processing_error', args: [(i+1).toString(), rowError.toString()]));
        }
      }
      
      // Save contracts to Firestore if there are any to import
      if (contractsToImport.isNotEmpty) {
        try {
          // Import contracts one by one (a batch write would be more efficient in a production app)
          for (var contract in contractsToImport) {
            await _firestoreService.addContract(contract, currentUser.uid);
          }
          
          // Close loading dialog
          Navigator.pop(context);
          
          // Reload contracts after import
          refreshContracts();
          
          // Show appropriate message based on import results
          if (errorRows.isEmpty) {
            _showInfoCard(
              context,
              tr('contracts_import_success', args: [importedCount.toString()]), // '$importedCount sözleşme başarıyla içe aktarıldı.'
              Colors.green,
              icon: Icons.check_circle,
            );
          } else {
            _showImportSummary(context, importedCount, errorRows, skippedRows);
          }
        } catch (importError) {
          // Close loading dialog
          Navigator.pop(context);
          
          _showExcelErrorDialog(
            context,
            tr('contracts_import_save_error'), // 'Sözleşmeler kaydedilirken bir hata oluştu.'
            tr('contracts_import_save_error_title'), // 'Kaydetme Hatası'
            errorDetails: importError.toString()
          );
        }
      } else {
        // Close loading dialog
        Navigator.pop(context);
        
        if (errorRows.isEmpty) {
          _showInfoCard(
            context,
            tr('contracts_import_no_valid_contracts'), // 'İçe aktarılacak geçerli sözleşme bulunamadı.'
            Colors.orange,
            icon: Icons.warning,
          );
        } else {
          _showExcelErrorDialog(
            context,
            tr('contracts_import_errors_occurred'), // 'İçe aktarma işlemi sırasında hatalar oluştu.'
            tr('contracts_import_failed'), // 'İçe Aktarma Başarısız'
            errorDetails: errorRows.join('\n')
          );
        }
      }
    } catch (e) {
      // Ensure we close the loading dialog if an error occurs
      try {
        Navigator.pop(context);
      } catch (_) {}
      
      _showExcelErrorDialog(
        context,
        tr('contracts_import_excel_processing_error'), // 'Excel dosyası işlenirken bir hata oluştu.'
        tr('contracts_import_excel_error'), // 'Excel İşleme Hatası'
        errorDetails: e.toString()
      );
    }
  }
  
  // Helper method to parse date from various string formats
  static DateTime? _parseDateFromString(String dateStr) {
    try {
      // Try DD.MM.YYYY format
      if (dateStr.contains('.')) {
        final parts = dateStr.split('.');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0].trim());
          final month = int.tryParse(parts[1].trim());
          final year = int.tryParse(parts[2].trim());
          
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      }
      
      // Try YYYY-MM-DD format
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final year = int.tryParse(parts[0].trim());
          final month = int.tryParse(parts[1].trim());
          final day = int.tryParse(parts[2].trim());
          
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      }
      
      // Try MM/DD/YYYY format
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final month = int.tryParse(parts[0].trim());
          final day = int.tryParse(parts[1].trim());
          final year = int.tryParse(parts[2].trim());
          
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      }
      
      // Try to parse as ISO date
      return DateTime.tryParse(dateStr);
    } catch (e) {
      return null;
    }
  }

  static Future<void> _parseCsvDataAndAddContracts(BuildContext context, String csvData, Function refreshContracts) async {
    try {
      // Check if user is authenticated
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showInfoCard(
          context,
          tr('common_login_required'), // 'Oturum açmanız gerekiyor'
          Colors.red,
          icon: Icons.error,
        );
        return;
      }
      
      _showInfoCard(
        context,
        tr('contracts_import_processing_csv'), // 'CSV dosyası işleniyor...'
        Colors.blue,
        icon: Icons.hourglass_top,
        duration: const Duration(seconds: 2),
      );
      
      final lines = csvData.split('\n');
      if (lines.isEmpty) {
        _showExcelErrorDialog(context, tr('contracts_import_csv_empty'), tr('contracts_import_file_read_error')); // 'CSV dosyası boş veya okunamıyor.', 'Dosya Okuma Hatası'
        return;
      }

      // Collect errors during import
      List<String> errorRows = [];
      int skippedRows = 0;
      int importedCount = 0;
      List<Contract> contractsToImport = [];
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Skip header row and process data rows
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) {
          skippedRows++;
          continue;
        }
        try {
          final fields = line.split(',');
          // EN AZ 6 alan bekleniyor
          if (fields.length < 6 || 
              fields[0].trim().isEmpty || 
              fields[3].trim().isEmpty || 
              fields[4].trim().isEmpty || 
              fields[5].trim().isEmpty) {
            errorRows.add(tr('contracts_import_row_missing_fields', args: [(i+1).toString()])); // 'Satır ${i+1}: Zorunlu alanlar eksik'
            continue;
          }
          final employee = fields[0].trim();
          final employeeName = fields.length > 1 ? fields[1].trim() : '';
          final vehicleId = fields.length > 2 ? fields[2].trim() : '';
          final type = fields.length > 3 ? fields[3].trim() : '';
          final startDateStr = fields.length > 4 ? fields[4].trim() : '';
          final endDateStr = fields.length > 5 ? fields[5].trim() : '';
          String statusText = fields.length > 6 ? fields[6].trim() : tr('contracts_status_active');
          final createdAtStr = fields.length > 7 ? fields[7].trim() : '';

          DateTime? startDate = _parseDateFromString(startDateStr);
          DateTime? endDate = _parseDateFromString(endDateStr);
          DateTime? createdAt = createdAtStr.isNotEmpty ? _parseDateFromString(createdAtStr) : null;

          if (startDate == null || endDate == null) {
            errorRows.add(tr('contracts_import_row_invalid_date', args: [(i+1).toString()])); // 'Satır ${i+1}: Geçersiz tarih formatı'
            continue;
          }
          if (startDate.isAfter(endDate)) {
            errorRows.add(tr('contracts_import_row_date_error', args: [(i+1).toString(), _formatDate(startDate), _formatDate(endDate)])); // 'Satır ${i+1}: Başlangıç tarihi (${_formatDate(startDate)}) bitiş tarihinden (${_formatDate(endDate)}) sonra olamaz'
            continue;
          }
          enums.ContractStatus statusEnum = _parseStatusText(statusText);
          ContractStatus contractStatus = _mapEnumsStatusToModel(statusEnum);

          final contractId = uuid.v4();
          final contract = Contract(
            id: contractId,
            employeeId: employee,
            employeeName: employeeName.isNotEmpty ? employeeName : employee,
            vehicleId: vehicleId,
            reference: type,
            startDate: startDate,
            endDate: endDate,
            status: contractStatus,
            createdAt: createdAt,
          );
          contractsToImport.add(contract);
          importedCount++;
        } catch (rowError) {
          errorRows.add(tr('contracts_import_row_processing_error', args: [(i+1).toString(), rowError.toString()])); // 'Satır ${i+1} işlenirken hata oluştu: ${rowError.toString()}'
        }
      }
      // Save contracts to Firestore if there are any to import
      if (contractsToImport.isNotEmpty) {
        try {
          // Import contracts one by one (a batch write would be more efficient in a production app)
          for (var contract in contractsToImport) {
            await _firestoreService.addContract(contract, currentUser.uid);
          }
          
          // Close loading dialog
          Navigator.pop(context);
          
          // Reload contracts after import
          refreshContracts();
          
          // Show appropriate message based on import results
          if (errorRows.isEmpty) {
            _showInfoCard(
              context,
              tr('contracts_import_success', args: [importedCount.toString()]), // '$importedCount sözleşme başarıyla içe aktarıldı.'
              Colors.green,
              icon: Icons.check_circle,
            );
          } else {
            _showImportSummary(context, importedCount, errorRows, skippedRows);
          }
        } catch (importError) {
          // Close loading dialog
          Navigator.pop(context);
          
          _showExcelErrorDialog(
            context,
            tr('contracts_import_save_error'), // 'Sözleşmeler kaydedilirken bir hata oluştu.'
            tr('contracts_import_save_error_title'), // 'Kaydetme Hatası'
            errorDetails: importError.toString()
          );
        }
      } else {
        // Close loading dialog
        Navigator.pop(context);
        
        if (errorRows.isEmpty) {
          _showInfoCard(
            context,
            tr('contracts_import_no_valid_contracts'), // 'İçe aktarılacak geçerli sözleşme bulunamadı.'
            Colors.orange,
            icon: Icons.warning,
          );
        } else {
          _showExcelErrorDialog(
            context,
            tr('contracts_import_errors_occurred'), // 'İçe aktarma işlemi sırasında hatalar oluştu.'
            tr('contracts_import_failed'), // 'İçe Aktarma Başarısız'
            errorDetails: errorRows.join('\n')
          );
        }
      }
    } catch (e) {
      // Ensure we close the loading dialog if an error occurs
      try {
        Navigator.pop(context);
      } catch (_) {}
      
      _showExcelErrorDialog(
        context,
        tr('contracts_import_csv_processing_error'), // 'CSV dosyası işlenirken bir hata oluştu.'
        tr('contracts_import_csv_error'), // 'CSV İşleme Hatası'
        errorDetails: e.toString()
      );
    }
  }

  static void _showExcelErrorDialog(BuildContext context, String message, String title, {String? errorDetails}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (errorDetails != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  errorDetails,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('common_ok')), // 'Tamam'
          ),
        ],
      ),
    );
  }

  static void _showImportSummary(BuildContext context, int importedCount, List<String> errorRows, int skippedRows) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Text(tr('contracts_import_summary_title')), // 'İçe Aktarma Özeti'
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('contracts_import_summary_success', args: [importedCount.toString()])), // '$importedCount sözleşme başarıyla içe aktarıldı.'
            if (skippedRows > 0)
              Text(tr('contracts_import_summary_skipped', args: [skippedRows.toString()])), // '$skippedRows boş satır atlandı.'
            if (errorRows.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(tr('contracts_import_summary_errors')), // 'İşlenemeyen satırlar:'
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  errorRows.join('\n'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('common_ok')), // 'Tamam'
          ),
        ],
      ),
    );
  }
  
  static void _showInfoCard(
    BuildContext context,
    String message,
    Color color, {
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    InfoCard.showInfoCard(
      context,
      message,
      color,
      icon: icon ?? Icons.info,
      duration: duration,
    );
  }
}
  
  void _showInfoCard(
    BuildContext context,
    String message,
    Color color, {
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    InfoCard.showInfoCard(
      context,
      message,
      color,
      icon: icon ?? Icons.info,
      duration: duration,
    );
  }
