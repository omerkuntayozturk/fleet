import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfileEditDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const ProfileEditDialog({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController departmentController;
  late TextEditingController positionController;
  late TextEditingController addressController;
  late TextEditingController birthDateController;
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, dynamic> userData = {};
  
  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    departmentController = TextEditingController();
    positionController = TextEditingController();
    addressController = TextEditingController();
    birthDateController = TextEditingController();
    
    // Fetch user data from Firebase
    _fetchUserData();
  }
  
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get current user
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Set email from FirebaseAuth
        emailController.text = currentUser.email ?? '';
        
        // Get additional user data from Firestore
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (docSnapshot.exists) {
          userData = docSnapshot.data() as Map<String, dynamic>;
          
          // Set form fields from Firestore data
          nameController.text = userData['profileName'] ?? '';
          phoneController.text = userData['phone'] ?? '';
          departmentController.text = userData['department'] ?? '';
          positionController.text = userData['position'] ?? '';
          addressController.text = userData['address'] ?? '';
          birthDateController.text = userData['birthDate'] ?? '';
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${tr('profile_edit_error_fetch')}: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Prepare data to save
        final updatedData = {
          'profileName': nameController.text,
          'phone': phoneController.text,
          'department': departmentController.text,
          'position': positionController.text,
          'address': addressController.text,
          'birthDate': birthDateController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set(updatedData, SetOptions(merge: true));
        
        // Call the onSave callback
        widget.onSave(updatedData);
        
        // Close dialog
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${tr('profile_edit_error_save')}: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    departmentController.dispose();
    positionController.dispose();
    addressController.dispose();
    birthDateController.dispose();
    super.dispose();
  }
  
  // Get initials from name
  String getInitials(String? name) {
    if (name == null || name.isEmpty) return 'NA';
    
    List<String> nameParts = name.trim().split(' ');
    String initials = '';
    if (nameParts.isNotEmpty) {
      initials += nameParts.first.isNotEmpty ? nameParts.first[0] : '';
      if (nameParts.length > 1 && nameParts.last.isNotEmpty) {
        initials += nameParts.last[0];
      }
    }
    return initials.toUpperCase();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine if we're on a small screen (mobile)
          final isSmallScreen = constraints.maxWidth < 600;
          return contentBox(context, isSmallScreen);
        },
      ),
    );
  }
  
  Widget contentBox(BuildContext context, bool isSmallScreen) {
    final initials = getInitials(nameController.text);
    
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Responsive header with avatar and title
          if (isSmallScreen)
            _buildMobileHeader(context, initials)
          else
            _buildDesktopHeader(context, initials),
            
          const Divider(height: 30),
          
          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          
          // Form fields - responsive layout
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: _buildResponsiveFormFields(isSmallScreen),
                    ),
                  ),
          ),
          
          // Action buttons - fixed at the bottom
          const SizedBox(height: 20),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: isSmallScreen
                ? _buildMobileButtons()
                : _buildDesktopButtons(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileHeader(BuildContext context, String initials) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                tr('profile_edit_title'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close),
              color: Colors.grey[600],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Avatar with initials
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          child: Center(
            child: _isLoading 
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  )
                : Text(
                    initials,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          tr('profile_edit_subtitle'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDesktopHeader(BuildContext context, String initials) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar with initials
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          child: Center(
            child: _isLoading 
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  )
                : Text(
                    initials,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 20),
        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('profile_edit_title'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                tr('profile_edit_subtitle'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        // Close button
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.close),
          color: Colors.grey[600],
        ),
      ],
    );
  }
  
  Widget _buildResponsiveFormFields(bool isSmallScreen) {
    if (isSmallScreen) {
      // Mobile layout - stack fields vertically
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: nameController,
            labelText: tr('profile_edit_name'),
            prefixIcon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr('profile_edit_validation_name');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: emailController,
            labelText: tr('profile_edit_email'),
            prefixIcon: Icons.email,
            enabled: false,
            helperText: tr('profile_edit_email_helper'),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: phoneController,
            labelText: tr('profile_edit_phone'),
            prefixIcon: Icons.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr('profile_edit_validation_phone');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: birthDateController,
            labelText: tr('profile_edit_birth_date'),
            prefixIcon: Icons.cake,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: departmentController,
            labelText: tr('profile_edit_department'),
            prefixIcon: Icons.business,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: positionController,
            labelText: tr('profile_edit_position'),
            prefixIcon: Icons.work,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: addressController,
            labelText: tr('profile_edit_address'),
            prefixIcon: Icons.location_on,
            maxLines: 3,
          ),
        ],
      );
    } else {
      // Desktop layout - side by side fields
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: nameController,
                  labelText: tr('profile_edit_name'),
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr('profile_edit_validation_name');
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTextField(
                  controller: emailController,
                  labelText: tr('profile_edit_email'),
                  prefixIcon: Icons.email,
                  enabled: false,
                  helperText: tr('profile_edit_email_helper'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: phoneController,
                  labelText: tr('profile_edit_phone'),
                  prefixIcon: Icons.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr('profile_edit_validation_phone');
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTextField(
                  controller: birthDateController,
                  labelText: tr('profile_edit_birth_date'),
                  prefixIcon: Icons.cake,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: departmentController,
                  labelText: tr('profile_edit_department'),
                  prefixIcon: Icons.business,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTextField(
                  controller: positionController,
                  labelText: tr('profile_edit_position'),
                  prefixIcon: Icons.work,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: addressController,
            labelText: tr('profile_edit_address'),
            prefixIcon: Icons.location_on,
            maxLines: 3,
          ),
        ],
      );
    }
  }
  
  Widget _buildMobileButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _isSaving ? null : _saveUserData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isSaving 
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(tr('profile_edit_saving')),
                  ],
                )
              : Text(tr('profile_edit_save')),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _isSaving ? null : () {
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          child: Text(tr('profile_edit_cancel')),
        ),
      ],
    );
  }
  
  Widget _buildDesktopButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSaving ? null : () {
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(tr('profile_edit_cancel')),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveUserData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isSaving 
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(tr('profile_edit_saving')),
                  ],
                )
              : Text(tr('profile_edit_save')),
        ),
      ],
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool enabled = true,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        helperText: helperText,
        helperStyle: TextStyle(color: Colors.grey.shade600),
      ),
      maxLines: maxLines,
      validator: validator,
      enabled: enabled,
    );
  }
}
