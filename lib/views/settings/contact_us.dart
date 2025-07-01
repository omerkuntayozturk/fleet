import 'package:flutter/material.dart';
import 'package:fleet/info_card.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  bool _isSending = false;
  bool _isUserLoggedIn = false;
  
  // Firebase functions instance
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  // Contact information
  final Map<String, String> _contactInfo = {
    'address': tr('contact_address_value'),
    'phone': tr('contact_phone_value'),
    'email': tr('contact_email_value'),
    'workHours': tr('contact_work_hours_value')
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    // Pre-fill email if user is already logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _nameController.text = user.displayName ?? '';
      _isUserLoggedIn = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Method to call the Firebase cloud function
  Future<void> _sendSupportEmail() async {
    try {
      setState(() {
        _isSending = true;
      });
      
      // Get current user info for better tracking
      final user = FirebaseAuth.instance.currentUser;
      final userName = _nameController.text.trim();
      final userEmail = _emailController.text.trim();
      final subject = _subjectController.text.trim();
      final message = _messageController.text.trim();
      
      // Prepare data for the cloud function according to its expected format
      // This should match the parameters expected by the sendSupportEmail function
      final data = {
        'userEmail': userEmail,
        'userName': userName,
        'subject': subject,
        'message': message,
      };
      
      // Call the Firebase cloud function
      final result = await _functions.httpsCallable('sendSupportEmail').call(data);
      
      // Check the response from the function
      final response = result.data as Map<String, dynamic>;
      if (response['success'] == true) {
        // Show success message
        InfoCard.showInfoCard(
          context,
          tr('contact_message_sent_success'),
          Colors.green,
          icon: Icons.check_circle,
        );
        
        // Clear form
        _subjectController.clear();
        _messageController.clear();
        
        // Don't clear name and email if they're from a logged-in user
        if (user == null) {
          _nameController.clear();
          _emailController.clear();
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to send email');
      }
    } catch (e) {
      // Show error message
      InfoCard.showInfoCard(
        context,
        '${tr('contact_message_sent_error')}: ${e.toString()}',
        Colors.red,
        icon: Icons.error,
      );
      print('Error sending support email: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _sendSupportEmail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Create multiple breakpoints for better responsiveness
    final isTablet = screenWidth > 768 && screenWidth <= 1200;
    final isMobile = screenWidth <= 768;
    final isSmallMobile = screenWidth <= 480;
    
    final bool isDialog = ModalRoute.of(context)?.settings.name == null;
    
    // Adaptive paddings based on screen size
    final horizontalPadding = isSmallMobile ? 16.0 : (isMobile ? 20.0 : 24.0);
    final verticalPadding = isSmallMobile ? 16.0 : 24.0;
    
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: isSmallMobile ? 20 : 40),
                    
                    // Main contact content - responsive layout
                    (!isMobile) 
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildContactInfo(),
                            ),
                            SizedBox(width: isTablet ? 20 : 40),
                            Expanded(
                              flex: 1,
                              child: _buildContactForm(),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildContactInfo(),
                            SizedBox(height: isSmallMobile ? 20 : 40),
                            _buildContactForm(),
                          ],
                        ),
                        
                    SizedBox(height: isSmallMobile ? 30 : 60),
                    
                    // FAQ Section
                    _buildFAQSection(),
                  ],
                ),
              ),
              
              // Add an X button if shown as dialog
              if (isDialog)
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: Colors.grey[700],
                    tooltip: tr('contact_close'),
                  ),
                ),
            ],
          ),
        );
      }
    );
    
    // Return appropriate widget based on whether it's shown as dialog or full page
    if (isDialog) {
      return content;
    } else {
      return Scaffold(
        appBar: const TopBar(),
        drawer: const SideMenu(currentPage: '/settings'),
        body: content,
      );
    }
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 480;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          )),
          child: Text(
            tr('contact_title'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: isSmallMobile ? 22 : null,
                ),
          ),
        ),
        const SizedBox(height: 8),
        FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
            ),
          ),
          child: Text(
            tr('contact_subtitle'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: isSmallMobile ? 14 : null,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;
    final isSmallMobile = screenWidth <= 480;
    
    // Adaptive padding and spacing
    final containerPadding = isSmallMobile ? 16.0 : 24.0;
    final itemSpacing = isSmallMobile ? 12.0 : 20.0;
    
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(containerPadding),
        // Remove fixed height to allow flexible resizing
        constraints: BoxConstraints(
          minHeight: isMobile ? 0 : 400, // Less restrictive minimum height
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('contact_info_title'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                    fontSize: isSmallMobile ? 18 : null,
                  ),
            ),
            SizedBox(height: itemSpacing),
            
            // Address
            _buildContactInfoItem(
              icon: Icons.location_on,
              title: tr('contact_address'),
              content: _contactInfo['address']!,
              color: Colors.blue,
            ),
            SizedBox(height: itemSpacing),
            
            // Phone
            _buildContactInfoItem(
              icon: Icons.phone,
              title: tr('contact_phone'),
              content: _contactInfo['phone']!,
              color: Colors.green,
            ),
            SizedBox(height: itemSpacing),
            
            // Email
            _buildContactInfoItem(
              icon: Icons.email,
              title: tr('contact_email'),
              content: _contactInfo['email']!,
              color: Colors.orange,
            ),
            SizedBox(height: itemSpacing),
            
            // Work Hours
            _buildContactInfoItem(
              icon: Icons.access_time,
              title: tr('contact_work_hours'),
              content: _contactInfo['workHours']!,
              color: Colors.purple,
            ),
            
            SizedBox(height: isSmallMobile ? 20 : 30),
            
            // Social Media
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('contact_social_media'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallMobile ? 16 : null,
                      ),
                ),
                SizedBox(height: isSmallMobile ? 10 : 16),
                // Wrap social media buttons for small screens
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: [
                    _buildSocialButton(
                      icon: FontAwesomeIcons.facebook,
                      iconSize: isSmallMobile ? 20 : 24,
                      color: const Color(0xFF1877F2),
                      url: 'http://facebook.com/share/1CCDyDe4fj/?mibextid=wwXIfr',
                      tooltip: 'Facebook',
                    ),
                    _buildSocialButton(
                      icon: FontAwesomeIcons.instagram,
                      iconSize: isSmallMobile ? 20 : 24,
                      color: const Color(0xFFE4405F),
                      url: 'https://www.instagram.com/goyaappyazilim?igsh=MXN6cnk1N3BxbmNqbg%3D%3D&utm_source=qr',
                      tooltip: 'Instagram',
                    ),
                    _buildSocialButton(
                      icon: FontAwesomeIcons.xTwitter,
                      iconSize: isSmallMobile ? 18 : 22,
                      color: const Color(0xFF000000),
                      url: 'http://x.com/goyaappyazilim?s=21&t=Ya7V1rb4kmhVgo7DCIILdw',
                      tooltip: 'Twitter/X',
                    ),
                    _buildSocialButton(
                      icon: FontAwesomeIcons.linkedin,
                      iconSize: isSmallMobile ? 20 : 24,
                      color: const Color(0xFF0A66C2),
                      url: 'https://www.linkedin.com/company/goyaapp-yaz%C4%B1l%C4%B1m-dijital-%C3%A7%C3%B6z%C3%BCmler/?viewAsMember=true',
                      tooltip: 'LinkedIn',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoItem({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 480;
    
    // Use a more flexible layout that can adapt to smaller screens
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallMobile ? 8 : 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: isSmallMobile ? 20 : 24,
          ),
        ),
        SizedBox(width: isSmallMobile ? 10 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallMobile ? 14 : 16,
                ),
              ),
              SizedBox(height: isSmallMobile ? 2 : 4),
              Text(
                content,
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.5,
                  fontSize: isSmallMobile ? 13 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String url,
    double iconSize = 24,
    String? tooltip,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 480;
    
    // Adjust button size for mobile
    final buttonSize = isSmallMobile ? 10.0 : 12.0;
    
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: () => _launchURL(url),
        borderRadius: BorderRadius.circular(buttonSize),
        child: Container(
          padding: EdgeInsets.all(buttonSize),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(buttonSize),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: FaIcon(
            icon,
            color: color,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildContactForm() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;
    final isSmallMobile = screenWidth <= 480;
    
    // Adaptive padding and spacing
    final containerPadding = isSmallMobile ? 16.0 : 24.0;
    final fieldSpacing = isSmallMobile ? 12.0 : 16.0;
    
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(containerPadding),
        // Remove fixed height to allow content to determine size
        constraints: BoxConstraints(
          minHeight: isMobile ? 0 : 400, // Less restrictive minimum height
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('contact_form_title'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      fontSize: isSmallMobile ? 18 : null,
                    ),
              ),
              SizedBox(height: isSmallMobile ? 10 : 16),
              Text(
                tr('contact_form_description'),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isSmallMobile ? 13 : null,
                ),
              ),
              SizedBox(height: isSmallMobile ? 16 : 24),
              
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: tr('contact_form_name'),
                  prefixIcon: Icon(Icons.person, size: isSmallMobile ? 20 : 24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isSmallMobile ? 12 : 16,
                    horizontal: isSmallMobile ? 10 : 12,
                  ),
                ),
                style: TextStyle(fontSize: isSmallMobile ? 14 : null),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr('contact_validation_name_required');
                  }
                  return null;
                },
              ),
              SizedBox(height: fieldSpacing),
              
              // Email field
              TextFormField(
                controller: _emailController,
                readOnly: _isUserLoggedIn,
                enabled: !_isUserLoggedIn,
                decoration: InputDecoration(
                  labelText: tr('contact_form_email'),
                  prefixIcon: Icon(Icons.email, size: isSmallMobile ? 20 : 24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isSmallMobile ? 12 : 16,
                    horizontal: isSmallMobile ? 10 : 12,
                  ),
                  suffixIcon: _isUserLoggedIn 
                      ? Tooltip(
                          message: tr('contact_email_readonly_tooltip'),
                          child: Icon(Icons.lock, 
                            color: Theme.of(context).primaryColor,
                            size: isSmallMobile ? 20 : 24,
                          ),
                        )
                      : null,
                  helperText: _isUserLoggedIn 
                      ? tr('contact_using_account_email') 
                      : null,
                  helperStyle: TextStyle(
                    color: _isUserLoggedIn ? Theme.of(context).primaryColor : null,
                    fontStyle: FontStyle.italic,
                    fontSize: isSmallMobile ? 12 : null,
                  ),
                  fillColor: _isUserLoggedIn ? Colors.grey[100] : null,
                  filled: _isUserLoggedIn,
                ),
                style: TextStyle(
                  color: _isUserLoggedIn ? Colors.grey[700] : null,
                  fontSize: isSmallMobile ? 14 : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr('contact_validation_email_required');
                  }
                  if (!value.contains('@')) {
                    return tr('contact_validation_email_invalid');
                  }
                  return null;
                },
              ),
              SizedBox(height: fieldSpacing),
              
              // Subject field
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: tr('contact_form_subject'),
                  prefixIcon: Icon(Icons.subject, size: isSmallMobile ? 20 : 24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isSmallMobile ? 12 : 16,
                    horizontal: isSmallMobile ? 10 : 12,
                  ),
                ),
                style: TextStyle(fontSize: isSmallMobile ? 14 : null),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr('contact_validation_subject_required');
                  }
                  return null;
                },
              ),
              SizedBox(height: fieldSpacing),
              
              // Message field - reduced height on small screens
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: tr('contact_form_message'),
                  prefixIcon: Icon(Icons.message, size: isSmallMobile ? 20 : 24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isSmallMobile ? 12 : 16,
                    horizontal: isSmallMobile ? 10 : 12,
                  ),
                ),
                style: TextStyle(fontSize: isSmallMobile ? 14 : null),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr('contact_validation_message_required');
                  }
                  return null;
                },
                maxLines: isSmallMobile ? 4 : 6,
              ),
              SizedBox(height: isSmallMobile ? 20 : 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: isSmallMobile ? 44 : 50,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSending
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: isSmallMobile ? 16 : 20,
                              width: isSmallMobile ? 16 : 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: isSmallMobile ? 1.5 : 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              tr('contact_form_sending'),
                              style: TextStyle(fontSize: isSmallMobile ? 14 : 16),
                            ),
                          ],
                        )
                      : Text(
                          tr('contact_form_submit'),
                          style: TextStyle(
                            fontSize: isSmallMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 480;
    
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('contact_faq_title'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallMobile ? 18 : null,
                ),
          ),
          SizedBox(height: isSmallMobile ? 16 : 24),
          
          // FAQ items
          _buildFAQItem(
            question: tr('contact_faq_question1'),
            answer: tr('contact_faq_answer1'),
          ),
          _buildFAQItem(
            question: tr('contact_faq_question2'),
            answer: tr('contact_faq_answer2'),
          ),
          _buildFAQItem(
            question: tr('contact_faq_question3'),
            answer: tr('contact_faq_answer3'),
          ),
          _buildFAQItem(
            question: tr('contact_faq_question4'),
            answer: tr('contact_faq_answer4'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 480;
    
    return Container(
      margin: EdgeInsets.only(bottom: isSmallMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Theme(
        // Use custom theme to adjust the expansion tile
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          visualDensity: isSmallMobile 
              ? VisualDensity.compact 
              : VisualDensity.standard,
        ),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallMobile ? 14 : 16,
            ),
          ),
          childrenPadding: EdgeInsets.all(isSmallMobile ? 12 : 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: Theme.of(context).primaryColor,
          collapsedIconColor: Colors.grey[700],
          tilePadding: EdgeInsets.symmetric(
            horizontal: isSmallMobile ? 12 : 16,
            vertical: isSmallMobile ? 8 : 12,
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                color: Colors.grey[800],
                height: 1.5,
                fontSize: isSmallMobile ? 13 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
