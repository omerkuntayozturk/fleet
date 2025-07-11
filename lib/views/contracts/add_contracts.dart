import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../models/contract.dart';
import 'package:uuid/uuid.dart';
import '../../info_card.dart';
import 'package:easy_localization/easy_localization.dart'; // Add this import for Easy Localization

// Date input formatter (DD.MM.YYYY format)
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Only allow digits and dots
    String filtered = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    
    // Apply DD.MM.YYYY format
    if (filtered.length > 10) {
      filtered = filtered.substring(0, 10);
    }
    
    // Add dots automatically
    if (filtered.length > 2 && !filtered.contains('.')) {
      filtered = '${filtered.substring(0, 2)}.${filtered.substring(2)}';
    }
    if (filtered.length > 5 && filtered.lastIndexOf('.') == 2) {
      filtered = '${filtered.substring(0, 5)}.${filtered.substring(5)}';
    }
    
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

// Name input formatter (allows letters, spaces, and basic punctuation)
class NameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Allow letters, spaces, and basic punctuation
    final filteredText = newValue.text.replaceAll(
      RegExp(r'[^a-zA-ZğüşöçıİĞÜŞÖÇ \-_.,]'),
      '',
    );
    
    // Limit the length to 100 characters
    final limitedText = filteredText.length > 100 ? filteredText.substring(0, 100) : filteredText;
    
    return TextEditingValue(
      text: limitedText,
      selection: TextSelection.collapsed(offset: limitedText.length),
    );
  }
}

class ContractManagement {
  // Responsive breakpoints
  static const double _mobileBreakpoint = 650;
  static final FirestoreService _firestoreService = FirestoreService();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final uuid = Uuid();

  // Determine if we're on a mobile device
  static bool _isMobileView(BuildContext context) {
    return MediaQuery.of(context).size.width < _mobileBreakpoint;
  }

  static void addNewContract(BuildContext context, Function refreshContracts) {
    final employeeNameCtrl = TextEditingController();
    final contractTypeCtrl = TextEditingController();
    final startDateCtrl = TextEditingController();
    final endDateCtrl = TextEditingController();
    final vehicleIdCtrl = TextEditingController(); // Hidden controller for vehicle ID
    final vehiclePlateCtrl = TextEditingController(); // New controller for displaying plate
    String? selectedEmployeeId;
    String? selectedVehiclePlate;

    // Get screen dimensions for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = _isMobileView(context);
    
    // Set the dialog width based on screen size
    final dialogWidth = isMobile 
        ? screenWidth * 0.95  // Almost full width on mobile
        : screenWidth * 0.6;  // 60% width on desktop
        
    // Set max height constraints based on screen size
    final maxHeight = isMobile 
        ? screenHeight * 0.9  // 90% of screen height on mobile
        : screenHeight * 0.85; // 85% of screen height on desktop
    
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              ),
              elevation: 8,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 40,
                vertical: isMobile ? 10 : 24
              ),
              child: Container(
                width: dialogWidth,
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                ),
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Responsive header
                      _buildResponsiveHeader(
                        context, 
                        tr('contracts_add_new_title'), // 'Yeni Sözleşme Ekle'
                        tr('contracts_add_new_subtitle'), // 'Çalışan için yeni bir sözleşme oluşturun'
                        Icons.description, 
                        Theme.of(context).primaryColor, 
                        isMobile
                      ),
                      SizedBox(height: isMobile ? 20 : 32),
                      
                      // Responsive contract info card
                      _buildContractInfoCard(
                        context,
                        employeeNameCtrl,
                        contractTypeCtrl,
                        vehicleIdCtrl, // ID controller (hidden)
                        vehiclePlateCtrl, // Pass plate controller for display
                        isMobile,
                        (String id, String name) {
                          selectedEmployeeId = id;
                          employeeNameCtrl.text = name;
                        },
                        // Vehicle selection callback
                        (String id, String plate) {
                          vehicleIdCtrl.text = id; // Store ID in hidden controller
                          vehiclePlateCtrl.text = plate; // Show plate in visible field
                          selectedVehiclePlate = plate;
                        },
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      
                      // Responsive dates card
                      _buildDatesCard(
                        context, 
                        startDateCtrl, 
                        endDateCtrl, 
                        isMobile
                      ),
                      SizedBox(height: isMobile ? 20 : 32),
                      
                      // Responsive action buttons
                      _buildActionButtons(
                        context,
                        () => Navigator.pop(context),
                        () {
                          _handleAddContract(
                            context,
                            employeeNameCtrl,
                            contractTypeCtrl,
                            startDateCtrl,
                            endDateCtrl,
                            vehicleIdCtrl,
                            refreshContracts,
                            selectedEmployeeId,
                            selectedVehiclePlate,
                          );
                        },
                        tr('common_cancel'), // 'İptal'
                        tr('contracts_add_button'), // 'Sözleşmeyi Ekle'
                        Theme.of(context).primaryColor,
                        isMobile,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Helper method to build responsive header
  static Widget _buildResponsiveHeader(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
          ),
          child: Icon(
            icon,
            color: color,
            size: isMobile ? 20 : 28,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: isMobile ? 2 : 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          splashRadius: isMobile ? 16 : 20,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: isMobile ? 32 : 40,
            minHeight: isMobile ? 32 : 40,
          ),
        ),
      ],
    );
  }
  
  // Helper method to build contract info card
  static Widget _buildContractInfoCard(
    BuildContext context,
    TextEditingController employeeNameCtrl,
    TextEditingController contractTypeCtrl,
    TextEditingController vehicleIdCtrl, // ID controller (hidden)
    TextEditingController vehiclePlateCtrl, // New parameter for plate display
    bool isMobile,
    [void Function(String, String)? onEmployeeSelected,
     void Function(String, String)? onVehicleSelected]
  ) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('contracts_info_title'), // 'Sözleşme Bilgileri'
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            
            // Employee name field (now read-only with selection dialog)
            TextField(
              controller: employeeNameCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: tr('contracts_select_employee'), // 'Çalışan Seçin'
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 13 : 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                prefixIcon: Icon(
                  Icons.person,
                  color: Colors.grey[500],
                  size: isMobile ? 18 : 24,
                ),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[500],
                  size: isMobile ? 24 : 28,
                ),
                filled: true,
                fillColor: Colors.white,
                helperText: isMobile ? null : tr('contracts_select_employee_helper'), // 'Listeden bir çalışan seçin'
                helperStyle: TextStyle(fontSize: isMobile ? 10 : 12, color: Colors.grey[600]),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16, 
                  vertical: isMobile ? 10 : 16
                ),
              ),
              onTap: () {
                _showEmployeeSelectionDialog(context, employeeNameCtrl, isMobile, onEmployeeSelected);
              },
            ),
            
            SizedBox(height: isMobile ? 16 : 20),
            
            // Contract type field (custom popup selection)
            TextField(
              controller: contractTypeCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: tr('contracts_type'), // 'Sözleşme Türü'
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 13 : 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                prefixIcon: Icon(
                  Icons.work,
                  color: Colors.grey[500],
                  size: isMobile ? 18 : 24,
                ),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[500],
                  size: isMobile ? 24 : 28,
                ),
                filled: true,
                fillColor: Colors.white,
                helperText: isMobile ? null : tr('contracts_type_helper'), // 'Sözleşme türünü seçin'
                helperStyle: TextStyle(fontSize: isMobile ? 10 : 12, color: Colors.grey[600]),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16, 
                  vertical: isMobile ? 10 : 16
                ),
              ),
              onTap: () {
                _showContractTypeDialog(context, contractTypeCtrl, isMobile);
              },
            ),
            
            SizedBox(height: isMobile ? 16 : 20),

            // Vehicle field (now using plate controller for display)
            TextField(
              controller: vehiclePlateCtrl, // Use plate controller instead of ID
              readOnly: true,
              decoration: InputDecoration(
                labelText: tr('contracts_select_vehicle', gender: 'Araç Seçin'),
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 13 : 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                prefixIcon: Icon(
                  Icons.directions_car,
                  color: Colors.grey[500],
                  size: isMobile ? 18 : 24,
                ),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[500],
                  size: isMobile ? 24 : 28,
                ),
                filled: true,
                fillColor: Colors.white,
                helperText: isMobile ? null : tr('contracts_select_vehicle_helper', gender: 'Araç seçin'),
                helperStyle: TextStyle(fontSize: isMobile ? 10 : 12, color: Colors.grey[600]),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 10 : 16
                ),
              ),
              onTap: () {
                _showVehicleSelectionDialog(
                  context, 
                  vehicleIdCtrl, // Still pass ID controller for value storage
                  isMobile, 
                  onVehicleSelected, 
                  vehiclePlateCtrl // Pass plate controller as additional parameter
                );
              },
            ),
            
            SizedBox(height: isMobile ? 16 : 20),

            // Reference field (text) kaldırıldı
            // TextField(
            //   controller: referenceCtrl,
            //   decoration: InputDecoration(
            //     labelText: 'Referans',
            //     labelStyle: TextStyle(
            //       color: Colors.grey[600],
            //       fontSize: isMobile ? 13 : 14,
            //     ),
            //     border: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
            //       borderSide: BorderSide(color: Colors.grey[300]!),
            //     ),
            //     enabledBorder: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
            //       borderSide: BorderSide(color: Colors.grey[300]!),
            //     ),
            //     focusedBorder: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
            //       borderSide: BorderSide(color: Theme.of(context).primaryColor),
            //     ),
            //     prefixIcon: Icon(
            //       Icons.link,
            //       color: Colors.grey[500],
            //       size: isMobile ? 18 : 24,
            //     ),
            //     filled: true,
            //     fillColor: Colors.white,
            //     helperText: isMobile ? null : 'Referans veya açıklama girin',
            //     helperStyle: TextStyle(fontSize: isMobile ? 10 : 12, color: Colors.grey[600]),
            //     contentPadding: EdgeInsets.symmetric(
            //       horizontal: isMobile ? 12 : 16,
            //       vertical: isMobile ? 10 : 16
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to fetch employees from Firestore
  static Future<List<Map<String, dynamic>>> _fetchEmployeesForSelection() async {
    try {
      // Check if user is authenticated
      final User? currentUser = ContractManagement._auth.currentUser;
      if (currentUser == null) {
        throw Exception('Oturum açmanız gerekiyor');
      }

      // Fetch employees directly from Firestore
      final employeesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('employees')
          .orderBy('name', descending: false)
          .get();
      
      // Convert snapshot to Map list
      return employeesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'position': data['position'] ?? '',
          'phone': data['phone'] ?? '',
          'departmentId': data['departmentId'] ?? '',
          'status': data['status'] ?? 'active',
        };
      }).toList();
      
    } catch (e) {
      print('Error fetching employees for selection: $e');
      throw e;
    }
  }

  // New helper method to show employee selection dialog with improved UI
  static void _showEmployeeSelectionDialog(
    BuildContext context,
    TextEditingController controller,
    bool isMobile,
    [void Function(String, String)? onEmployeeSelected]
  ) {
    final dialogWidth = isMobile 
        ? MediaQuery.of(context).size.width * 0.95
        : MediaQuery.of(context).size.width * 0.7;
    
    final dialogHeight = isMobile 
        ? MediaQuery.of(context).size.height * 0.8
        : MediaQuery.of(context).size.height * 0.7;
        
    // Add a search controller for filtering employees
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 20,
                vertical: isMobile ? 20 : 40,
              ),
              child: Container(
                width: dialogWidth,
                height: dialogHeight,
                padding: const EdgeInsets.all(0),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: Theme.of(context).primaryColor,
                            size: isMobile ? 20 : 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tr('contracts_select_employee'), // 'Çalışan Seçin'
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    
                    // Search bar
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: tr('search_employees'), // 'Çalışan ara...'
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          // Force update the UI when search text changes
                          setState(() {});
                        },
                      ),
                    ),
                    
                    // Employee list
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchEmployeesForSelection(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    tr('contracts_employee_load_error'), // 'Çalışanlar yüklenirken hata oluştu'
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    snapshot.error.toString(),
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showEmployeeSelectionDialog(context, controller, isMobile, onEmployeeSelected);
                                    },
                                    child: Text(tr('common_try_again')), // 'Tekrar Dene'
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          List<Map<String, dynamic>> employees = snapshot.data ?? [];
                          
                          // Filter employees based on search text
                          final searchText = searchController.text.toLowerCase();
                          if (searchText.isNotEmpty) {
                            employees = employees.where((employee) {
                              return employee['name'].toString().toLowerCase().contains(searchText) ||
                                     (employee['email'] != null && employee['email'].toString().toLowerCase().contains(searchText)) ||
                                     (employee['position'] != null && employee['position'].toString().toLowerCase().contains(searchText));
                            }).toList();
                          }
                          
                          if (employees.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchText.isNotEmpty
                                        ? tr('no_search_results') // 'Arama sonucu bulunamadı'
                                        : tr('contracts_no_employees_found'), // 'Henüz çalışan kaydı bulunamadı'
                                    style: TextStyle(
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    searchText.isNotEmpty
                                        ? tr('try_different_search') // 'Farklı bir arama terimi deneyin'
                                        : tr('contracts_add_employees_first'), // 'Önce çalışan modülünden çalışan ekleyin'
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: employees.length,
                            itemBuilder: (context, index) {
                              final employee = employees[index];
                              final isSelected = controller.text == employee['name'];
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                elevation: isSelected ? 4 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected 
                                        ? Theme.of(context).primaryColor 
                                        : Colors.grey[200]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    controller.text = employee['name'];
                                    if (onEmployeeSelected != null) {
                                      onEmployeeSelected(employee['id'], employee['name']);
                                    }
                                    Navigator.pop(context);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                                    child: Row(
                                      children: [
                                        // Avatar with first letter or profile picture
                                        CircleAvatar(
                                          radius: isMobile ? 20 : 24,
                                          backgroundColor: isSelected 
                                              ? Theme.of(context).primaryColor 
                                              : _getColorFromName(employee['name']),
                                          backgroundImage: employee['imageUrl'] != null && employee['imageUrl'].toString().isNotEmpty
                                              ? NetworkImage(employee['imageUrl'])
                                              : null,
                                          child: employee['imageUrl'] == null || employee['imageUrl'].toString().isEmpty
                                              ? Text(
                                                  employee['name'].isNotEmpty 
                                                      ? employee['name'][0].toUpperCase()
                                                      : '?',
                                                  style: TextStyle(
                                                    fontSize: isMobile ? 16 : 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // Employee details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                employee['name'],
                                                style: TextStyle(
                                                  fontSize: isMobile ? 14 : 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected 
                                                      ? Theme.of(context).primaryColor 
                                                      : Colors.black87,
                                                ),
                                              ),
                                              if (employee['email'] != null && employee['email'].toString().isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  employee['email'],
                                                  style: TextStyle(
                                                    fontSize: isMobile ? 12 : 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                              if (employee['position'] != null && employee['position'].toString().isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  employee['position'],
                                                  style: TextStyle(
                                                    fontSize: isMobile ? 12 : 14,
                                                    color: Colors.grey[500],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        
                                        // Phone info if available
                                        if (employee['phone'] != null && employee['phone'].toString().isNotEmpty)
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            margin: EdgeInsets.only(right: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                                SizedBox(width: 4),
                                                Text(
                                                  employee['phone'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        
                                        // Selection indicator
                                        Icon(
                                          isSelected 
                                              ? Icons.radio_button_checked 
                                              : Icons.radio_button_unchecked,
                                          color: isSelected 
                                              ? Theme.of(context).primaryColor 
                                              : Colors.grey[400],
                                          size: isMobile ? 20 : 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                               ); 
                            },
                          );
                        },
                      ),
                    ),
                    
                    // Footer with action buttons
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end, // Changed from spaceBetween to end
                        children: [
                          // Vehicle count removed
                          
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              tr('common_cancel', gender: 'Vazgeç'),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }
  
  // Helper function to generate color from name for avatar
  static Color _getColorFromName(String name) {
    if (name.isEmpty) return Colors.blue;
    
    // Simple hash function for name
    int hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Convert to color
    final hue = (hash % 360).abs();
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.5).toColor();
  }

  // Edit contract method
  static void editContract(BuildContext context, Map<String, dynamic> contract, Function refreshContracts) {
    final employeeNameCtrl = TextEditingController(text: contract['employeeName'] ?? contract['employee']);
    final contractTypeCtrl = TextEditingController(text: contract['type']);
    final startDateCtrl = TextEditingController(text: contract['startDate']);
    final endDateCtrl = TextEditingController(text: contract['endDate']);
    final vehicleIdCtrl = TextEditingController(text: contract['vehicleId'] ?? '');
    final vehiclePlateCtrl = TextEditingController(text: contract['vehiclePlate'] ?? '');
    String? selectedEmployeeId = contract['employeeId'];
// Initialize with existing plate

    // Get screen dimensions for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = _isMobileView(context);
    
    // Set the dialog width based on screen size
    final dialogWidth = isMobile 
        ? screenWidth * 0.95  // Almost full width on mobile
        : screenWidth * 0.6;  // 60% width on desktop
        
    // Set max height constraints based on screen size
    final maxHeight = isMobile 
        ? screenHeight * 0.9  // 90% of screen height on mobile
        : screenHeight * 0.85; // 85% of screen height on desktop
    
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {            
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              ),
              elevation: 8,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 40,
                vertical: isMobile ? 10 : 24
              ),
              child: Container(
                width: dialogWidth,
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                ),
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Responsive header
                      _buildResponsiveHeader(
                        context, 
                        tr('contracts_edit_title'), // 'Sözleşmeyi Düzenle'
                        tr('contracts_edit_subtitle'), // 'Çalışan sözleşme bilgilerini güncelleyin'
                        Icons.edit_document, 
                        Theme.of(context).colorScheme.secondary, 
                        isMobile
                      ),
                      SizedBox(height: isMobile ? 20 : 32),
                      
                      // Responsive contract info card
                      _buildContractInfoCard(
                        context,
                        employeeNameCtrl,
                        contractTypeCtrl,
                        vehicleIdCtrl,
                        vehiclePlateCtrl, // Pass plate controller
                        isMobile,
                        (String id, String name) {
                          selectedEmployeeId = id;
                          employeeNameCtrl.text = name;
                        },
                        // Vehicle selection callback
                        (String id, String plate) {
                          vehicleIdCtrl.text = id;
                          vehiclePlateCtrl.text = plate;
// Now properly defined
                        },
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      
                      // Responsive dates card
                      _buildDatesCard(
                        context, 
                        startDateCtrl, 
                        endDateCtrl, 
                        isMobile
                      ),
                      SizedBox(height: isMobile ? 20 : 32),
                      
                      // Responsive action buttons
                      _buildActionButtons(
                        context,
                        () => Navigator.pop(context),
                        () {
                          _handleEditContract(
                            context,
                            contract['id'],
                            employeeNameCtrl,
                            contractTypeCtrl,
                            startDateCtrl,
                            endDateCtrl,
                            refreshContracts,
                            selectedEmployeeId, // <-- eklendi
                            contract, // <-- pass contract map
                          );
                        },
                        tr('common_cancel'), // 'İptal'
                        tr('common_update'), // 'Güncelle'
                        Colors.green, // Changed from Theme.of(context).colorScheme.secondary to Colors.green
                        isMobile,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Helper method to handle edit contract functionality
  // Helper method to build action buttons
  static Widget _buildActionButtons(
    BuildContext context,
    VoidCallback onCancel,
    VoidCallback onConfirm,
    String cancelText,
    String confirmText,
    Color confirmColor,
    bool isMobile,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 8 : 12,
            ),
          ),
          child: Text(
            cancelText,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: isMobile ? 13 : 14,
            ),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 16),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 10 : 14,
            ),
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  // Helper method to parse date from DD.MM.YYYY format
  static DateTime? _parseDate(String dateString) {
    try {
      final parts = dateString.split('.');
      if (parts.length != 3) return null;
      
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      
      if (day == null || month == null || year == null) return null;
      if (day < 1 || day > 31 || month < 1 || month > 12) return null;
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  // Helper method to build dates card
  static Widget _buildDatesCard(
    BuildContext context,
    TextEditingController startDateCtrl,
    TextEditingController endDateCtrl,
    bool isMobile,
  ) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('contracts_dates_title'), // 'Sözleşme Tarihleri'
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            
            // Start date field - made read-only and opens date picker on tap
            TextField(
              controller: startDateCtrl,
              readOnly: true,
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: startDateCtrl.text.isNotEmpty 
                      ? _parseDate(startDateCtrl.text) ?? DateTime.now()
                      : DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  locale: const Locale('tr', 'TR'), // Turkish locale
                  helpText: tr('contracts_select_start_date'), // 'Başlangıç tarihi seçin'
                  cancelText: tr('common_cancel'), // 'İptal'
                  confirmText: tr('common_confirm'), // 'Tamam'
                );
                if (picked != null) {
                  final day = picked.day.toString().padLeft(2, '0');
                  final month = picked.month.toString().padLeft(2, '0');
                  final year = picked.year.toString();
                  startDateCtrl.text = '$day.$month.$year';
                }
              },
              decoration: InputDecoration(
                labelText: tr('contracts_start_date'), // 'Başlangıç Tarihi'
                hintText: tr('contracts_date_format'), // 'GG.AA.YYYY'
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 13 : 14,
                ),
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: isMobile ? 13 : 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                prefixIcon: Icon(
                  Icons.calendar_today,
                  color: Colors.grey[500],
                  size: isMobile ? 18 : 24,
                ),
                suffixIcon: Icon(
                  Icons.date_range,
                  color: Colors.grey[500],
                  size: isMobile ? 18 : 22,
                ),
                filled: true,
                fillColor: Colors.white,
                helperText: isMobile ? null : tr('contracts_click_to_select_date'), // 'Tarihi seçmek için tıklayın'
                helperStyle: TextStyle(fontSize: isMobile ? 10 : 12, color: Colors.grey[600]),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16, 
                  vertical: isMobile ? 10 : 16
                ),
              ),
            ),
            
            SizedBox(height: isMobile ? 16 : 20),
            
            // End date field - made read-only and opens date picker on tap
            TextField(
              controller: endDateCtrl,
              readOnly: true,
              onTap: () async {
                // Calculate initial date - prefer one year from start date or current date
                DateTime initialDate = DateTime.now().add(const Duration(days: 365));
                
                if (startDateCtrl.text.isNotEmpty) {
                  final startDate = _parseDate(startDateCtrl.text);
                  if (startDate != null) {
                    // Set initial end date to one year after start date
                    initialDate = startDate.add(const Duration(days: 365));
                  }
                }
                
                // If end date is already filled, use that as initial date
                if (endDateCtrl.text.isNotEmpty) {
                  final currentEndDate = _parseDate(endDateCtrl.text);
                  if (currentEndDate != null) {
                    initialDate = currentEndDate;
                  }
                }
                
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  locale: const Locale('tr', 'TR'), // Turkish locale
                  helpText: tr('contracts_select_end_date'), // 'Bitiş tarihi seçin'
                  cancelText: tr('common_cancel'), // 'İptal'
                  confirmText: tr('common_confirm'), // 'Tamam'
                );
                if (picked != null) {
                  final day = picked.day.toString().padLeft(2, '0');
                  final month = picked.month.toString().padLeft(2, '0');
                  final year = picked.year.toString();
                  endDateCtrl.text = '$day.$month.$year';
                }
              },
              decoration: InputDecoration(
                labelText: tr('contracts_end_date'), // 'Bitiş Tarihi'
                hintText: tr('contracts_date_format'), // 'GG.AA.YYYY'
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 13 : 14,
                ),
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: isMobile ? 13 : 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                prefixIcon: Icon(
                  Icons.event,
                  color: Colors.grey[500],
                  size: isMobile ? 18 : 24,
                ),
                suffixIcon: Icon(
                  Icons.date_range,
                  color: Colors.grey[500],
                  size: isMobile ? 18 : 22,
                ),
                filled: true,
                fillColor: Colors.white,
                helperText: isMobile ? null : tr('contracts_click_to_select_date'), // 'Tarihi seçmek için tıklayın'
                helperStyle: TextStyle(fontSize: isMobile ? 10 : 12, color: Colors.grey[600]),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16, 
                  vertical: isMobile ? 10 : 16
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to show contract type selection dialog
  static void _showContractTypeDialog(
    BuildContext context,
    TextEditingController controller,
    bool isMobile,
  ) {
    final contractTypes = [
      {
        'name': tr('contract_type_indefinite'), // 'Belirsiz Süreli'
        'description': tr('contract_type_indefinite_desc'), // 'Bitiş tarihi olmayan sürekli iş sözleşmesi'
        'icon': Icons.calendar_today_outlined,
      },
      {
        'name': tr('contract_type_definite'), // 'Belirli Süreli'
        'description': tr('contract_type_definite_desc'), // 'Başlangıç ve bitiş tarihleri belirlenmiş sözleşme'
        'icon': Icons.date_range,
      },
      {
        'name': tr('contract_type_full_time'), // 'Tam Zamanlı'
        'description': tr('contract_type_full_time_desc'), // 'Tam gün çalışma esasına dayalı sözleşme'
        'icon': Icons.access_time_filled,
      },
    ];
    
    final dialogWidth = isMobile 
        ? MediaQuery.of(context).size.width * 0.95
        : MediaQuery.of(context).size.width * 0.6;
    
    final dialogHeight = isMobile 
        ? MediaQuery.of(context).size.height * 0.7
        : MediaQuery.of(context).size.height * 0.6;
        
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 20,
            vertical: isMobile ? 20 : 40,
          ),
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.work_outline,
                        color: Theme.of(context).primaryColor,
                        size: isMobile ? 20 : 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('contracts_select_type'), // 'Sözleşme Türü Seçin'
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                
                // Contract types list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: contractTypes.length,
                    itemBuilder: (context, index) {
                      final type = contractTypes[index];
                      final isSelected = controller.text == type['name'];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        elevation: isSelected ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected 
                                ? Theme.of(context).primaryColor 
                                : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            controller.text = type['name'] as String;
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            child: Row(
                              children: [
                                // Icon container
                                Container(
                                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? Theme.of(context).primaryColor.withOpacity(0.1) 
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    type['icon'] as IconData,
                                    color: isSelected 
                                        ? Theme.of(context).primaryColor 
                                        : Colors.grey[700],
                                    size: isMobile ? 20 : 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Contract type details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type['name'] as String,
                                        style: TextStyle(
                                          fontSize: isMobile ? 14 : 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected 
                                              ? Theme.of(context).primaryColor 
                                              : Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        type['description'] as String,
                                        style: TextStyle(
                                          fontSize: isMobile ? 12 : 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Selection indicator
                                Icon(
                                  isSelected 
                                      ? Icons.radio_button_checked 
                                      : Icons.radio_button_unchecked,
                                  color: isSelected 
                                      ? Theme.of(context).primaryColor 
                                      : Colors.grey[400],
                                  size: isMobile ? 20 : 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                         );
                    },
                  ),
                ),

                // Footer with action button
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          tr('common_cancel'), // 'Vazgeç'
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        },
      );
  }

  // Helper method to fetch vehicles from Firestore
  static Future<List<Map<String, dynamic>>> _fetchVehiclesForSelection() async {
    try {
      // Check if user is authenticated
      final User? currentUser = ContractManagement._auth.currentUser;
      if (currentUser == null) {
        throw Exception('Oturum açmanız gerekiyor');
      }

      // Fetch vehicles directly from Firestore
      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('vehicles')
          .orderBy('model', descending: false)
          .get();
      
      // Convert snapshot to Map list
      return vehiclesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'model': data['model'] ?? '',
          'plate': data['plate'] ?? '',
          'year': data['year'] != null ? data['year'].toString() : '',
        };
      }).toList();
      
    } catch (e) {
      print('Error fetching vehicles for selection: $e');
      throw e;
    }
  }

  // New helper method to show vehicle selection dialog with improved UI
  static void _showVehicleSelectionDialog(
    BuildContext context,
    TextEditingController idController, // Store ID here
    bool isMobile,
    [void Function(String, String)? onVehicleSelected,
     TextEditingController? plateController] // Optional plate controller
  ) {
    final dialogWidth = isMobile 
        ? MediaQuery.of(context).size.width * 0.95
        : MediaQuery.of(context).size.width * 0.7;
    
    final dialogHeight = isMobile 
        ? MediaQuery.of(context).size.height * 0.8
        : MediaQuery.of(context).size.height * 0.7;
        
    // Add a search controller for filtering vehicles
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 20,
                vertical: isMobile ? 20 : 40,
              ),
              child: Container(
                width: dialogWidth,
                height: dialogHeight,
                padding: const EdgeInsets.all(0),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            color: Theme.of(context).primaryColor,
                            size: isMobile ? 20 : 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tr('contracts_select_vehicle', gender: 'Araç Seçin'),
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    
                    // Search bar
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: tr('search_vehicles', gender: 'Araç ara...'),
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          // Force update the UI when search text changes
                          setState(() {});
                        },
                      ),
                    ),
                    
                    // Vehicle list
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchVehiclesForSelection(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    tr('contracts_vehicle_load_error', gender: 'Araçlar yüklenirken hata oluştu'),
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    snapshot.error.toString(),
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showVehicleSelectionDialog(context, idController, isMobile);
                                    },
                                    child: Text(tr('common_try_again', gender: 'Tekrar Dene')),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          List<Map<String, dynamic>> vehicles = snapshot.data ?? [];
                          
                          // Filter vehicles based on search text
                          final searchText = searchController.text.toLowerCase();
                          if (searchText.isNotEmpty) {
                            vehicles = vehicles.where((vehicle) {
                              return vehicle['model'].toString().toLowerCase().contains(searchText) ||
                                     vehicle['plate'].toString().toLowerCase().contains(searchText);
                            }).toList();
                          }
                          
                          if (vehicles.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.directions_car_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchText.isNotEmpty
                                        ? tr('no_search_results',)
                                        : tr('contracts_no_vehicles_found',),
                                    style: TextStyle(
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    searchText.isNotEmpty
                                        ? tr('try_different_search', )
                                        : tr('contracts_add_vehicles_first',),
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: vehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = vehicles[index];
                              final isSelected = idController.text == vehicle['id'];
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                elevation: isSelected ? 4 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected 
                                        ? Theme.of(context).primaryColor 
                                        : Colors.grey[200]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    // Set the ID to the hidden controller
                                    idController.text = vehicle['id'];
                                    
                                    // Set the plate to the display controller if provided
                                    if (plateController != null) {
                                      plateController.text = vehicle['plate'];
                                    }
                                    
                                    // Call the callback if provided
                                    if (onVehicleSelected != null) {
                                      onVehicleSelected(vehicle['id'], vehicle['plate']);
                                    }
                                    
                                    Navigator.pop(context);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                                    child: Row(
                                      children: [
                                        // Vehicle icon or indicator
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? Theme.of(context).primaryColor.withOpacity(0.1)
                                                : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.directions_car,
                                            color: isSelected 
                                                ? Theme.of(context).primaryColor 
                                                : Colors.grey[700],
                                            size: isMobile ? 20 : 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // Vehicle details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                vehicle['model'],
                                                style: TextStyle(
                                                  fontSize: isMobile ? 14 : 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected 
                                                      ? Theme.of(context).primaryColor 
                                                      : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                vehicle['plate'],
                                                style: TextStyle(
                                                  fontSize: isMobile ? 12 : 14,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              // Vehicle year display removed
                                            ],
                                          ),
                                        ),
                                        
                                        // Selection indicator
                                        Icon(
                                          isSelected 
                                              ? Icons.radio_button_checked 
                                              : Icons.radio_button_unchecked,
                                          color: isSelected 
                                              ? Theme.of(context).primaryColor 
                                              : Colors.grey[400],
                                          size: isMobile ? 20 : 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                );
                            },
                          );
                        },
                      ),
                    ),
                    
                    // Footer with action buttons
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end, // Changed from spaceBetween to end
                        children: [
                          // Vehicle count removed
                          
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              tr('common_cancel', gender: 'Vazgeç'),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  // Helper method to handle adding a contract
  static void _handleAddContract(
    BuildContext context,
    TextEditingController employeeNameCtrl,
    TextEditingController contractTypeCtrl,
    TextEditingController startDateCtrl,
    TextEditingController endDateCtrl,
    TextEditingController vehicleIdCtrl,
    Function refreshContracts,
    String? selectedEmployeeId,
    String? selectedVehiclePlate,
  ) async { // Changed to async
    // Validate inputs
    if (employeeNameCtrl.text.isEmpty ||
        contractTypeCtrl.text.isEmpty ||
        startDateCtrl.text.isEmpty ||
        endDateCtrl.text.isEmpty ||
        vehicleIdCtrl.text.isEmpty ||
        selectedEmployeeId == null ||
        selectedVehiclePlate == null) {
      InfoCard.showInfoCard(
        context,
        tr('contracts_fill_all_fields'),
        Colors.red,
        icon: Icons.error,
      );
      return;
    }
    
    // Check if user is authenticated
    final User? currentUser = ContractManagement._auth.currentUser;
    if (currentUser == null) {
      InfoCard.showInfoCard(
        context,
        tr('common_login_required'), // 'Oturum açmanız gerekiyor'
        Colors.red,
        icon: Icons.error,
      );
      return;
    }
    
    // Parse dates from DD.MM.YYYY format to DateTime
    DateTime? startDate = _parseDate(startDateCtrl.text);
    DateTime? endDate = _parseDate(endDateCtrl.text);
    
    if (startDate == null || endDate == null) {
      InfoCard.showInfoCard(
        context,
        tr('contracts_invalid_date_format'), // 'Geçersiz tarih formatı. GG.AA.YYYY formatında girin'
        Colors.red,
        icon: Icons.error,
      );
      return;
    }
    
    // Validate that start date is not after end date
    if (startDate.isAfter(endDate)) {
      InfoCard.showInfoCard(
        context,
        tr('contracts_start_after_end_error'), // 'Başlangıç tarihi bitiş tarihinden sonra olamaz'
        Colors.red,
        icon: Icons.error,
      );
      return;
    }
    
    // Check for existing active contracts for this vehicle and block if found
    bool hasExistingContract = await _hasActiveContractForVehicle(
      currentUser.uid, 
      vehicleIdCtrl.text
    );
    
    if (hasExistingContract) {
      // Show error message and prevent contract creation
      InfoCard.showInfoCard(
        context,
        tr('contracts_vehicle_already_has_contract', namedArgs: {'plate': selectedVehiclePlate}),
        Colors.red,
        icon: Icons.error,
        duration: const Duration(seconds: 5),
      );
      return; // Don't proceed with contract creation
    }
    
    // Create a unique ID for the new contract
    final contractId = uuid.v4();

    // Create a contract object
    final contract = Contract(
      id: contractId,
      employeeId: selectedEmployeeId,
      employeeName: employeeNameCtrl.text,
      vehicleId: vehicleIdCtrl.text,
      vehiclePlate: selectedVehiclePlate,
      reference: contractTypeCtrl.text, // <-- referans yerine contractTypeCtrl.text atanıyor
      startDate: startDate,
      endDate: endDate,
      status: ContractStatus.ongoing,
      createdAt: DateTime.now(),
    );

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Add the contract to Firestore
    _firestoreService.addContract(contract, currentUser.uid)
      .then((_) {
        // Close loading dialog and contract dialog
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Close contract dialog
        
        // Show success message with status info
        final statusText = contract.statusDisplayText;
        InfoCard.showInfoCard(
          context,
          tr('contracts_added_success', args: [employeeNameCtrl.text, statusText]), // '${employeeNameCtrl.text} için yeni sözleşme eklendi\nDurum: $statusText'
          Colors.green,
          icon: Icons.check_circle,
        );
        
        // Refresh contracts list
        refreshContracts();
      })
      .catchError((error) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Show error message
        InfoCard.showInfoCard(
          context,
          tr('common_error_occurred', args: [error.toString()]), // 'Hata oluştu: ${error.toString()}'
          Colors.red,
          icon: Icons.error,
        );
      });
  }
  
  // Add a new method to check for existing active contracts for a vehicle
  static Future<bool> _hasActiveContractForVehicle(String userId, String vehicleId) async {
    try {
      // Fetch all contracts for this vehicle
      final QuerySnapshot contractsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('contracts')
          .where('vehicleId', isEqualTo: vehicleId)
          .get();
      
      // Check if any contract is active (ongoing status and end date in the future)
      final now = DateTime.now();
      for (var doc in contractsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Check if status is ongoing
        final status = data['status'] as String? ?? '';
        final isOngoing = status.contains('ongoing');
        
        // Check if end date is in the future
        final endDate = data['endDate'] is Timestamp 
            ? (data['endDate'] as Timestamp).toDate()
            : null;
        
        final isActive = isOngoing && endDate != null && endDate.isAfter(now);
        
        if (isActive) {
          return true; // Found an active contract
        }
      }
      
      return false; // No active contracts found
    } catch (e) {
      print('Error checking existing contracts: $e');
      return false; // Return false on error to allow contract creation
    }
  }

  // Helper method to handle edit contract functionality
  static void _handleEditContract(
    BuildContext context,
    String contractId,
    TextEditingController employeeNameCtrl,
    TextEditingController contractTypeCtrl,
    TextEditingController startDateCtrl,
    TextEditingController endDateCtrl,
    Function refreshContracts,
    String? selectedEmployeeId,
    Map<String, dynamic> contract,
  ) {
    // Validate inputs
    if (employeeNameCtrl.text.isEmpty ||
        contractTypeCtrl.text.isEmpty ||
        startDateCtrl.text.isEmpty ||
        endDateCtrl.text.isEmpty ||
        selectedEmployeeId == null) {
      InfoCard.showInfoCard(
        context,
        tr('contracts_fill_all_fields'),
        Colors.red,
        icon: Icons.error,
      );
      return;
    }
    
    // Check if user is authenticated
    final User? currentUser = ContractManagement._auth.currentUser;
    if (currentUser == null) {
      InfoCard.showInfoCard(
        context,
        tr('common_login_required'), // 'Oturum açmanız gerekiyor'
        Colors.red,
        icon: Icons.error,
      );
      return;
    }
    
    // Parse dates from DD.MM.YYYY format to DateTime
    DateTime? startDate = _parseDate(startDateCtrl.text);
    DateTime? endDate = _parseDate(endDateCtrl.text);
    
    if (startDate == null || endDate == null) {
      InfoCard.showInfoCard(
        context,
        tr('contracts_invalid_date_format'), // 'Geçersiz tarih formatı. GG.AA.YYYY formatında girin'
        Colors.red,
        icon: Icons.error,
      );
      return;
    }
    
    // Validate that start date is not after end date
    if (startDate.isAfter(endDate)) {
      InfoCard.showInfoCard(
        context,
        tr('contracts_start_after_end_error'), // 'Başlangıç tarihi bitiş tarihinden sonra olamaz'
        Colors.red,
        icon: Icons.error,
      );
      return;
    }
    
    // --- CONTRACT TYPE FIELD DÜZENLEME ---
    // contractTypeCtrl.text firebase'de 'type' alanı olarak güncellenmeli.
    // reference alanı ayrı tutulmalı (contract['reference']).

    // Create an updated contract object
    final updatedContract = Contract(
      id: contractId,
      employeeId: selectedEmployeeId,
      employeeName: employeeNameCtrl.text,
      vehicleId: contract['vehicleId'] ?? '',
      vehiclePlate: contract['vehiclePlate'] ?? '', // Use existing plate from contract
      reference: contractTypeCtrl.text,
      startDate: startDate,
      endDate: endDate,
      status: ContractStatus.ongoing,
      createdAt: contract['createdAt'] != null
          ? DateTime.tryParse(contract['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Update the contract in Firestore
    ContractManagement._firestoreService.updateContract(updatedContract, currentUser.uid)
      .then((_) {
        // Close loading dialog and contract dialog
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Close contract dialog
        
        // Show success message with updated status info
        final statusText = updatedContract.statusDisplayText;
        InfoCard.showInfoCard(
          context,
          tr('contracts_updated_success', args: [employeeNameCtrl.text, statusText]), // '${employeeNameCtrl.text} için sözleşme güncellendi\nDurum: $statusText'
          Colors.green,
          icon: Icons.check_circle,
        );
        
        // Refresh contracts list
        refreshContracts();
      })
      .catchError((error) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Show error message
        InfoCard.showInfoCard(
          context,
          tr('common_error_occurred', args: [error.toString()]), // 'Hata oluştu: ${error.toString()}'
          Colors.red,
          icon: Icons.error,
        );
      });
  }

  // Delete contract method - change from instance method to static method
  void deleteContract(BuildContext context, Map<String, dynamic> contract, Function refreshContracts) {
    // Check if user is authenticated
    final User? currentUser = ContractManagement._auth.currentUser;
    if (currentUser == null) {
      InfoCard.showInfoCard(
        context,
        'Oturum açmanız gerekiyor',
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
    
    // Delete the contract from Firestore
    ContractManagement._firestoreService.deleteContract(contract['id'], currentUser.uid)
      .then((_) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Refresh contracts list
        refreshContracts();
      })
      .catchError((error) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Show error message
        InfoCard.showInfoCard(
          context,
          'Hata oluştu: ${error.toString()}',
          Colors.red,
          icon: Icons.error,
        );
      });
  }
  }