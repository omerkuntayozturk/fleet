import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/service_entry.dart';
import '../../services/service_service.dart';
import '../../services/vehicle_service.dart';
import '../../services/firestore_service.dart';
import '../../info_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';
import '../../models/vehicle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Main class for service management
class ServiceManagement {
  // Responsive breakpoints
  static const double _mobileBreakpoint = 650;
  
  // Determine if we're on a mobile device
  static bool _isMobileView(BuildContext context) {
    return MediaQuery.of(context).size.width < _mobileBreakpoint;
  }

  // Method to show add/edit service dialog
  static void addNewService(BuildContext context, VoidCallback onServiceAdded, {ServiceEntry? editService}) {
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
                  child: AddServiceForm(
                    onServiceAdded: onServiceAdded,
                    isMobile: isMobile,
                    editService: editService, // Pass service for editing
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

// Form for adding/editing services
class AddServiceForm extends StatefulWidget {
  final VoidCallback onServiceAdded;
  final bool isMobile;
  final ServiceEntry? editService;
  
  const AddServiceForm({
    super.key,
    required this.onServiceAdded,
    required this.isMobile,
    this.editService,
  });

  @override
  State<AddServiceForm> createState() => _AddServiceFormState();
}

class _AddServiceFormState extends State<AddServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _serviceTypeController = TextEditingController();
  final _vehicleIdController = TextEditingController(); // Keep for backward compatibility
  final _vehicleDisplayController = TextEditingController(); // New controller for display
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _serviceDate = DateTime.now();
  
  final _serviceService = ServiceService();
  final _vehicleService = VehicleService();
  final _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isEditMode = false;

  // Store actual vehicleId separately from display text
  String _selectedVehicleId = '';
  
  // Add these variables to store vehicle details
  String _selectedVehicleName = '';
  String _selectedVehiclePlate = '';

  @override
  void initState() {
    super.initState();
    
    // Check if we're in edit mode by seeing if a service was passed
    _isEditMode = widget.editService != null;
    
    // Load available vehicles
    _loadVehicles();
    
    // If in edit mode, populate form with service data
    if (_isEditMode) {
      _populateFormWithServiceData();
    }
  }
  
  // Load available vehicles
  // Load available vehicles
  void _loadVehicles() {
    final vehicles = _vehicleService.getAll();
    final vehicleModelMap = <String, String>{};
    
    for (var vehicle in vehicles) {
      vehicleModelMap[vehicle.id] = vehicle.model;
    }
    
    setState(() {
    });
  }
  // New method to load vehicle details
  Future<void> _loadVehicleDetails(String vehicleId) async {
    if (vehicleId.isEmpty) return;
    
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
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
          });
        }
      }
    } catch (e) {
      print('Error loading vehicle details: $e');
    }
  }
  
  // Populate form with service data when in edit mode
  void _populateFormWithServiceData() {
    final service = widget.editService!;
    
    // Set text controllers
    _serviceTypeController.text = service.serviceType;
    _costController.text = service.cost.toString();
    
    // Store the actual vehicle ID
    _selectedVehicleId = service.vehicleId;
    _vehicleIdController.text = service.vehicleId;
    
    // Set notes
    _notesController.text = service.notes;
    
    // Set date
    setState(() {
      _serviceDate = service.date;
    });
    
    // Load vehicle details
    _loadVehicleDetails(service.vehicleId);
  }

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _vehicleIdController.dispose();
    _vehicleDisplayController.dispose(); // Dispose the new controller
    _costController.dispose();
    _notesController.dispose();
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
        // Store the actual ID in a separate variable
        _selectedVehicleId = selectedVehicle.id;
        // Display the plate in the field
        _vehicleDisplayController.text = selectedVehicle.plate;
        _selectedVehicleName = selectedVehicle.model;
        _selectedVehiclePlate = selectedVehicle.plate;
      });
    }
  }

  // Save service to Firebase
  Future<void> _saveService() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturum açmamış!');
      }

      // Generate unique ID for the service or use existing if in edit mode
      final serviceId = _isEditMode ? widget.editService!.id : const Uuid().v4();
      
      // Parse cost - handle invalid input
      final cost = double.tryParse(_costController.text.trim()) ?? 0.0;
      
      // Create service object using _selectedVehicleId instead of controller text
      final serviceData = ServiceEntry(
        id: serviceId,
        vehicleId: _selectedVehicleId,
        date: _serviceDate,
        serviceType: _serviceTypeController.text.trim(),
        cost: cost,
        notes: _notesController.text.trim(),
      );

      // Save service to Firestore
      if (_isEditMode) {
        // Update existing service (using addService since updateService doesn't exist)
        await _firestoreService.addService(serviceData, currentUser.uid);
        
        // Also update in-memory cache
        _serviceService.update(serviceData);
      } else {
        // Add new service
        await _firestoreService.addService(serviceData, currentUser.uid);
        
        // Also update in-memory cache
        _serviceService.add(serviceData);
      }
      
      // Notify parent and close dialog
      if (mounted) {
        widget.onServiceAdded();
        Navigator.of(context).pop();
        
        // Show success message
        InfoCard.showInfoCard(
          context,
          _isEditMode 
              ? 'Servis kaydı başarıyla güncellendi' 
              : 'Servis kaydı başarıyla eklendi',
          Colors.green,
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _isEditMode 
              ? 'Servis güncellenirken hata: $e' 
              : 'Servis eklenirken hata: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _serviceDate) {
      setState(() {
        _serviceDate = picked;
      });
    }
  }

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

  // Format date for display
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
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
            ServiceManagement.buildResponsiveHeader(
              context,
              _isEditMode ? 'service_edit_title' : 'service_add_title',
              _isEditMode ? 'service_edit_subtitle' : 'service_add_subtitle',
              _isEditMode ? Icons.edit_note : Icons.build,
              Theme.of(context).primaryColor,
              widget.isMobile,
            ),
            SizedBox(height: widget.isMobile ? 20 : 32),
            
            // Service Information Card
            _buildFormCard(
              'Servis Bilgileri',
              [
                // Service type field
                TextFormField(
                  controller: _serviceTypeController,
                  decoration: InputDecoration(
                    labelText: 'Servis Türü *',
                    hintText: 'Örn: Yağ Değişimi, Lastik Değişimi',
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
                      Icons.miscellaneous_services,
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Servis türü gereklidir';
                    }
                    return null;
                  },
                ),
                SizedBox(height: widget.isMobile ? 16 : 20),
                
                // Vehicle selection field - Updated to use vehicleDisplayController
                GestureDetector(
                  onTap: _showVehicleSelectionDialog,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _vehicleDisplayController, // Use display controller instead of vehicleIdController
                      decoration: InputDecoration(
                        labelText: 'Araç Seçimi *',
                        hintText: 'Araç seçmek için tıklayın',
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
                          return 'Araç seçimi zorunludur';
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
                              'Seçilen araç: $_selectedVehicleName ($_selectedVehiclePlate)',
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
                
                SizedBox(height: widget.isMobile ? 16 : 20),
                
                // Date field
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Servis Tarihi *',
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
                        Text(_formatDate(_serviceDate)),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey[500],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: widget.isMobile ? 16 : 24),
            
            // Cost and Notes Card
            _buildFormCard(
              'Maliyet ve Notlar',
              [
                // Cost field
                TextFormField(
                  controller: _costController,
                  decoration: InputDecoration(
                    labelText: 'Maliyet (TL) *',
                    hintText: 'Servis maliyetini girin',
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
                      Icons.attach_money,
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
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Maliyet gereklidir';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Geçerli bir sayı girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: widget.isMobile ? 16 : 20),
                
                // Notes field
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notlar',
                    hintText: 'Ek bilgiler veya notlar ekleyin',
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
                      Icons.note,
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
                  maxLines: 3,
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
            ServiceManagement.buildActionButtons(
              context,
              () => Navigator.pop(context),
              _saveService,
              'cancel',
              _isEditMode ? 'Güncelle' : 'Kaydet',
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
                    'Araç Seçimi',
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
                hintText: 'Araç ara (model, plaka veya yıl)',
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
              child: Text('Yeniden Dene'),
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
                  ? 'Henüz araç eklenmemiş'
                  : 'Aramalara uygun araç bulunamadı',
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