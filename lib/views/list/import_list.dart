import 'package:fleet/models/employee.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:excel/excel.dart' as excel_package;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/employee_service.dart';
import '../../../info_card.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/enums.dart'; // Import for EmploymentStatus enum

class EmployeeImportExport {
  static final EmployeeService _employeeService = EmployeeService();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final uuid = Uuid();

  // Add helper method to convert string status to EmploymentStatus enum
  static EmploymentStatus _getEmploymentStatusFromString(String statusStr) {
    try {
      switch (statusStr.toLowerCase()) {
        case 'onleave':
          return EmploymentStatus.onLeave;
        case 'terminated':
          return EmploymentStatus.terminated;
        case 'active':
        default:
          return EmploymentStatus.active;
      }
    } catch (e) {
      developer.log('Error converting status string to enum: ${e.toString()}', 
          name: 'EmployeeImportExport', error: e);
      return EmploymentStatus.active; // Default to active on error
    }
  }

  static void importEmployees(BuildContext context, Function refreshCallback) {
    try {
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
                          'import_list_title'.tr(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'import_list_subtitle'.tr(),
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
                            'import_list_template_download'.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'import_list_template_desc',
                        style: TextStyle(fontSize: 14),
                      ).tr(),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('import_list_template_download_btn').tr(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _downloadEmployeeTemplate(context),
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
                            'import_list_upload_title'.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'import_list_upload_desc',
                        style: TextStyle(fontSize: 14),
                      ).tr(),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.file_upload),
                          label: const Text('import_list_upload_btn').tr(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _selectAndUploadFile(context, refreshCallback);
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
                        child: const Text(
                          'import_list_note',
                          style: TextStyle(fontSize: 13),
                        ).tr(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      developer.log('Error in importEmployees: ${e.toString()}', name: 'EmployeeImportExport');
      _showInfoCard(
        context,
        'import_list_import_screen_error'.tr(),
        Colors.red,
        icon: Icons.error,
      );
    }
  }

  static void exportEmployees(BuildContext context, List<dynamic> employees) {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Get the current user ID - needed for Firebase query
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        // Close loading dialog
        Navigator.pop(context);
        
        _showInfoCard(
          context,
          'import_list_login_required'.tr(),
          Colors.red,
          icon: Icons.error,
        );
        return;
      }

      // Fetch fresh employee data directly from Firestore
      _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('employees')
          .get()
          .then((querySnapshot) {
            try {
              // Close loading dialog
              Navigator.pop(context);
              
              // Check if there are employees to export
              if (querySnapshot.docs.isEmpty) {
                _showInfoCard(
                  context,
                  'import_list_no_employees_to_export'.tr(),
                  Colors.orange,
                  icon: Icons.warning,
                );
                return;
              }
              
              // Create an Excel workbook
              final excel = excel_package.Excel.createExcel();
              developer.log('Excel workbook created successfully', name: 'EmployeeImportExport');
              
              // Create sheet for employees and set as default
              final sheet = excel['Çalışanlar'];
              excel.setDefaultSheet('Çalışanlar');
              
              // Add headers
              sheet.appendRow([
                'Ad Soyad',
                'Pozisyon',
                'Departman',
                'Durum',
                'E-posta',
                'Telefon',
              ]);
              
              // Add employee data from Firebase
              int exportedCount = 0;
              
              for (var doc in querySnapshot.docs) {
                try {
                  final data = doc.data();
                  
                  // Get department name if available
                  String departmentName = data['departmentId'] ?? '';
                  if (departmentName.isNotEmpty) {
                    try {
                      // Try to look up department name
                      _getDepartmentName(currentUser.uid, departmentName).then((name) {
                        if (name.isNotEmpty) {
                          departmentName = name;
                        }
                      });
                    } catch (deptError) {
                      developer.log('Error fetching department name: ${deptError.toString()}', 
                          name: 'EmployeeImportExport', error: deptError);
                    }
                  }
                  
                  // Add row to Excel
                  sheet.appendRow([
                    data['name'] ?? '',
                    data['position'] ?? '',
                    departmentName,
                    _getStatusText(data['status']?.toString() ?? 'active'),
                    data['email'] ?? '',
                    data['phone'] ?? '',
                  ]);
                  
                  exportedCount++;
                } catch (docError) {
                  developer.log('Error processing employee document: ${docError.toString()}', 
                      name: 'EmployeeImportExport', error: docError);
                }
              }
              
              // Generate Excel file bytes
              final bytes = excel.encode();
              if (bytes != null) {
                try {
                  // Create blob and download link
                  final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
                  final url = html.Url.createObjectUrlFromBlob(blob);
                  
                  // Create an anchor element with download attribute to properly trigger the download
                  html.AnchorElement(href: url)
                    ..setAttribute('download', 'Calisanlar_${DateTime.now().millisecondsSinceEpoch}.xlsx')
                    ..click();
                    
                  // Clean up the URL object after download starts
                  html.Url.revokeObjectUrl(url);
                  
                  _showInfoCard(
                    context,
                    'import_list_export_success'.tr(args: ['$exportedCount']),
                    Colors.green,
                    icon: Icons.check_circle,
                  );
                } catch (downloadError) {
                  developer.log('Error triggering download: ${downloadError.toString()}', 
                      name: 'EmployeeImportExport', error: downloadError);
                  _showInfoCard(
                    context,
                    'import_list_download_failed'.tr(),
                    Colors.red,
                    icon: Icons.error,
                  );
                }
              } else {
                _showInfoCard(
                  context,
                  'import_list_excel_create_failed'.tr(),
                  Colors.red,
                  icon: Icons.error,
                );
              }
            } catch (exportError) {
              // Close loading dialog if still open
              try {
                Navigator.pop(context);
              } catch (_) {}
              
              developer.log('Error during export process: ${exportError.toString()}', 
                  name: 'EmployeeImportExport', error: exportError);
              _showInfoCard(
                context,
                'import_list_export_error'.tr(args: [exportError.toString()]),
                Colors.red,
                icon: Icons.error,
              );
            }
          })
          .catchError((error) {
            // Close loading dialog
            Navigator.pop(context);
            
            developer.log('Firebase fetch error: ${error.toString()}', 
                name: 'EmployeeImportExport', error: error);
            _showInfoCard(
              context,
              'import_list_firestore_fetch_error'.tr(args: [error.toString()]),
              Colors.red,
              icon: Icons.error,
            );
          });
    } catch (e) {
      // Close loading dialog if open
      try {
        Navigator.pop(context);
      } catch (_) {}
      
      // Show detailed error information
      _showInfoCard(
        context,
        'import_list_export_start_failed'.tr(args: [e.toString()]),
        Colors.red,
        icon: Icons.error,
      );
      
      developer.log('Export error: ${e.toString()}', name: 'EmployeeImportExport', error: e);
    }
  }
  
  // Helper method to get department name from ID
  static Future<String> _getDepartmentName(String userId, String departmentId) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('departments')
          .doc(departmentId)
          .get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('name')) {
          return data['name'] as String;
        }
      }
    } catch (e) {
      developer.log('Error getting department name: ${e.toString()}', 
          name: 'EmployeeImportExport', error: e);
    }
    return departmentId; // Return the ID if name can't be fetched
  }
  
  static String _getStatusText(String status) {
    try {
      switch (status) {
        case 'active':
          return 'import_list_status_active'.tr();
        case 'onLeave':
          return 'import_list_status_onleave'.tr();
        case 'terminated':
          return 'import_list_status_terminated'.tr();
        default:
          return 'import_list_status_active'.tr();
      }
    } catch (e) {
      developer.log('Error in _getStatusText: ${e.toString()}', name: 'EmployeeImportExport', error: e);
      return 'import_list_status_active'.tr(); // Default fallback
    }
  }
  
  static String _parseStatusText(String statusText) {
    try {
      switch (statusText.toLowerCase()) {
        case 'izinli':
        case 'on leave':
        case 'izinde':
          return 'onLeave';
        case 'işten ayrılmış':
        case 'terminated':
        case 'ayrıldı':
        case 'işten çıktı':
          return 'terminated';
        case 'aktif':
        case 'active':
        case 'çalışıyor':
        default:
          return 'active';
      }
    } catch (e) {
      developer.log('Error in _parseStatusText: ${e.toString()}', name: 'EmployeeImportExport', error: e);
      return 'active'; // Default fallback
    }
  }

  static void _downloadEmployeeTemplate(BuildContext context) {
    try {
      // Define column headers for the template
      List<String> headers = [
        'import_list_header_name'.tr(),
        'import_list_header_position'.tr(),
        'import_list_header_department'.tr(),
        'import_list_header_status'.tr(),
        'import_list_header_email'.tr(),
        'import_list_header_phone'.tr(),
      ];
      
      // Define an example row with sample data
      List<String> exampleData = [
        'import_list_example_name'.tr(),
        'import_list_example_position'.tr(),
        'import_list_example_department'.tr(),
        'import_list_example_status'.tr(),
        'import_list_example_email'.tr(),
        'import_list_example_phone'.tr(),
      ];
      
      try {
        // Create an Excel workbook
        final excel = excel_package.Excel.createExcel();
        final sheet = excel['Çalışan Şablonu'];
        excel.setDefaultSheet('Çalışan Şablonu');
        
        // Add headers
        sheet.appendRow(headers);
        
        // Add example data
        sheet.appendRow(exampleData);
        
        try {
          // Generate Excel file bytes
          final bytes = excel.encode();
          if (bytes != null) {
            try {
              // Create blob and download link
              final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
              final url = html.Url.createObjectUrlFromBlob(blob);
              
              try {
                // Create an anchor element with download attribute to trigger the download
                html.AnchorElement(href: url)
                  ..setAttribute('download', 'Calisan_Sablonu.xlsx')
                  ..click();
                  
                // Clean up the URL object after download starts
                html.Url.revokeObjectUrl(url);
              } catch (downloadError) {
                developer.log('Error downloading template: ${downloadError.toString()}', name: 'EmployeeImportExport', error: downloadError);
                throw Exception('import_list_template_download_failed'.tr(args: [downloadError.toString()]));
              }
              
              _showInfoCard(
                context,
                'import_list_template_downloaded'.tr(),
                Colors.green,
                icon: Icons.check_circle,
              );
            } catch (blobError) {
              developer.log('Error creating template blob: ${blobError.toString()}', name: 'EmployeeImportExport', error: blobError);
              throw Exception('import_list_template_blob_failed'.tr(args: [blobError.toString()]));
            }
          } else {
            developer.log('Excel template encode returned null', name: 'EmployeeImportExport');
            throw Exception('import_list_template_encode_failed'.tr());
          }
        } catch (encodeError) {
          developer.log('Error encoding Excel template: ${encodeError.toString()}', name: 'EmployeeImportExport', error: encodeError);
          throw Exception('import_list_template_create_failed'.tr(args: [encodeError.toString()]));
        }
      } catch (excelError) {
        developer.log('Excel template creation error: ${excelError.toString()}', name: 'EmployeeImportExport', error: excelError);
        throw Exception('import_list_template_create_failed'.tr(args: [excelError.toString()]));
      }
    } catch (e) {
      developer.log('Template download error: ${e.toString()}', name: 'EmployeeImportExport', error: e);
      _showInfoCard(
        context,
        'import_list_template_create_error'.tr(args: [e.toString()]),
        Colors.red,
        icon: Icons.error,
      );
    }
  }
  
  static void _selectAndUploadFile(BuildContext context, Function refreshCallback) {
    try {
      final input = html.FileUploadInputElement()
        ..accept = '.csv,.xlsx,.xls'
        ..click();
      
      input.onChange.listen((event) {
        try {
          if (input.files != null && input.files!.isNotEmpty) {
            try {
              final file = input.files!.first;
              final reader = html.FileReader();
              final fileExt = file.name.split('.').last.toLowerCase();
              
              try {
                reader.onLoadEnd.listen((e) {
                  try {
                    if (reader.result != null) {
                      if (fileExt == 'csv') {
                        try {
                          final csvData = reader.result as String;
                          _parseCsvDataAndAddEmployees(context, csvData, refreshCallback);
                        } catch (csvError) {
                          developer.log('CSV parsing error: ${csvError.toString()}', name: 'EmployeeImportExport', error: csvError);
                          _showInfoCard(
                            context,
                            'import_list_csv_read_error'.tr(args: [csvError.toString()]),
                            Colors.red,
                            icon: Icons.error,
                          );
                        }
                      } else if (fileExt == 'xlsx' || fileExt == 'xls') {
                        try {
                          // Handle Excel files
                          final excelData = reader.result as Uint8List;
                          _parseExcelDataAndAddEmployees(context, excelData, refreshCallback);
                        } catch (excelError) {
                          developer.log('Excel parsing error: ${excelError.toString()}', name: 'EmployeeImportExport', error: excelError);
                          _showInfoCard(
                            context,
                            'import_list_excel_read_error'.tr(args: [excelError.toString()]),
                            Colors.red,
                            icon: Icons.error,
                          );
                        }
                      } else {
                        developer.log('Unsupported file format: $fileExt', name: 'EmployeeImportExport');
                        _showInfoCard(
                          context,
                          'import_list_unsupported_file_format'.tr(),
                          Colors.orange,
                          icon: Icons.warning,
                        );
                      }
                    } else {
                      developer.log('File reader returned null result', name: 'EmployeeImportExport');
                      _showInfoCard(
                        context,
                        'import_list_file_read_failed'.tr(),
                        Colors.red,
                        icon: Icons.error,
                      );
                    }
                  } catch (resultError) {
                    developer.log('Error processing file read result: ${resultError.toString()}', name: 'EmployeeImportExport', error: resultError);
                    _showInfoCard(
                      context,
                      'import_list_file_process_error'.tr(args: [resultError.toString()]),
                      Colors.red,
                      icon: Icons.error,
                    );
                  }
                });
                
                if (fileExt == 'csv') {
                  reader.readAsText(file);
                } else {
                  reader.readAsArrayBuffer(file);
                }
              } catch (readerError) {
                developer.log('Error setting up file reader: ${readerError.toString()}', name: 'EmployeeImportExport', error: readerError);
                _showInfoCard(
                  context,
                  'import_list_file_reader_error'.tr(args: [readerError.toString()]),
                  Colors.red,
                  icon: Icons.error,
                );
              }
            } catch (fileError) {
              developer.log('Error accessing file: ${fileError.toString()}', name: 'EmployeeImportExport', error: fileError);
              _showInfoCard(
                context,
                'import_list_file_access_error'.tr(args: [fileError.toString()]),
                Colors.red,
                icon: Icons.error,
              );
            }
          } else {
            developer.log('No file selected', name: 'EmployeeImportExport');
            // Don't show message for no file selection as this is a normal user action
          }
        } catch (eventError) {
          developer.log('Error in file input onChange event: ${eventError.toString()}', name: 'EmployeeImportExport', error: eventError);
          _showInfoCard(
            context,
            'import_list_file_select_error'.tr(args: [eventError.toString()]),
            Colors.red,
            icon: Icons.error,
          );
        }
      });
    } catch (e) {
      developer.log('Error creating file input element: ${e.toString()}', name: 'EmployeeImportExport', error: e);
      _showInfoCard(
        context,
        'import_list_file_input_error'.tr(args: [e.toString()]),
        Colors.red,
        icon: Icons.error,
      );
    }
  }

  static void _parseExcelDataAndAddEmployees(BuildContext context, Uint8List bytes, Function refreshCallback) {
    try {
      // Check if user is authenticated
      try {
        final User? currentUser = _auth.currentUser;
        if (currentUser == null) {
          developer.log('User not authenticated', name: 'EmployeeImportExport');
          _showInfoCard(
            context,
            'import_list_login_required'.tr(),
            Colors.red,
            icon: Icons.error,
          );
          return;
        }
      } catch (authError) {
        developer.log('Authentication check error: ${authError.toString()}', name: 'EmployeeImportExport', error: authError);
        _showInfoCard(
          context,
          'import_list_auth_check_error'.tr(args: [authError.toString()]),
          Colors.red,
          icon: Icons.error,
        );
        return;
      }
      
      _showInfoCard(
        context,
        'import_list_excel_processing'.tr(),
        Colors.blue,
        icon: Icons.hourglass_top,
        duration: const Duration(seconds: 2),
      );
      
      // Use the Excel package to decode the file
      try {
        final excel = excel_package.Excel.decodeBytes(bytes);
        
        if (excel.tables.isEmpty) {
          developer.log('Excel file has no tables/sheets', name: 'EmployeeImportExport');
          _showExcelErrorDialog(context, 'import_list_excel_empty'.tr(), 'import_list_file_read_error_title'.tr());
          return;
        }
        
        try {
          // Get the first sheet
          final sheet = excel.tables.entries.first.value;
          final rows = sheet.rows;
          
          if (rows.isEmpty) {
            developer.log('Excel file has no rows', name: 'EmployeeImportExport');
            _showExcelErrorDialog(context, 'Excel dosyasında veri bulunamadı.', 'Veri Bulunamadı');
            return;
          }
          
          try {
            // Validate header row
            final headerRow = rows[0];
            if (headerRow.length < 3 || 
                headerRow[0]?.value?.toString() == null ||
                headerRow[1]?.value?.toString() == null ||
                headerRow[2]?.value?.toString() == null) {
              developer.log('Invalid header row in Excel file', name: 'EmployeeImportExport');
              _showExcelErrorDialog(
                context, 
                'import_list_excel_invalid_headers'.tr(),
                'import_list_invalid_headers_title'.tr()
              );
              return;
            }
            
            // Collect errors during import
            List<String> errorRows = [];
            int skippedRows = 0;
            
            // Skip the header row and process data rows
            int importedCount = 0;
            List<Map<String, dynamic>> employeesToImport = [];
            
            // Show loading dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
            
            try {
              for (var i = 1; i < rows.length; i++) {
                try {
                  final row = rows[i];
                  
                  // Skip empty rows
                  if (row.isEmpty || row[0]?.value == null) {
                    skippedRows++;
                    continue;
                  }
                  
                  try {
                    // Extract values, ensuring we handle nulls properly
                    final name = row[0]?.value?.toString() ?? '';
                    final position = row[1]?.value?.toString() ?? '';
                    final department = row[2]?.value?.toString() ?? '';
                    
                    // Status is optional with a default value
                    String status = 'active';
                    
                    try {
                      if (row.length > 3 && row[3]?.value != null) {
                        final statusText = row[3]?.value?.toString() ?? 'Aktif';
                        status = _parseStatusText(statusText);
                      }
                    } catch (statusError) {
                      developer.log('Error parsing status at row $i: ${statusError.toString()}', name: 'EmployeeImportExport', error: statusError);
                      status = 'active'; // Default to active on error
                    }
                    
                    // Optional fields
                    String? email = null;
                    String? phone = null;
                    String? imageUrl = null;
                    
                    try {
                      if (row.length > 4 && row[4]?.value != null) {
                        email = row[4]?.value?.toString();
                      }
                      
                      if (row.length > 5 && row[5]?.value != null) {
                        phone = row[5]?.value?.toString();
                      }
                    } catch (optionalFieldError) {
                      developer.log('Error parsing optional fields at row $i: ${optionalFieldError.toString()}', name: 'EmployeeImportExport', error: optionalFieldError);
                      // Continue with nulls for optional fields
                    }
                    
                    // Skip if required fields are empty
                    if (name.isEmpty || position.isEmpty || department.isEmpty) {
                      errorRows.add('import_list_row_missing_fields'.tr(args: ['${i+1}']));
                      continue;
                    }
                    
                    // Create employee object as Map
                    try {
                      final employeeId = uuid.v4();
                      final employee = {
                        'id': employeeId,
                        'name': name,
                        'position': position,
                        'department': department,
                        'status': status,
                        'email': email,
                        'phone': phone,
                        'imageUrl': imageUrl,
                      };
                      
                      employeesToImport.add(employee);
                      importedCount++;
                    } catch (employeeCreationError) {
                      developer.log('Error creating employee object at row $i: ${employeeCreationError.toString()}', name: 'EmployeeImportExport', error: employeeCreationError);
                      errorRows.add('import_list_row_employee_create_error'.tr(args: ['${i+1}', employeeCreationError.toString()]));
                    }
                  } catch (rowProcessingError) {
                    developer.log('Error processing row $i: ${rowProcessingError.toString()}', name: 'EmployeeImportExport', error: rowProcessingError);
                    errorRows.add('import_list_row_process_error'.tr(args: ['${i+1}', rowProcessingError.toString()]));
                  }
                } catch (rowAccessError) {
                  developer.log('Error accessing row $i: ${rowAccessError.toString()}', name: 'EmployeeImportExport', error: rowAccessError);
                  errorRows.add('import_list_row_access_error'.tr(args: ['${i+1}', rowAccessError.toString()]));
                }
              }
              
              // Save employees to database if there are any to import
              if (employeesToImport.isNotEmpty) {
                try {
                  // Import employees using the service
                  for (var i = 0; i < employeesToImport.length; i++) {
                    try {
                      // Create proper Employee object with EmploymentStatus enum
                      final employeeData = employeesToImport[i];
                      
                      // Always set status to active by default
                      final employee = Employee(
                        id: employeeData['id'],
                        name: employeeData['name'],
                        position: employeeData['position'],
                        departmentId: employeeData['department'],
                        status: EmploymentStatus.active, // Always use active status
                        email: employeeData['email'],
                        phone: employeeData['phone'],
                        imageUrl: employeeData['imageUrl'],
                      );
                      _employeeService.add(employee);
                    } catch (addError) {
                      developer.log('Error adding employee at index $i: ${addError.toString()}', name: 'EmployeeImportExport', error: addError);
                      errorRows.add('import_list_employee_add_error'.tr(args: [addError.toString()]));
                    }
                  }
                  
                  // Close loading dialog
                  Navigator.pop(context);
                  
                  // Reload employees after import
                  try {
                    refreshCallback();
                  } catch (refreshError) {
                    developer.log('Error refreshing employee list: ${refreshError.toString()}', name: 'EmployeeImportExport', error: refreshError);
                  }
                  
                  // Show appropriate message based on import results
                  if (errorRows.isEmpty) {
                    _showInfoCard(
                      context,
                      'import_list_import_success'.tr(args: ['$importedCount']),
                      Colors.green,
                      icon: Icons.check_circle,
                    );
                  } else {
                    _showImportSummary(context, importedCount, errorRows, skippedRows);
                  }
                } catch (importError) {
                  // Close loading dialog
                  try {
                    Navigator.pop(context);
                  } catch (_) {}
                  
                  developer.log('Error during import process: ${importError.toString()}', name: 'EmployeeImportExport');
                  _showExcelErrorDialog(
                    context,
                    'import_list_save_error'.tr(),
                    'import_list_save_error_title'.tr(),
                    errorDetails: importError.toString()
                  );
                }
              } else {
                // Close loading dialog
                try {
                  Navigator.pop(context);
                } catch (_) {}
                
                if (errorRows.isEmpty) {
                  _showInfoCard(
                    context,
                    'import_list_no_valid_employee'.tr(),
                    Colors.orange,
                    icon: Icons.warning,
                  );
                } else {
                  _showExcelErrorDialog(
                    context,
                    'import_list_import_failed'.tr(),
                    'import_list_import_failed_title'.tr(),
                    errorDetails: errorRows.join('\n')
                  );
                }
              }
            } catch (rowsError) {
              // Ensure we close the loading dialog if an error occurs
              try {
                Navigator.pop(context);
              } catch (_) {}
              
              developer.log('Error processing Excel rows: ${rowsError.toString()}', name: 'EmployeeImportExport', error: rowsError);
              _showExcelErrorDialog(
                context,
                'import_list_excel_data_process_error'.tr(),
                'import_list_data_process_error_title'.tr(),
                errorDetails: rowsError.toString()
              );
            }
          } catch (headerError) {
            developer.log('Header validation error: ${headerError.toString()}', name: 'EmployeeImportExport', error: headerError);
            _showExcelErrorDialog(
              context,
              'import_list_header_validation_error'.tr(),
              'import_list_header_error_title'.tr(),
              errorDetails: headerError.toString()
            );
          }
        } catch (sheetError) {
          developer.log('Error accessing Excel sheet: ${sheetError.toString()}', name: 'EmployeeImportExport', error: sheetError);
          _showExcelErrorDialog(
            context,
            'import_list_sheet_access_error'.tr(),
            'import_list_sheet_access_error_title'.tr(),
            errorDetails: sheetError.toString()
          );
        }
      } catch (excelDecodeError) {
        developer.log('Excel decode error: ${excelDecodeError.toString()}', name: 'EmployeeImportExport', error: excelDecodeError);
        _showExcelErrorDialog(
          context,
          'import_list_excel_process_error'.tr(),
          'import_list_excel_process_error_title'.tr(),
          errorDetails: excelDecodeError.toString()
        );
      }
    } catch (e) {
      // Ensure we close the loading dialog if an error occurs
      try {
        Navigator.pop(context);
      } catch (_) {}
      
      developer.log('Excel processing error: ${e.toString()}', name: 'EmployeeImportExport', error: e);
      _showExcelErrorDialog(
        context,
        'import_list_excel_process_error'.tr(),
        'import_list_excel_process_error_title'.tr(),
        errorDetails: e.toString()
      );
    }
  }

  static void _parseCsvDataAndAddEmployees(BuildContext context, String csvData, Function refreshCallback) {
    try {
      // Check if user is authenticated
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showInfoCard(
          context,
          'import_list_login_required'.tr(),
          Colors.red,
          icon: Icons.error,
        );
        return;
      }
      
      _showInfoCard(
        context,
        'import_list_csv_processing'.tr(),
        Colors.blue,
        icon: Icons.hourglass_top,
        duration: const Duration(seconds: 2),
      );
      
      final lines = csvData.split('\n');
      if (lines.isEmpty) {
        _showExcelErrorDialog(context, 'import_list_csv_empty'.tr(), 'import_list_file_read_error_title'.tr());
        return;
      }

      // Collect errors during import
      List<String> errorRows = [];
      int skippedRows = 0;
      int importedCount = 0;
      List<Map<String, dynamic>> employeesToImport = [];
      
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
          
          // Make sure we have at least the required fields
          if (fields.length < 3 || 
              fields[0].trim().isEmpty || 
              fields[1].trim().isEmpty || 
              fields[2].trim().isEmpty) {
            errorRows.add('import_list_row_missing_fields'.tr(args: ['${i+1}']));
            continue;
          }
          
          final name = fields[0].trim();
          final position = fields[1].trim();
          final department = fields[2].trim();
          
          // Status is optional with a default value
          String status = 'active';
          
          if (fields.length > 3 && fields[3].trim().isNotEmpty) {
            status = _parseStatusText(fields[3].trim());
          }
          
          // Optional fields
          String? email = null;
          String? phone = null;
          
          if (fields.length > 4 && fields[4].trim().isNotEmpty) {
            email = fields[4].trim();
          }
          
          if (fields.length > 5 && fields[5].trim().isNotEmpty) {
            phone = fields[5].trim();
          }
          
          // Create employee object as Map
          final employeeId = uuid.v4();
          final employee = {
            'id': employeeId,
            'name': name,
            'position': position,
            'department': department,
            'status': status,
            'email': email,
            'phone': phone,
            'imageUrl': null,
          };
          
          employeesToImport.add(employee);
          importedCount++;
        } catch (rowError) {
          errorRows.add('Satır ${i+1} işlenirken hata oluştu: ${rowError.toString()}');
        }
      }

      // Save employees to database if there are any to import
      if (employeesToImport.isNotEmpty) {
        try {
          // Import employees using the service
          for (var employeeData in employeesToImport) {
            // Create proper Employee object with EmploymentStatus enum
            final employee = Employee(
              id: employeeData['id'],
              name: employeeData['name'],
              position: employeeData['position'],
              departmentId: employeeData['department'],
              status: EmploymentStatus.active, // Always use active status
              email: employeeData['email'],
              phone: employeeData['phone'],
              imageUrl: employeeData['imageUrl'],
            );
            _employeeService.add(employee);
          }
          
          // Close loading dialog
          Navigator.pop(context);
          
          // Reload employees after import
          refreshCallback();
          
          // Show appropriate message based on import results
          if (errorRows.isEmpty) {
            _showInfoCard(
              context,
              'import_list_import_success'.tr(args: ['$importedCount']),
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
            'import_list_save_error'.tr(),
            'import_list_save_error_title'.tr(),
            errorDetails: importError.toString()
          );
        }
      } else {
        // Close loading dialog
        Navigator.pop(context);
        
        if (errorRows.isEmpty) {
          _showInfoCard(
            context,
            'import_list_no_valid_employee'.tr(),
            Colors.orange,
            icon: Icons.warning,
          );
        } else {
          _showExcelErrorDialog(
            context,
            'import_list_import_failed'.tr(),
            'import_list_import_failed_title'.tr(),
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
        'import_list_csv_process_error'.tr(),
        'import_list_csv_process_error_title'.tr(),
        errorDetails: e.toString()
      );
    }
  }

  static void _showExcelErrorDialog(BuildContext context, String message, String title, {String? errorDetails}) {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(title.tr()),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.tr()),
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
              child: const Text('import_list_ok').tr(),
            ),
          ],
        ),
      );
    } catch (e) {
      developer.log('Error showing error dialog: ${e.toString()}', name: 'EmployeeImportExport', error: e);
      // Use a simpler fallback if the dialog itself fails
      _showInfoCard(
        context,
        '${title.tr()}: ${message.tr()}',
        Colors.red,
        icon: Icons.error,
      );
    }
  }

  static void _showImportSummary(BuildContext context, int importedCount, List<String> errorRows, int skippedRows) {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text('import_list_import_summary').tr(),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('import_list_imported_count'.tr(args: ['$importedCount'])),
              if (skippedRows > 0)
                Text('import_list_skipped_rows'.tr(args: ['$skippedRows'])),
              if (errorRows.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('import_list_unprocessed_rows').tr(),
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showErrorCorrection(context, errorRows);
                  },
                  child: const Text('import_list_fix_and_retry').tr(),
                ),
              ],
              if (errorRows.isEmpty && skippedRows == 0)
                const Text('import_list_all_imported').tr(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('import_list_ok').tr(),
            ),
          ],
        ),
      );
    } catch (e) {
      developer.log('Error showing import summary: ${e.toString()}', name: 'EmployeeImportExport', error: e);
      _showInfoCard(
        context,
        'İçe aktarma özeti gösterilirken bir hata oluştu.',
        Colors.red,
        icon: Icons.error,
      );
    }
  }
  
  static void _showErrorCorrection(BuildContext context, List<String> errorRows) {
    // Parse error rows to extract row numbers and error details
    final List<Map<String, dynamic>> rowErrorData = [];
    
    for (var errorRow in errorRows) {
      // Extract row number and error message
      final RegExp rowRegex = RegExp(r'Satır (\d+): (.*)');
      final match = rowRegex.firstMatch(errorRow);
      
      if (match != null) {
        final rowNumber = int.tryParse(match.group(1) ?? '') ?? 0;
        final errorMessage = match.group(2) ?? 'Bilinmeyen hata';
        
        rowErrorData.add({
          'rowNumber': rowNumber,
          'errorMessage': errorMessage,
          'originalData': errorRow,
          'correctedData': {
            'name': '',
            'position': '',
            'department': '',
            'status': 'active',
            'email': '',
            'phone': '',
          }
        });
      }
    }
    
    if (rowErrorData.isEmpty) {
      _showInfoCard(
        context,
        'Düzeltilebilecek hata bulunamadı.',
        Colors.orange,
        icon: Icons.warning,
      );
      return;
    }
    
    // Sort by row number
    rowErrorData.sort((a, b) => (a['rowNumber'] as int).compareTo(b['rowNumber'] as int));
    
    int currentIndex = 0;
    
    // Controllers for text fields
    final nameController = TextEditingController();
    final positionController = TextEditingController();
    final departmentController = TextEditingController();
    final statusController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    
    // Set initial values for the first error
    _setControllerValues(
      rowErrorData[currentIndex],
      nameController,
      positionController,
      departmentController,
      statusController,
      emailController,
      phoneController
    );
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.6,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_note, color: Colors.orange, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'import_list_data_correction'.tr(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              Text(
                                'import_list_row_error_count'.tr(args: ['${rowErrorData[currentIndex]['rowNumber']}', '${rowErrorData.length}']),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Error message
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rowErrorData[currentIndex]['errorMessage'].tr(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Form fields
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'import_list_header_name'.tr(),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: positionController,
                            decoration: InputDecoration(
                              labelText: 'import_list_header_position'.tr(),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: departmentController,
                            decoration: InputDecoration(
                              labelText: 'import_list_header_department'.tr(),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _getStatusFromController(statusController),
                            decoration: const InputDecoration(
                              labelText: 'import_list_header_status',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            items: [
                              DropdownMenuItem(value: 'active', child: Text('import_list_status_active').tr()),
                              DropdownMenuItem(value: 'onLeave', child: Text('import_list_status_onleave').tr()),
                              DropdownMenuItem(value: 'terminated', child: Text('import_list_status_terminated').tr()),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                statusController.text = value;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'import_list_header_email'.tr(),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            decoration: InputDecoration(
                              labelText: 'import_list_header_phone'.tr(),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Navigation buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Previous button
                        ElevatedButton.icon(
                          onPressed: currentIndex > 0 ? () {
                            // Save current values
                            _saveControllerValues(
                              rowErrorData[currentIndex],
                              nameController,
                              positionController,
                              departmentController,
                              statusController,
                              emailController,
                              phoneController
                            );
                            
                            // Move to previous item
                            setState(() {
                              currentIndex--;
                              _setControllerValues(
                                rowErrorData[currentIndex],
                                nameController,
                                positionController,
                                departmentController,
                                statusController,
                                emailController,
                                phoneController
                              );
                            });
                          } : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Önceki Hata'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                          ),
                        ),
                        
                        // Next/Save button
                        ElevatedButton.icon(
                          onPressed: () {
                            // Save current values
                            _saveControllerValues(
                              rowErrorData[currentIndex],
                              nameController,
                              positionController,
                              departmentController,
                              statusController,
                              emailController,
                              phoneController
                            );
                            
                            // Check if there are more errors to fix
                            if (currentIndex < rowErrorData.length - 1) {
                              // Move to next item
                              setState(() {
                                currentIndex++;
                                _setControllerValues(
                                  rowErrorData[currentIndex],
                                  nameController,
                                  positionController,
                                  departmentController,
                                  statusController,
                                  emailController,
                                  phoneController
                                );
                              });
                            } else {
                              // All errors have been addressed, import the corrected data
                              Navigator.pop(context);
                              _importCorrectedData(context, rowErrorData);
                            }
                          },
                          icon: Icon(currentIndex < rowErrorData.length - 1 ? Icons.arrow_forward : Icons.save),
                          label: Text(currentIndex < rowErrorData.length - 1 ? 'Sonraki Hata' : 'Düzeltmeleri Kaydet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentIndex < rowErrorData.length - 1 ? Colors.blue : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  static String _getStatusFromController(TextEditingController controller) {
    final status = controller.text;
    if (status == 'onLeave' || status == 'terminated') {
      return status;
    }
    return 'active';
  }
  
  static void _setControllerValues(
    Map<String, dynamic> rowData,
    TextEditingController nameController,
    TextEditingController positionController,
    TextEditingController departmentController,
    TextEditingController statusController,
    TextEditingController emailController,
    TextEditingController phoneController
  ) {
    final correctedData = rowData['correctedData'] as Map<String, dynamic>;
    
    nameController.text = correctedData['name'] ?? '';
    positionController.text = correctedData['position'] ?? '';
    departmentController.text = correctedData['department'] ?? '';
    statusController.text = correctedData['status'] ?? 'active';
    emailController.text = correctedData['email'] ?? '';
    phoneController.text = correctedData['phone'] ?? '';
  }
  
  static void _saveControllerValues(
    Map<String, dynamic> rowData,
    TextEditingController nameController,
    TextEditingController positionController,
    TextEditingController departmentController,
    TextEditingController statusController,
    TextEditingController emailController,
    TextEditingController phoneController
  ) {
    final correctedData = rowData['correctedData'] as Map<String, dynamic>;
    
    correctedData['name'] = nameController.text;
    correctedData['position'] = positionController.text;
    correctedData['department'] = departmentController.text;
    correctedData['status'] = statusController.text;
    correctedData['email'] = emailController.text;
    correctedData['phone'] = phoneController.text;
  }
  
  static void _importCorrectedData(BuildContext context, List<Map<String, dynamic>> correctedRows) {
    try {
      // Check if user is authenticated
      try {
        final User? currentUser = _auth.currentUser;
        if (currentUser == null) {
          developer.log('User not authenticated for corrected data import', name: 'EmployeeImportExport');
          _showInfoCard(
            context,
            'import_list_login_required'.tr(),
            Colors.red,
            icon: Icons.error,
          );
          return;
        }
      } catch (authError) {
        developer.log('Authentication check error in corrected data import: ${authError.toString()}', name: 'EmployeeImportExport', error: authError);
        _showInfoCard(
          context,
          'import_list_auth_check_error'.tr(args: [authError.toString()]),
          Colors.red,
          icon: Icons.error,
        );
        return;
      }
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      int successCount = 0;
      List<String> remainingErrors = [];
      
      // Iterate through corrected rows and validate
      for (var i = 0; i < correctedRows.length; i++) {
        try {
          final rowData = correctedRows[i];
          final correctedData = rowData['correctedData'] as Map<String, dynamic>;
          final rowNumber = rowData['rowNumber'] as int;
          
          // Validate required fields
          if (correctedData['name'].toString().isEmpty || 
              correctedData['position'].toString().isEmpty || 
              correctedData['department'].toString().isEmpty) {
            remainingErrors.add('Satır $rowNumber: Zorunlu alanlar eksik');
            continue;
          }
          
          try {
            // Create employee object
            final employeeId = uuid.v4();
            // Make sure we handle empty strings properly for nullable fields
            String? emailValue = correctedData['email']?.toString();
            if (emailValue != null && emailValue.isEmpty) emailValue = null;
            
            String? phoneValue = correctedData['phone']?.toString();
            if (phoneValue != null && phoneValue.isEmpty) phoneValue = null;
            
            final employee = Employee(
              id: employeeId,
              name: correctedData['name'],
              position: correctedData['position'],
              departmentId: correctedData['department'],
              status: EmploymentStatus.active, // Always use active status
              email: emailValue,
              phone: phoneValue,
              imageUrl: null,
            );
            
            // Add employee to database
            try {
              _employeeService.add(employee);
              successCount++;
              developer.log('Successfully added corrected employee: ${employee.name}', name: 'EmployeeImportExport');
            } catch (addError) {
              developer.log('Error adding corrected employee at row $rowNumber: ${addError.toString()}', name: 'EmployeeImportExport', error: addError);
              remainingErrors.add('Satır $rowNumber: Veritabanına eklenirken hata: ${addError.toString()}');
            }
          } catch (employeeCreationError) {
            developer.log('Error creating employee object for corrected data at row $rowNumber: ${employeeCreationError.toString()}', name: 'EmployeeImportExport', error: employeeCreationError);
            remainingErrors.add('Satır $rowNumber: ${employeeCreationError.toString()}');
          }
        } catch (rowProcessingError) {
          developer.log('Error processing corrected row $i: ${rowProcessingError.toString()}', name: 'EmployeeImportExport', error: rowProcessingError);
          remainingErrors.add('Satır işlenirken hata: ${rowProcessingError.toString()}');
        }
      }
      
      // Close loading dialog
      try {
        Navigator.pop(context);
      } catch (dialogError) {
        developer.log('Error closing dialog: ${dialogError.toString()}', name: 'EmployeeImportExport', error: dialogError);
      }
      
      // Show result
      if (remainingErrors.isEmpty) {
        _showInfoCard(
          context,
          'import_list_import_success'.tr(args: ['$successCount']),
          Colors.green,
          icon: Icons.check_circle,
        );
      } else {
        _showExcelErrorDialog(
          context,
          'import_list_some_rows_failed'.tr(),
          'import_list_partial_success_title'.tr(),
          errorDetails: remainingErrors.join('\n'),
        );
      }
      
    } catch (e) {
      // Close loading dialog if open
      try {
        Navigator.pop(context);
      } catch (_) {}
      
      developer.log('Error importing corrected data: ${e.toString()}', name: 'EmployeeImportExport', error: e);
      _showInfoCard(
        context,
        'import_list_import_error'.tr(args: [e.toString()]),
        Colors.red,
        icon: Icons.error,
      );
    }
  }
  
  static void _showInfoCard(
    BuildContext context,
    String message,
    Color color, {
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    try {
      // Use InfoCard to display messages
      InfoCard.showInfoCard(
        context,
        message,
        color,
        icon: icon ?? Icons.info,
        duration: duration,
      );
    } catch (e) {
      developer.log('Error showing info card: ${e.toString()}', name: 'EmployeeImportExport', error: e);
      // Fallback to print if InfoCard fails
      print('INFO CARD ERROR: $message');
    }
  }
}
