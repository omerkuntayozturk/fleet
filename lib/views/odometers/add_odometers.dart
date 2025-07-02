import 'package:flutter/material.dart';
import '../../models/odometer_record.dart';
import '../../services/odometer_service.dart';
import 'package:easy_localization/easy_localization.dart';

// Main class for odometer management
class OdometerManagement {
  // Responsive breakpoints
  static const double _mobileBreakpoint = 650;
  
  // Determine if we're on a mobile device
  static bool _isMobileView(BuildContext context) {
    return MediaQuery.of(context).size.width < _mobileBreakpoint;
  }

  // Method to show add/edit odometer dialog
  static void addNewOdometer(BuildContext context, VoidCallback onOdometerAdded, {OdometerRecord? editRecord}) {
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
                    editRecord: editRecord, // Pass record for editing
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
  
  const AddOdometerForm({
    super.key,
    required this.onOdometerAdded,
    required this.isMobile,
    this.editRecord,
  });

  @override
  State<AddOdometerForm> createState() => _AddOdometerFormState();
}

class _AddOdometerFormState extends State<AddOdometerForm> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleIdController = TextEditingController();
  final _valueController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  final _odometerService = OdometerService();
  
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isEditMode = false;

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
    
    // Set text controllers
    _vehicleIdController.text = record.vehicleId;
    _valueController.text = record.value.toString();
    
    // Set date
    _selectedDate = record.date;
  }

  @override
  void dispose() {
    _vehicleIdController.dispose();
    _valueController.dispose();
    super.dispose();
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
      // Parse odometer value
      final value = double.tryParse(_valueController.text.trim()) ?? 0.0;
      
      // Create record object
      final record = OdometerRecord(
        id: _isEditMode ? widget.editRecord!.id : DateTime.now().toIso8601String(),
        vehicleId: _vehicleIdController.text.trim(),
        date: _selectedDate,
        value: value,
      );
      
      // Save record
      if (_isEditMode) {
        // Update existing record
        _odometerService.update(record);
      } else {
        // Add new record
        _odometerService.add(record);
      }
      
      // Notify parent and close dialog
      if (mounted) {
        widget.onOdometerAdded();
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode 
                ? 'Kilometre kaydı başarıyla güncellendi' 
                : 'Kilometre kaydı başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _isEditMode 
              ? 'Kilometre kaydı güncellenirken hata: $e' 
              : 'Kilometre kaydı eklenirken hata: $e';
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
            OdometerManagement.buildResponsiveHeader(
              context,
              _isEditMode ? 'Kilometre Kaydını Düzenle' : 'Yeni Kilometre Kaydı',
              _isEditMode ? 'Mevcut kaydı güncelleyin' : 'Yeni kilometre kaydı ekleyin',
              _isEditMode ? Icons.edit : Icons.speed,
              Theme.of(context).primaryColor,
              widget.isMobile,
            ),
            SizedBox(height: widget.isMobile ? 20 : 32),
            
            // Odometer Information Card
            _buildFormCard(
              'Kilometre Bilgileri',
              [
                // Vehicle ID field
                TextFormField(
                  controller: _vehicleIdController,
                  decoration: InputDecoration(
                    labelText: 'Araç ID *',
                    hintText: 'Araç ID\'sini girin',
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
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 12 : 16,
                      vertical: widget.isMobile ? 10 : 16
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Araç ID zorunludur';
                    }
                    return null;
                  },
                ),
                SizedBox(height: widget.isMobile ? 16 : 20),
                
                // Odometer value field
                TextFormField(
                  controller: _valueController,
                  decoration: InputDecoration(
                    labelText: 'Kilometre Değeri *',
                    hintText: 'Kilometre değerini girin',
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
                    suffixText: 'km',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 12 : 16,
                      vertical: widget.isMobile ? 10 : 16
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kilometre değeri zorunludur';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Geçerli bir sayı giriniz';
                    }
                    return null;
                  },
                ),
                SizedBox(height: widget.isMobile ? 16 : 20),
                
                // Date field
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tarih *',
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
              'İptal',
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
