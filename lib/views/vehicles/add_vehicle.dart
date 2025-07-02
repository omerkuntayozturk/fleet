import 'package:flutter/material.dart';
import '../../models/vehicle.dart';

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
                  : Text(submitText),
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
                cancelText,
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
              cancelText,
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
                : Text(submitText),
          ),
        ],
      );
    }
  }
}

class AddVehicleDialog extends StatelessWidget {
  final void Function(Vehicle) onAdd;
  const AddVehicleDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = VehicleManagement._isMobileView(context);

    final dialogWidth = isMobile ? screenWidth * 0.95 : screenWidth * 0.6;
    final maxHeight = isMobile ? screenHeight * 0.9 : screenHeight * 0.85;

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

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    super.dispose();
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
    try {
      final newVehicle = Vehicle(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        model: _modelController.text.trim(),
        plate: _plateController.text.trim(),
        year: int.tryParse(_yearController.text),
      );
      widget.onAdd(newVehicle);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Araç eklenirken hata: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
              'Yeni Araç Ekle',
              'Filo listenize yeni bir araç ekleyin',
              Icons.directions_car,
              Theme.of(context).primaryColor,
              widget.isMobile,
            ),
            SizedBox(height: widget.isMobile ? 20 : 32),
            _buildFormCard(
              'Araç Bilgileri',
              [
                TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: 'Model *',
                    hintText: 'Araç modelini girin',
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
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Model gerekli' : null,
                ),
                SizedBox(height: widget.isMobile ? 16 : 20),
                TextFormField(
                  controller: _plateController,
                  decoration: InputDecoration(
                    labelText: 'Plaka *',
                    hintText: 'Araç plakasını girin',
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
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Plaka gerekli' : null,
                ),
                SizedBox(height: widget.isMobile ? 16 : 20),
                TextFormField(
                  controller: _yearController,
                  decoration: InputDecoration(
                    labelText: 'Yıl *',
                    hintText: 'Araç yılı',
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
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Yıl gerekli';
                    final year = int.tryParse(v);
                    if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                      return 'Geçerli bir yıl girin';
                    }
                    return null;
                  },
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
              'İptal',
              'Ekle',
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
