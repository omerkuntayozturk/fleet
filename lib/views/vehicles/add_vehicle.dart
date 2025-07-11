import 'package:flutter/material.dart';
import '../../models/vehicle.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // Add this import for input formatters
import 'package:easy_localization/easy_localization.dart'; // Add Easy Localization import

// Responsive breakpoints ve yardımcı fonksiyonlar
class VehicleManagement {
  static const double _mobileBreakpoint = 650;

  static bool _isMobileView(BuildContext context) {
    return MediaQuery.of(context).size.width < _mobileBreakpoint;
  }

  static void showAddVehicleDialog(BuildContext context, void Function(Vehicle) onAdd) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = _isMobileView(context);

    final dialogWidth = isMobile ? screenWidth * 0.95 : screenWidth * 0.6;
    final maxHeight = isMobile ? screenHeight * 0.9 : screenHeight * 0.85;

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
            vertical: isMobile ? 10 : 24,
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
                  child: AddVehicleForm(
                    onAdd: onAdd,
                    isMobile: isMobile,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showEditVehicleDialog(BuildContext context, Vehicle vehicle, void Function(Vehicle) onUpdate) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = _isMobileView(context);

    final dialogWidth = isMobile ? screenWidth * 0.95 : screenWidth * 0.6;
    final maxHeight = isMobile ? screenHeight * 0.9 : screenHeight * 0.85;

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
            vertical: isMobile ? 10 : 24,
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
                  child: EditVehicleForm(
                    vehicle: vehicle,
                    onUpdate: onUpdate,
                    isMobile: isMobile,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

class AddVehicleDialog extends StatefulWidget {
  final Function(Vehicle) onAdd;

  const AddVehicleDialog({super.key, required this.onAdd});

  @override
  State<AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<AddVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _yearController = TextEditingController();
  
  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('vehicle_add_title'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      labelText: tr('vehicle_field_model'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.directions_car),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return tr('vehicle_error_model_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _plateController,
                    decoration: InputDecoration(
                      labelText: tr('vehicle_field_plate'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.pin),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return tr('vehicle_error_plate_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _yearController,
                    decoration: InputDecoration(
                      labelText: tr('vehicle_field_year'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final year = int.tryParse(value);
                        if (year == null) {
                          return tr('vehicle_error_year_invalid');
                        }
                        if (year < 1900 || year > DateTime.now().year + 1) {
                          return tr('vehicle_error_year_range');
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('vehicle_button_cancel')),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Generate a temporary ID - it will be replaced by Firestore
                      final String tempId = DateTime.now().millisecondsSinceEpoch.toString();
                      
                      // Create a new vehicle with the form data
                      final Vehicle newVehicle = Vehicle(
                        id: tempId,
                        model: _modelController.text,
                        plate: _plateController.text,
                        year: _yearController.text.isNotEmpty ? int.parse(_yearController.text) : null,
                      );
                      
                      // Call the onAdd callback with the new vehicle
                      widget.onAdd(newVehicle);
                      
                      // Close the dialog
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(tr('vehicle_button_save')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddVehicleForm extends StatefulWidget {
  final void Function(Vehicle) onAdd;
  final bool isMobile;
  const AddVehicleForm({Key? key, required this.onAdd, required this.isMobile}) : super(key: key);

  @override
  State<AddVehicleForm> createState() => _AddVehicleFormState();
}

class _AddVehicleFormState extends State<AddVehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _plateExistsError = false;

  @override
  void initState() {
    super.initState();
    _plateController.addListener(() {
      if (_plateExistsError) {
        setState(() {
          _plateExistsError = false;
        });
        // Sadece plaka alanını yeniden doğrula
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
      }
    });
  }

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  // Plaka normalize fonksiyonu (büyük harf, boşluk sil)
  String _normalizePlate(String plate) {
    return plate.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }

  // Add input formatters and validation rules
  String? _validateModel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr('vehicle_error_model_required');
    }
    if (value.trim().length < 2) {
      return tr('vehicle_error_model_min_length');
    }
    if (value.trim().length > 50) {
      return tr('vehicle_error_model_max_length');
    }
    return null;
  }

  String? _validatePlate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr('vehicle_error_plate_required');
    }
    final plateRegex = RegExp(r'^[0-9]{1,2}\s*[A-Za-z]{1,3}\s*[0-9]{1,4}$');
    if (!plateRegex.hasMatch(value.trim())) {
      return tr('vehicle_error_plate_format');
    }
    if (_plateExistsError) {
      return tr('vehicle_error_plate_exists');
    }
    return null;
  }

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr('vehicle_error_year_required');
    }
    
    // Sadece sayı kontrolü
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return tr('vehicle_error_year_numeric');
    }
    
    final year = int.tryParse(value);
    if (year == null) {
      return tr('vehicle_error_year_invalid');
    }
    
    final currentYear = DateTime.now().year;
    if (year < 1900) {
      return tr('vehicle_error_year_min');
    }
    if (year > currentYear + 1) {
      return tr('vehicle_error_year_max', namedArgs: {'year': (currentYear + 1).toString()});
    }
    
    return null;
  }

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

  Future<void> _saveVehicle() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final currentContext = context;

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception(tr('vehicle_error_login_required'));
      }

      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('vehicles')
          .get();

      final newPlateNorm = _normalizePlate(_plateController.text);

      bool plateExists = vehiclesSnapshot.docs.any((doc) {
        final data = doc.data();
        final existingPlate = data['plate'] ?? '';
        return _normalizePlate(existingPlate) == newPlateNorm;
      });

      if (plateExists) {
        setState(() {
          _isSubmitting = false;
          _plateExistsError = true;
        });
        // Sadece plaka alanını yeniden doğrula
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
        return;
      } else {
        // Plaka çakışması yoksa hata sıfırlanır
        if (_plateExistsError) {
          setState(() {
            _plateExistsError = false;
          });
        }
      }

      // 2. Araç ekleme işlemi
      final String vehicleId = FirebaseFirestore.instance.collection('users')
          .doc(currentUser.uid)
          .collection('vehicles')
          .doc()
          .id;

      final newVehicle = Vehicle(
        id: vehicleId,
        model: _modelController.text.trim(),
        plate: _plateController.text.trim(),
        year: int.tryParse(_yearController.text),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('vehicles')
          .doc(vehicleId)
          .set({
            'id': vehicleId,
            'model': newVehicle.model,
            'plate': newVehicle.plate,
            'year': newVehicle.year,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      widget.onAdd(newVehicle);

      if (mounted) {
        Navigator.of(currentContext).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = tr('vehicle_error_save', namedArgs: {'error': e.toString()});
          _isSubmitting = false;
        });
      }
      print('Error saving vehicle: $e');
    }
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
            VehicleManagement.buildResponsiveHeader(
              context,
              'vehicle_add_title',
              'vehicle_add_subtitle',
              Icons.directions_car,
              Theme.of(context).primaryColor,
              widget.isMobile,
            ),
            SizedBox(height: widget.isMobile ? 20 : 32),
            _buildFormCard(
              tr('vehicle_information_title'),
              [
                TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: tr('vehicle_field_model_required'),
                    hintText: tr('vehicle_hint_model'),
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
                      Icons.directions_car_outlined,
                      color: Colors.grey[500],
                      size: widget.isMobile ? 18 : 24,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 12 : 16,
                      vertical: widget.isMobile ? 10 : 16,
                    ),
                  ),
                  validator: _validateModel,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                ),
                SizedBox(height: widget.isMobile ? 16 : 20),
                TextFormField(
                  controller: _plateController,
                  decoration: InputDecoration(
                    labelText: tr('vehicle_field_plate_required'),
                    hintText: tr('vehicle_hint_plate'),
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
                      Icons.confirmation_number_outlined,
                      color: Colors.grey[500],
                      size: widget.isMobile ? 18 : 24,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 12 : 16,
                      vertical: widget.isMobile ? 10 : 16,
                    ),
                  ),
                  validator: _validatePlate,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    // Alfanumerik karakterlere izin ver
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z\s]')),
                  ],
                ),
                SizedBox(height: widget.isMobile ? 16 : 20),
                TextFormField(
                  controller: _yearController,
                  decoration: InputDecoration(
                    labelText: tr('vehicle_field_year_required'),
                    hintText: tr('vehicle_hint_year', namedArgs: {'year': DateTime.now().year.toString()}),
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
                      Icons.calendar_today_outlined,
                      color: Colors.grey[500],
                      size: widget.isMobile ? 18 : 24,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 12 : 16,
                      vertical: widget.isMobile ? 10 : 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateYear,
                  inputFormatters: [
                    // Sadece sayılara izin ver
                    FilteringTextInputFormatter.digitsOnly,
                    // Maksimum 4 basamaklı sayı
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ],
            ),
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
            VehicleManagement.buildActionButtons(
              context,
              () => Navigator.pop(context),
              _saveVehicle,
              'vehicle_button_cancel',
              'vehicle_button_add',
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

// Add this new class after the AddVehicleForm class
class EditVehicleForm extends StatefulWidget {
  final Vehicle vehicle;
  final void Function(Vehicle) onUpdate;
  final bool isMobile;
  
  const EditVehicleForm({
    Key? key, 
    required this.vehicle, 
    required this.onUpdate, 
    required this.isMobile
  }) : super(key: key);

  @override
  State<EditVehicleForm> createState() => _EditVehicleFormState();
}

class _EditVehicleFormState extends State<EditVehicleForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _modelController;
  late TextEditingController _plateController;
  late TextEditingController _yearController;

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _plateExistsError = false; // Plaka çakışma hatası için

  @override
  void initState() {
    super.initState();
    _modelController = TextEditingController(text: widget.vehicle.model);
    _plateController = TextEditingController(text: widget.vehicle.plate);
    _yearController = TextEditingController(text: widget.vehicle.year?.toString() ?? '');

    _plateController.addListener(() {
      if (_plateExistsError) {
        setState(() {
          _plateExistsError = false;
        });
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
      }
    });
  }

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  // Plaka normalize fonksiyonu (büyük harf, boşluk sil)
  String _normalizePlate(String plate) {
    return plate.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }

  // Add the same validation methods
  String? _validateModel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr('vehicle_error_model_required');
    }
    if (value.trim().length < 2) {
      return tr('vehicle_error_model_min_length');
    }
    if (value.trim().length > 50) {
      return tr('vehicle_error_model_max_length');
    }
    return null;
  }

  String? _validatePlate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr('vehicle_error_plate_required');
    }
    
    // Türk plaka formatı için basit bir regex
    // İl kodu (1-81) + harf(lar) + rakam(lar)
    final plateRegex = RegExp(r'^[0-9]{1,2}\s*[A-Za-z]{1,3}\s*[0-9]{1,4}$');
    if (!plateRegex.hasMatch(value.trim())) {
      return tr('vehicle_error_plate_format');
    }
    if (_plateExistsError) {
      return tr('vehicle_error_plate_exists');
    }
    return null;
  }

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr('vehicle_error_year_required');
    }
    
    // Sadece sayı kontrolü
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return tr('vehicle_error_year_numeric');
    }
    
    final year = int.tryParse(value);
    if (year == null) {
      return tr('vehicle_error_year_invalid');
    }
    
    final currentYear = DateTime.now().year;
    if (year < 1900) {
      return tr('vehicle_error_year_min');
    }
    if (year > currentYear + 1) {
      return tr('vehicle_error_year_max', namedArgs: {'year': (currentYear + 1).toString()});
    }
    
    return null;
  }

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

  Future<void> _updateVehicle() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    // Store context reference before async operation
    final currentContext = context;
    
    try {
      // Get current user
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception(tr('vehicle_error_login_required'));
      }
      
      // Plaka çakışma kontrolü (kendi kaydı hariç)
      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('vehicles')
          .get();

      final newPlateNorm = _normalizePlate(_plateController.text);
      final currentVehicleId = widget.vehicle.id;

      bool plateExists = vehiclesSnapshot.docs.any((doc) {
        final data = doc.data();
        final existingPlate = data['plate'] ?? '';
        final existingId = data['id'] ?? doc.id;
        return existingId != currentVehicleId && _normalizePlate(existingPlate) == newPlateNorm;
      });

      if (plateExists) {
        setState(() {
          _isSubmitting = false;
          _plateExistsError = true;
        });
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
        return;
      } else {
        if (_plateExistsError) {
          setState(() {
            _plateExistsError = false;
          });
        }
      }

      // Create updated vehicle object
      final updatedVehicle = Vehicle(
        id: widget.vehicle.id,
        model: _modelController.text.trim(),
        plate: _plateController.text.trim(),
        year: int.tryParse(_yearController.text),
      );
      
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('vehicles')
          .doc(widget.vehicle.id)
          .update({
            'model': updatedVehicle.model,
            'plate': updatedVehicle.plate,
            'year': updatedVehicle.year,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // Call the onUpdate callback with the updated vehicle
      widget.onUpdate(updatedVehicle);
      
      // Check if still mounted before popping
      if (mounted) {
        Navigator.of(currentContext).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = tr('vehicle_error_update', namedArgs: {'error': e.toString()});
          _isSubmitting = false;
        });
      }
      print('Error updating vehicle: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if this is a new vehicle (adding) or existing vehicle (editing)
    final isNewVehicle = widget.vehicle.id.startsWith('new_');
    final headerTitle = isNewVehicle ? 'Yeni Araç Ekle' : 'Araç Düzenle';
    final headerSubtitle = isNewVehicle ? 'Filo listenize yeni bir araç ekleyin' : 'Araç bilgilerini güncelleyin';

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VehicleManagement.buildResponsiveHeader(
              context,
              headerTitle,
              headerSubtitle,
              Icons.directions_car,
              Theme.of(context).primaryColor,
              widget.isMobile,
            ),
            SizedBox(height: widget.isMobile ? 20 : 32),
            _buildFormCard(
              tr('vehicle_information_title'),
              [
                TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: tr('vehicle_field_model_required'),
                    hintText: tr('vehicle_hint_model'),
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
                      Icons.directions_car_outlined,
                      color: Colors.grey[500],
                      size: widget.isMobile ? 18 : 24,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 12 : 16,
                      vertical: widget.isMobile ? 10 : 16,
                    ),
                  ),
                  validator: _validateModel,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                ),
                SizedBox(height: widget.isMobile ? 16 : 20),
                TextFormField(
                  controller: _plateController,
                  decoration: InputDecoration(
                    labelText: tr('vehicle_field_plate_required'),
                    hintText: tr('vehicle_hint_plate'),
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
                      Icons.confirmation_number_outlined,
                      color: Colors.grey[500],
                      size: widget.isMobile ? 18 : 24,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 12 : 16,
                      vertical: widget.isMobile ? 10 : 16,
                    ),
                  ),
                  validator: _validatePlate,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    // Alfanumerik karakterlere izin ver
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z\s]')),
                  ],
                ),
                SizedBox(height: widget.isMobile ? 16 : 20),
                TextFormField(
                  controller: _yearController,
                  decoration: InputDecoration(
                    labelText: tr('vehicle_field_year_required'),
                    hintText: tr('vehicle_hint_year', namedArgs: {'year': DateTime.now().year.toString()}),
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
                      Icons.calendar_today_outlined,
                      color: Colors.grey[500],
                      size: widget.isMobile ? 18 : 24,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 12 : 16,
                      vertical: widget.isMobile ? 10 : 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateYear,
                  inputFormatters: [
                    // Sadece sayılara izin ver
                    FilteringTextInputFormatter.digitsOnly,
                    // Maksimum 4 basamaklı sayı
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ],
            ),
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
            VehicleManagement.buildActionButtons(
              context,
              () => Navigator.pop(context),
              _updateVehicle,
              'vehicle_button_cancel',
              isNewVehicle ? 'vehicle_button_add' : 'vehicle_button_update',
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
