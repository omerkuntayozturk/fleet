import 'package:flutter/material.dart';
import '../../models/odometer_record.dart';
import '../../services/odometer_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vehicle.dart';
import '../../services/firestore_service.dart';
import '../../models/employee.dart';
import '../../services/employee_service.dart';
import 'package:flutter/services.dart'; // Add this import for input formatters
import '../../info_card.dart'; // InfoCard importu eklendi

// Main class for odometer management
class OdometerManagement {
  // Responsive breakpoints
  static const double _mobileBreakpoint = 650;
  
  // Determine if we're on a mobile device
  static bool _isMobileView(BuildContext context) {
    return MediaQuery.of(context).size.width < _mobileBreakpoint;
  }

  // Method to show add/edit odometer dialog
  static void addNewOdometer(
    BuildContext context,
    VoidCallback onOdometerAdded, {
    OdometerRecord? editRecord,
    List<OdometerRecord>? allOdometerRecords,
    Future<void> Function(OdometerRecord newRecord)? onBeforeAdd, // <-- yeni parametre
  }) {
    // Get screen dimensions for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = _isMobileView(context);
    
    // Set the dialog width based on screen size
    final dialogWidth = isMobile 
        ? screenWidth * 0.95  // Almost full width on mobile
        : screenWidth * 0.5;  // 50% width on desktop
        
    // Set max height constraints based on screen size
    final maxHeight = isMobile 
        ? screenHeight * 0.9  // 90% of screen height on mobile
        : screenHeight * 0.8; // 80% of screen height on desktop
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: AddOdometerForm(
                    onOdometerAdded: onOdometerAdded,
                    isMobile: isMobile,
                    editRecord: editRecord,
                    allOdometerRecords: allOdometerRecords,
                    onBeforeAdd: onBeforeAdd, // <-- ekle
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Helper method to build responsive header
  static Widget buildResponsiveHeader(
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
                title.tr(),
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: isMobile ? 2 : 4),
              Text(
                subtitle.tr(),
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
  
  // Helper method to build responsive action buttons
  static Widget buildActionButtons(
    BuildContext context,
    VoidCallback onCancel,
    VoidCallback onSubmit,
    String cancelText,
    String submitText,
    Color actionColor,
    bool isMobile,
    bool isSubmitting,
  ) {
    // For mobile, stack buttons vertically
    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(submitText.tr()),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isSubmitting ? null : onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                side: BorderSide(color: Colors.grey[400]!),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: Text(
                cancelText.tr(),
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ),
        ],
      );
    } else {
      // For desktop, show buttons side by side
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: isSubmitting ? null : onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              side: BorderSide(color: Colors.grey[400]!),
            ),
            child: Text(
              cancelText.tr(),
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: isSubmitting ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: isSubmitting
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(submitText.tr()),
          ),
        ],
      );
    }
  }
}

// Form for adding/editing odometers
class AddOdometerForm extends StatefulWidget {
  final VoidCallback onOdometerAdded;
  final bool isMobile;
  final OdometerRecord? editRecord;
  final List<OdometerRecord>? allOdometerRecords;
  final Future<void> Function(OdometerRecord newRecord)? onBeforeAdd; // <-- yeni parametre

  const AddOdometerForm({
    super.key,
    required this.onOdometerAdded,
    required this.isMobile,
    this.editRecord,
    this.allOdometerRecords,
    this.onBeforeAdd, // <-- ekle
  });

  @override
  State<AddOdometerForm> createState() => _AddOdometerFormState();
}

class _AddOdometerFormState extends State<AddOdometerForm> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleIdController = TextEditingController();
  final _vehicleDisplayController = TextEditingController(); // New controller for display
  final _valueController = TextEditingController();
  final _driverController = TextEditingController(); 
  DateTime _selectedDate = DateTime.now();
  
  final _odometerService = OdometerService();
  
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isEditMode = false;
  
  // Store actual vehicleId separately from display text
  String _selectedVehicleId = '';
  
  // Add these variables to store vehicle details
  String _selectedVehicleName = '';
  String _selectedVehiclePlate = '';
  
  // Add this variable to store driver name
  String _selectedDriverName = '';

  // Add these new variables to track vehicle's last odometer reading
  double _lastOdometerValue = 0.0;
  bool _hasLastOdometerReading = false;
  bool _isLoadingLastReading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Check if we're in edit mode
    _isEditMode = widget.editRecord != null;
    
    // If in edit mode, populate form with record data
    if (_isEditMode) {
      _populateFormWithRecordData();
    }
  }
  
  // Populate form with record data when in edit mode
  void _populateFormWithRecordData() {
    final record = widget.editRecord!;
    
    // Set the actual vehicle ID
    _selectedVehicleId = record.vehicleId;
    
    // Set text controllers
    _vehicleIdController.text = record.vehicleId;
    _valueController.text = record.value.toString();
    _driverController.text = record.driver;
    
    // Set date
    _selectedDate = record.date;
    
    // Load vehicle details if in edit mode
    _loadVehicleDetails(record.vehicleId);
    
    // Set the driver name
    _selectedDriverName = record.driver;
  }
  
  // Yeni: Parent'tan gelen listedeki en yüksek km'yi bul
  double _getMaxOdometerFromList(String vehicleId) {
    if (widget.allOdometerRecords == null) return 0.0;
    final records = widget.allOdometerRecords!
        .where((r) => r.vehicleId == vehicleId)
        .toList();
    if (records.isEmpty) return 0.0;
    return records.map((r) => r.value).reduce((a, b) => a > b ? a : b);
  }

  // New method to load vehicle details and last odometer reading
  Future<void> _loadVehicleDetails(String vehicleId) async {
    if (vehicleId.isEmpty) return;
    
    setState(() {
      _isLoadingLastReading = true;
    });
    
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Fetch vehicle details
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('vehicles')
          .doc(vehicleId)
          .get();
          
      if (vehicleDoc.exists) {
        final data = vehicleDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _selectedVehicleName = data['model'] ?? '';
            _selectedVehiclePlate = data['plate'] ?? '';
            _vehicleDisplayController.text = data['plate'] ?? '';
          });
        }
      }
      
      // Firestore'dan en yüksek km
      double firestoreMax = 0.0;
      final odometerQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('odometers')
          .where('vehicleId', isEqualTo: vehicleId)
          .orderBy('value', descending: true)
          .limit(1)
          .get();
      
      if (odometerQuery.docs.isNotEmpty) {
        final lastReading = odometerQuery.docs.first.data();
        firestoreMax = lastReading['value'] is double 
            ? lastReading['value'] 
            : double.tryParse(lastReading['value'].toString()) ?? 0.0;
      }

      // Parent'tan gelen listedeki en yüksek km
      double listMax = _getMaxOdometerFromList(vehicleId);

      // Eğer edit moddaysak, mevcut kaydı hariç tut
      if (_isEditMode && widget.editRecord != null) {
        if (widget.allOdometerRecords != null) {
          final filtered = widget.allOdometerRecords!
              .where((r) => r.vehicleId == vehicleId && r.id != widget.editRecord!.id)
              .toList();
          if (filtered.isNotEmpty) {
            listMax = filtered.map((r) => r.value).reduce((a, b) => a > b ? a : b);
          } else {
            listMax = 0.0;
          }
        }
      }

      // En yüksek olanı kullan
      final maxValue = firestoreMax > listMax ? firestoreMax : listMax;

      if (mounted) {
        setState(() {
          _lastOdometerValue = maxValue;
          _hasLastOdometerReading = maxValue > 0;
          _isLoadingLastReading = false;
        });
      }
    } catch (e) {
      print('Error loading vehicle details or odometer readings: $e');
      if (mounted) {
        setState(() {
          _isLoadingLastReading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _vehicleIdController.dispose();
    _vehicleDisplayController.dispose(); // Dispose the new controller
    _valueController.dispose();
    _driverController.dispose();
    super.dispose();
  }

  // Show vehicle selection dialog
  Future<void> _showVehicleSelectionDialog() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _errorMessage = 'Kullanıcı oturumu bulunamadı';
      });
      return;
    }
    
    // Show dialog and wait for result
    final Vehicle? selectedVehicle = await showDialog<Vehicle>(
      context: context,
      builder: (BuildContext context) {
        return VehicleSelectionDialog(
          userId: currentUser.uid,
          isMobile: widget.isMobile,
        );
      },
    );
    
    // If a vehicle was selected, update the form
    if (selectedVehicle != null && mounted) {
      setState(() {
        // Reset the km value when vehicle changes
        if (_selectedVehicleId != selectedVehicle.id) {
          _valueController.text = '';
        }
        // Store the actual ID in a separate variable
        _selectedVehicleId = selectedVehicle.id;
        // Display the plate in the field
        _vehicleDisplayController.text = selectedVehicle.plate;
        _selectedVehicleName = selectedVehicle.model;
        _selectedVehiclePlate = selectedVehicle.plate;
      });
      
      // Load vehicle details and fetch last odometer reading
      await _loadVehicleDetails(selectedVehicle.id);
    }
  }

  // Show driver selection dialog
  Future<void> _showDriverSelectionDialog() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _errorMessage = 'Kullanıcı oturumu bulunamadı';
      });
      return;
    }
    
    // Show dialog and wait for result
    final Employee? selectedDriver = await showDialog<Employee>(
      context: context,
      builder: (BuildContext context) {
        return DriverSelectionDialog(
          userId: currentUser.uid,
          isMobile: widget.isMobile,
        );
      },
    );
    
    // If a driver was selected, update the form
    if (selectedDriver != null && mounted) {
      setState(() {
        _driverController.text = selectedDriver.name;
        _selectedDriverName = selectedDriver.name;
      });
    }
  }

  // Function to show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Save odometer record
  Future<void> _saveOdometerRecord() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Get current user
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Kilometre kaydı eklemek için giriş yapmalısınız');
      }
      
      // Parse odometer value
      final value = double.tryParse(_valueController.text.trim()) ?? 0.0;
      
      // Generate or use existing ID
      final String recordId = _isEditMode 
          ? widget.editRecord!.id 
          : FirebaseFirestore.instance.collection('users')
              .doc(currentUser.uid)
              .collection('odometers')
              .doc()
              .id;
      
      // Create record object using selectedVehicleId instead of controller text
      final record = OdometerRecord(
        id: recordId,
        vehicleId: _selectedVehicleId,
        driver: _driverController.text.trim(),
        date: _selectedDate,
        value: value,
      );

      // Yeni: Kayıt eklenmeden önce callback ile aynı plakalı eski kayıtları sil
      if (widget.onBeforeAdd != null) {
        await widget.onBeforeAdd!(record);
      }
      
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('odometers')
          .doc(recordId)
          .set({
            'id': recordId,
            'vehicleId': record.vehicleId,
            'driver': record.driver,
            'date': record.date,
            'value': record.value,
            'createdAt': _isEditMode ? FieldValue.serverTimestamp() : FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // For backward compatibility, still update the local service
      if (_isEditMode) {
        _odometerService.update(record);
      } else {
        _odometerService.add(record);
      }
      
      // Notify parent and close dialog
      if (mounted) {
        widget.onOdometerAdded();
        Navigator.of(context).pop();
        
        // Show success message
        InfoCard.showInfoCard(
          context,
          _isEditMode 
              ? tr('odometer_success_update')
              : tr('odometer_success_add'),
          Colors.green,
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _isEditMode 
              ? tr('odometer_error_update', namedArgs: {'error': e.toString()})
              : tr('odometer_error_add', namedArgs: {'error': e.toString()});
        });
        print('Error saving odometer record: $e');
        InfoCard.showInfoCard(
          context,
          _isEditMode
              ? tr('odometer_error_update', namedArgs: {'error': e.toString()})
              : tr('odometer_error_add', namedArgs: {'error': e.toString()}),
          Colors.red,
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Build a form card with title and content (duplicate, consider removing if not needed)
  Widget _buildFormCardDuplicate(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.isMobile ? 12 : 16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: widget.isMobile ? 14 : 16,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: widget.isMobile ? 12 : 16),
            ...children,
          ],
        ),
      ),
      );
  }


  // Duplicate build method removed to resolve the error.

  // Build a form card with title and content
  Widget _buildFormCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.isMobile ? 12 : 16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: widget.isMobile ? 14 : 16,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: widget.isMobile ? 12 : 16),
            ...children,
          ],
        ),
      ),
      );
  }

  // Validate kilometer value
  String? _validateKilometerValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr('odometer_error_value_required');
    }
    
    final numericValue = double.tryParse(value);
    if (numericValue == null) {
      return tr('odometer_error_invalid_number');
    }
    
    if (numericValue < 0) {
      return tr('odometer_error_negative_value');
    }

    // Yeni: Hem Firestore hem listedeki max değeri kontrol et
    double maxValue = _lastOdometerValue;
    // Edit modda, mevcut kaydı hariç tut
    if (_isEditMode && widget.editRecord != null) {
      double listMax = 0.0;
      if (widget.allOdometerRecords != null) {
        final filtered = widget.allOdometerRecords!
            .where((r) => r.vehicleId == _selectedVehicleId && r.id != widget.editRecord!.id)
            .toList();
        if (filtered.isNotEmpty) {
          listMax = filtered.map((r) => r.value).reduce((a, b) => a > b ? a : b);
        }
      }
      if (maxValue < listMax) maxValue = listMax;
    }

    if (maxValue > 0 && numericValue < maxValue) {
      return tr('odometer_error_value_too_low', namedArgs: {
        'value': maxValue.toStringAsFixed(0)
      });
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            OdometerManagement.buildResponsiveHeader(
              context,
              _isEditMode ? 'odometer_edit_title' : 'odometer_add_title',
              _isEditMode ? 'odometer_edit_subtitle' : 'odometer_add_subtitle',
              _isEditMode ? Icons.edit : Icons.speed,
              Theme.of(context).primaryColor,
              widget.isMobile,
            ),
            SizedBox(height: widget.isMobile ? 20 : 32),
            
            // Odometer Information Card
            _buildFormCard(
              tr('odometer_information_title'),
              [
                // Vehicle selection field - Updated to use vehicleDisplayController
                GestureDetector(
                  onTap: _showVehicleSelectionDialog,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _vehicleDisplayController, // Use the display controller
                      decoration: InputDecoration(
                        labelText: tr('odometer_field_vehicle'),
                        hintText: tr('odometer_hint_vehicle'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        prefixIcon: Icon(
                          Icons.directions_car,
                          color: Colors.grey[500],
                          size: widget.isMobile ? 18 : 24,
                        ),
                        suffixIcon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey[600],
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: widget.isMobile ? 12 : 16,
                          vertical: widget.isMobile ? 10 : 16
                        ),
                      ),
                      validator: (value) {
                        if (_selectedVehicleId.isEmpty) {
                          return tr('odometer_error_vehicle_required');
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                
                // Display selected vehicle info if available
                if (_selectedVehicleName.isNotEmpty || _selectedVehiclePlate.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Seçilen Araç: ${_selectedVehicleName} - ${_selectedVehiclePlate}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Display current odometer reading if available
                if (_isLoadingLastReading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_hasLastOdometerReading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.speed, size: 16, color: Colors.amber.shade800),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Mevcut km: ${_lastOdometerValue.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                SizedBox(height: widget.isMobile ? 16 : 20),
                
                // Driver field - Modified to be read-only and trigger selection dialog
                GestureDetector(
                  onTap: _showDriverSelectionDialog,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _driverController,
                      decoration: InputDecoration(
                        labelText: tr('odometer_field_driver'),
                        hintText: tr('odometer_hint_driver'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        prefixIcon: Icon(
                          Icons.person,
                          color: Colors.grey[500],
                          size: widget.isMobile ? 18 : 24,
                        ),
                        suffixIcon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey[600],
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: widget.isMobile ? 12 : 16,
                          vertical: widget.isMobile ? 10 : 16
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Display selected driver info if available
                if (_selectedDriverName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.green.shade700),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Seçilen Sürücü: ${_selectedDriverName}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                SizedBox(height: widget.isMobile ? 16 : 20),
                
                // Odometer value field - Updated with validation and input formatters
                TextFormField(
                  controller: _valueController,
                  decoration: InputDecoration(
                    labelText: tr('odometer_field_value'),
                    hintText: _hasLastOdometerReading 
                        ? tr('odometer_hint_value_with_last', namedArgs: {'value': _lastOdometerValue.toStringAsFixed(0)})
                        : tr('odometer_hint_value'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    prefixIcon: Icon(
                      Icons.speed,
                      color: Colors.grey[500],
                      size: widget.isMobile ? 18 : 24,
                    ),
                    suffixText: tr('odometer_unit_km'),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 12 : 16,
                      vertical: widget.isMobile ? 10 : 16
                    ),
                    helperText: _hasLastOdometerReading 
                        ? "Son okuma: ${_lastOdometerValue.toStringAsFixed(0)}"
                        : tr('odometer_helper_first_reading'),
                    helperStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: _validateKilometerValue,
                  inputFormatters: [
                    // Allow only numbers and a single decimal point
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                ),
                
                SizedBox(height: widget.isMobile ? 16 : 20),
                
                // Date field
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: tr('odometer_field_date'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: Colors.grey[500],
                        size: widget.isMobile ? 18 : 24,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: widget.isMobile ? 12 : 16,
                        vertical: widget.isMobile ? 10 : 16
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                          style: TextStyle(
                            fontSize: widget.isMobile ? 14 : 16,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Error message
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: widget.isMobile ? 16 : 24),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: widget.isMobile ? 24 : 32),
            
            // Action buttons
            OdometerManagement.buildActionButtons(
              context,
              () => Navigator.pop(context),
              _saveOdometerRecord,
              'odometer_button_cancel',
              _isEditMode ? 'odometer_button_update' : 'odometer_button_save',
              Theme.of(context).primaryColor,
              widget.isMobile,
              _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}

// New widget for vehicle selection dialog
class VehicleSelectionDialog extends StatefulWidget {
  final String userId;
  final bool isMobile;
  
  const VehicleSelectionDialog({
    Key? key,
    required this.userId,
    required this.isMobile,
  }) : super(key: key);

  @override
  State<VehicleSelectionDialog> createState() => _VehicleSelectionDialogState();
}

class _VehicleSelectionDialogState extends State<VehicleSelectionDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadVehicles();
    
    _searchController.addListener(() {
      _filterVehicles();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Load vehicles from Firestore
  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final vehicles = await _firestoreService.fetchVehiclesWithDetails(userId: widget.userId);
      
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _filteredVehicles = vehicles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Araçlar yüklenirken hata oluştu: $e';
          _isLoading = false;
        });
      }
      print('Error loading vehicles: $e');
    }
  }
  
  // Filter vehicles based on search input
  void _filterVehicles() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredVehicles = _vehicles;
      } else {
        _filteredVehicles = _vehicles.where((vehicle) {
          return vehicle.model.toLowerCase().contains(query) ||
                 vehicle.plate.toLowerCase().contains(query) ||
                 (vehicle.year?.toString().contains(query) ?? false);
        }).toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final dialogWidth = widget.isMobile 
        ? screenWidth * 0.95
        : screenWidth * 0.5;
        
    final dialogHeight = widget.isMobile
        ? screenHeight * 0.7
        : screenHeight * 0.6;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.isMobile ? 16 : 20),
      ),
      elevation: 8,
      insetPadding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 10 : 40,
        vertical: widget.isMobile ? 24 : 40,
      ),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: Theme.of(context).primaryColor,
                  size: widget.isMobile ? 24 : 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('vehicle_selection_title'),
                    style: TextStyle(
                      fontSize: widget.isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr('vehicle_search_hint'),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.isMobile ? 12 : 16,
                  vertical: widget.isMobile ? 10 : 12,
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Vehicle list
            Expanded(
              child: _buildVehicleList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVehicleList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadVehicles,
              child: Text(tr('button_retry')),
            ),
          ],
        ),
      );
    }
    
    if (_filteredVehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_filled, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? tr('vehicle_empty_list')
                  : tr('vehicle_no_search_results'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _filteredVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _filteredVehicles[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop(vehicle);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.directions_car, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.model,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          vehicle.plate,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (vehicle.year != null)
                          Text(
                            'Yıl: ${vehicle.year}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// New widget for driver selection dialog
class DriverSelectionDialog extends StatefulWidget {
  final String userId;
  final bool isMobile;
  
  const DriverSelectionDialog({
    Key? key,
    required this.userId,
    required this.isMobile,
  }) : super(key: key);

  @override
  State<DriverSelectionDialog> createState() => _DriverSelectionDialogState();
}

class _DriverSelectionDialogState extends State<DriverSelectionDialog> {
  final EmployeeService _employeeService = EmployeeService();
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadEmployees();
    
    _searchController.addListener(() {
      _filterEmployees();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Load employees from Firestore
  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final employees = await _employeeService.getAll();
      
      if (mounted) {
        setState(() {
          _employees = employees;
          _filteredEmployees = employees;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sürücüler yüklenirken hata oluştu: $e';
          _isLoading = false;
        });
      }
      print('Error loading employees: $e');
    }
  }
  
  // Filter employees based on search input
  void _filterEmployees() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees.where((employee) {
          return employee.name.toLowerCase().contains(query) ||
                 (employee.email?.toLowerCase().contains(query) ?? false) ||
                 (employee.phone?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final dialogWidth = widget.isMobile 
        ? screenWidth * 0.95
        : screenWidth * 0.5;
        
    final dialogHeight = widget.isMobile
        ? screenHeight * 0.7
        : screenHeight * 0.6;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.isMobile ? 16 : 20),
      ),
      elevation: 8,
      insetPadding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 10 : 40,
        vertical: widget.isMobile ? 24 : 40,
      ),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                  size: widget.isMobile ? 24 : 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('driver_selection_title'),
                    style: TextStyle(
                      fontSize: widget.isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr('driver_search_hint'),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.isMobile ? 12 : 16,
                  vertical: widget.isMobile ? 10 : 12,
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Employee list
            Expanded(
              child: _buildEmployeeList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmployeeList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadEmployees,
              child: Text(tr('button_retry')),
            ),
          ],
        ),
      );
    }
    
    if (_filteredEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? tr('driver_empty_list')
                  : tr('driver_no_search_results'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop(employee);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.person, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (employee.position.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              employee.position,
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        if (employee.phone != null && employee.phone!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              employee.phone!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (employee.email != null && employee.email!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              employee.email!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
