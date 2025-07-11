import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/employee.dart';
import '../../../services/employee_service.dart';
import '../../../services/firestore_service.dart';
import '../../../core/enums.dart';
import 'package:uuid/uuid.dart';
import '../../../info_card.dart';
import 'package:easy_localization/easy_localization.dart';

// Main class for employee management
class EmployeeManagement {
  // Responsive breakpoints
  static const double _mobileBreakpoint = 650;
  
  // Determine if we're on a mobile device
  static bool _isMobileView(BuildContext context) {
    return MediaQuery.of(context).size.width < _mobileBreakpoint;
  }

  // Method to show add/edit employee dialog
  static void addNewEmployee(BuildContext context, VoidCallback onEmployeeAdded, {Employee? editEmployee}) {
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
                  child: AddEmployeeForm(
                    onEmployeeAdded: onEmployeeAdded,
                    isMobile: isMobile,
                    editEmployee: editEmployee, // Pass employee for editing
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

// Form for adding/editing employees
class AddEmployeeForm extends StatefulWidget {
  final VoidCallback onEmployeeAdded;
  final bool isMobile;
  final Employee? editEmployee;
  
  const AddEmployeeForm({
    super.key,
    required this.onEmployeeAdded,
    required this.isMobile,
    this.editEmployee,
  });

  @override
  State<AddEmployeeForm> createState() => _AddEmployeeFormState();
}

class _AddEmployeeFormState extends State<AddEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _statusController = TextEditingController();
  EmploymentStatus _selectedStatus = EmploymentStatus.active;
  
  final _employeeService = EmployeeService();
  final _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    
    // Check if we're in edit mode by seeing if an employee was passed
    _isEditMode = widget.editEmployee != null;
    
    // If in edit mode, populate form with employee data
    if (_isEditMode) {
      _populateFormWithEmployeeData();
    } else {
      // Set default status for new employees
      _selectedStatus = EmploymentStatus.active;
      _updateStatusText(); // Set default status text
    }
  }
  
  // Populate form with employee data when in edit mode
  void _populateFormWithEmployeeData() {
    final employee = widget.editEmployee!;
    
    // Set text controllers
    _nameController.text = employee.name;
    _emailController.text = employee.email ?? '';
    _phoneController.text = employee.phone ?? '';
    
    // Set status
    _selectedStatus = employee.status;
    _updateStatusText(); // Update status text field
  }
  
  // Update the status text field based on selected status
  void _updateStatusText() {
    switch (_selectedStatus) {
      case EmploymentStatus.active:
        _statusController.text = tr('employee_status_active');
        break;
      case EmploymentStatus.terminated:
        _statusController.text = tr('employee_status_inactive');
        break;
      // Remove other cases
      default:
        _statusController.text = tr('employee_status_active');
        break;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _statusController.dispose(); // Dispose the new controller
    super.dispose();
  }

  // Save employee to Firebase
  Future<void> _saveEmployee() async {
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
        throw Exception(tr('employee_error_not_logged_in'));
      }

      // Generate unique ID for the employee or use existing if in edit mode
      final employeeId = _isEditMode ? widget.editEmployee!.id : const Uuid().v4();
      
      // Create employee object with phone field explicitly included
      final employeeData = Employee(
        id: employeeId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        position: '', // Departman ve pozisyon kaldırıldı
        departmentId: '', // Departman kaldırıldı
        status: _selectedStatus,
        createdAt: _isEditMode ? widget.editEmployee!.createdAt : DateTime.now(), // Set creation timestamp
      );

      print('Saving employee with phone: ${employeeData.phone}');

      // Save employee to Firestore
      if (_isEditMode) {
        // Update existing employee
        await _firestoreService.updateEmployee(employeeData, currentUser.uid);
        
        // Also update in-memory cache
        _employeeService.update(employeeData);
      } else {
        // Add new employee
        await _firestoreService.addEmployee(employeeData, currentUser.uid);
        
        // Also update in-memory cache
        _employeeService.add(employeeData);
      }
      
      // Notify parent and close dialog
      if (mounted) {
        widget.onEmployeeAdded();
        Navigator.of(context).pop();
        
        // Show success message
        InfoCard.showInfoCard(
          context,
          _isEditMode 
              ? tr('employee_success_update', namedArgs: {'name': employeeData.name})
              : tr('employee_success_add', namedArgs: {'name': employeeData.name}),
          Colors.green,
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _isEditMode 
              ? tr('employee_error_update', namedArgs: {'error': e.toString()})
              : tr('employee_error_add', namedArgs: {'error': e.toString()});
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

  // Show employment status selection dialog
  void _showStatusSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.isMobile ? 16 : 20),
          ),
          child: EmploymentStatusSelectionDialog(
            isMobile: widget.isMobile,
            currentStatus: _selectedStatus,
            onStatusSelected: (EmploymentStatus status) {
              setState(() {
                _selectedStatus = status;
                _updateStatusText();
              });
            },
          ),
        );
      },
    );
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
            EmployeeManagement.buildResponsiveHeader(
              context,
              _isEditMode ? 'employee_edit_title' : 'employee_add_title',
              _isEditMode ? 'employee_edit_subtitle' : 'employee_add_subtitle',
              _isEditMode ? Icons.edit_note : Icons.person_add,
              Theme.of(context).primaryColor,
              widget.isMobile,
            ),
            SizedBox(height: widget.isMobile ? 20 : 32),
            
            // Personal Information Card
            _buildFormCard(
              'employee_personal_info'.tr(),
              [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'employee_name_label'.tr(args: ['*']),
                    hintText: 'employee_name_hint'.tr(),
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
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 12 : 16,
                      vertical: widget.isMobile ? 10 : 16
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'employee_name_required'.tr();
                    }
                    final nameRegExp = RegExp(r"^[a-zA-ZğüşöçıİĞÜŞÖÇ\s]{2,}$");
                    if (!nameRegExp.hasMatch(value.trim())) {
                      return tr('employee_name_invalid_format');
                    }
                    return null;
                  },
                ),
                SizedBox(height: widget.isMobile ? 16 : 20),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'employee_email_label'.tr(),
                    hintText: 'employee_email_hint'.tr(),
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
                      Icons.email,
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
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return tr('employee_email_required');
                    }
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'employee_email_invalid'.tr();
                    }
                    return null;
                  },
                ),
                SizedBox(height: widget.isMobile ? 16 : 20),
                
                // Phone field
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'employee_phone_label'.tr(),
                    hintText: 'employee_phone_hint'.tr(),
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
                      Icons.phone,
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
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return tr('employee_phone_required');
                    }
                    final phoneRegExp = RegExp(r'^\+?\d{10,}$');
                    if (!phoneRegExp.hasMatch(value.trim())) {
                      return tr('employee_phone_invalid_format');
                    }
                    return null;
                  },
                ),
              ],
            ),
            
            SizedBox(height: widget.isMobile ? 16 : 24),
            
            // Job Information Card
            _buildFormCard(
              'employee_job_info'.tr(),
              [
                // Status field - replacing dropdown with TextFormField
                TextFormField(
                  controller: _statusController,
                  decoration: InputDecoration(
                    labelText: 'employee_status_label'.tr(),
                    hintText: 'employee_status_hint'.tr(),
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
                      Icons.how_to_reg,
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
                  readOnly: true,
                  onTap: _showStatusSelectionDialog,
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
            EmployeeManagement.buildActionButtons(
              context,
              () => Navigator.pop(context),
              _saveEmployee,
              'cancel'.tr(),
              _isEditMode ? 'employee_save_changes'.tr() : 'employee_save'.tr(),
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

// New widget to handle employment status selection
class EmploymentStatusSelectionDialog extends StatelessWidget {
  final bool isMobile;
  final EmploymentStatus currentStatus;
  final Function(EmploymentStatus) onStatusSelected;
  
  const EmploymentStatusSelectionDialog({
    Key? key,
    required this.isMobile,
    required this.currentStatus,
    required this.onStatusSelected,
  }) : super(key: key);

  // Only two statuses: Aktif and Pasif
  List<EmploymentStatus> get _statusOptions => [
    EmploymentStatus.active,
    EmploymentStatus.terminated, // Use as "Pasif"
  ];

  Map<String, dynamic> _getStatusDetails(EmploymentStatus status) {
    switch (status) {
      case EmploymentStatus.active:
        return {
          'name': tr('employee_status_active'),
          'description': tr('employee_status_active_description'),
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      case EmploymentStatus.terminated:
        return {
          'name': tr('employee_status_inactive'),
          'description': tr('employee_status_inactive_description'),
          'icon': Icons.do_not_disturb,
          'color': Colors.red,
        };
      default:
        return {
          'name': tr('employee_status_active'),
          'description': '',
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? double.infinity : 400,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * (isMobile ? 0.6 : 0.5),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'employee_status_select_title'.tr(),
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'employee_status_select_subtitle'.tr(),
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 8),
          
          // Status options list
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: _statusOptions.map((status) {
                final statusInfo = _getStatusDetails(status);
                final isSelected = status == currentStatus;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                        ? statusInfo['color'] 
                        : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected 
                        ? statusInfo['color'].withOpacity(0.1) 
                        : Colors.transparent,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        onStatusSelected(status);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusInfo['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                statusInfo['icon'],
                                color: statusInfo['color'],
                                size: isMobile ? 20 : 24,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    statusInfo['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    statusInfo['description'],
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: statusInfo['color'],
                                size: isMobile ? 20 : 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          SizedBox(height: 16),
          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              child: Text(
                'cancel'.tr(),
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}