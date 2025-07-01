import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class UserAgreementPage extends StatelessWidget {
  final bool isDialog;
  
  const UserAgreementPage({Key? key, this.isDialog = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're on a mobile screen
        final isMobile = constraints.maxWidth < 600;
        
        Widget content = Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                // Responsive padding based on screen size
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16.0 : 24.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: formatAgreementText(context, Colors.indigo, constraints.maxWidth),
                ),
              ),
            ),
            
            // Add X button in the top-right corner if shown as dialog
            if (isDialog)
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  color: Colors.grey[700],
                  tooltip: tr('user_agreement_close'),
                ),
              ),
          ],
        );

        // Return appropriate widget based on whether it's shown as dialog or full page
        if (isDialog) {
          return content;
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text(tr('user_agreement_title')),
              centerTitle: true,
              backgroundColor: Colors.indigo,
              elevation: 0,
            ),
            body: content,
          );
        }
      }
    );
  }

  // Formats agreement text by parsing headings, sections and lists
  static List<Widget> formatAgreementText(BuildContext context, Color color, double maxWidth) {
    final List<Widget> widgets = [];
    
    // Determine if we're on a mobile screen
    final isMobile = maxWidth < 600;
    
    // Calculate responsive spacing
    final double titleSpacing = isMobile ? 16.0 : 24.0;
    final double sectionSpacing = isMobile ? 12.0 : 16.0;
    final double bulletSpacing = isMobile ? 6.0 : 8.0;
    final double paragraphSpacing = isMobile ? 12.0 : 16.0;

    // Add title with responsive font size
    widgets.add(
      Text(
        tr('user_agreement_main_title'),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: isMobile ? 18 : 24,
        ),
      ),
    );
    widgets.add(SizedBox(height: titleSpacing));

    // Add introduction
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: paragraphSpacing),
        child: Text(
          tr('user_agreement_intro'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: isMobile ? 14 : 16,
          ),
        ),
      ),
    );

    // Function to create section headers with responsive styling
    Widget createSectionHeader(String translationKey) {
      return Padding(
        padding: EdgeInsets.only(bottom: sectionSpacing),
        child: Text(
          tr(translationKey),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: isMobile ? 16 : 18,
          ),
        ),
      );
    }

    // Function to create section content with responsive styling
    Widget createSectionContent(String translationKey) {
      return Padding(
        padding: EdgeInsets.only(bottom: paragraphSpacing),
        child: Text(
          tr(translationKey),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: isMobile ? 14 : 16,
          ),
        ),
      );
    }

    // Function to create subsection headers with responsive styling
    Widget createSubsectionHeader(String translationKey) {
      return Padding(
        padding: EdgeInsets.only(bottom: bulletSpacing),
        child: Text(
          tr(translationKey),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: isMobile ? 15 : 16,
          ),
        ),
      );
    }

    // Function to create bullet points with responsive design
    Widget createBulletPoint(String translationKey) {
      return Padding(
        padding: EdgeInsets.only(
          left: isMobile ? 8.0 : 16.0, 
          bottom: bulletSpacing,
          right: 4.0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: isMobile ? 6 : 8),
              width: isMobile ? 5 : 6,
              height: isMobile ? 5 : 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Expanded(
              child: Text(
                tr(translationKey),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Section 1 - Service Description
    widgets.add(createSectionHeader('user_agreement_section_1'));
    widgets.add(createSectionContent('user_agreement_section_1_content'));

    // Section 2 - Terms of Use
    widgets.add(createSectionHeader('user_agreement_section_2'));
    
    // Bullet points for section 2
    for (int i = 1; i <= 5; i++) {
      widgets.add(createBulletPoint('user_agreement_section_2_bullet_$i'));
    }
    widgets.add(SizedBox(height: isMobile ? 8 : 16));

    // Section 3 - Membership and Account Management
    widgets.add(createSectionHeader('user_agreement_section_3'));
    
    // Bullet points for section 3
    for (int i = 1; i <= 3; i++) {
      widgets.add(createBulletPoint('user_agreement_section_3_bullet_$i'));
    }
    widgets.add(SizedBox(height: isMobile ? 8 : 16));

    // Section 4 - Payment, Subscription and Refund Terms
    widgets.add(createSectionHeader('user_agreement_section_4'));
    
    // Subsection 4.1
    widgets.add(createSubsectionHeader('user_agreement_section_4_1'));
    widgets.add(createSectionContent('user_agreement_section_4_1_content'));
    
    // Subsection 4.2
    widgets.add(createSubsectionHeader('user_agreement_section_4_2'));
    
    // Bullet points for subsection 4.2
    for (int i = 1; i <= 3; i++) {
      widgets.add(createBulletPoint('user_agreement_section_4_2_bullet_$i'));
    }
    
    // Subsection 4.3
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: bulletSpacing, top: bulletSpacing),
        child: Text(
          tr('user_agreement_section_4_3'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: isMobile ? 15 : 16,
          ),
        ),
      ),
    );
    
    // Bullet points for subsection 4.3
    for (int i = 1; i <= 3; i++) {
      widgets.add(createBulletPoint('user_agreement_section_4_3_bullet_$i'));
    }
    widgets.add(SizedBox(height: isMobile ? 8 : 16));

    // Section 5 - Intellectual Property
    widgets.add(createSectionHeader('user_agreement_section_5'));
    
    // Bullet points for section 5
    for (int i = 1; i <= 3; i++) {
      widgets.add(createBulletPoint('user_agreement_section_5_bullet_$i'));
    }
    widgets.add(SizedBox(height: isMobile ? 8 : 16));

    // Section 6 - License and EULA
    widgets.add(createSectionHeader('user_agreement_section_6'));
    
    // Subsection 6.1
    widgets.add(createSubsectionHeader('user_agreement_section_6_1'));
    widgets.add(createSectionContent('user_agreement_section_6_1_content'));
    
    // Subsection 6.2
    widgets.add(createSubsectionHeader('user_agreement_section_6_2'));
    
    // Bullet points for subsection 6.2
    for (int i = 1; i <= 4; i++) {
      widgets.add(createBulletPoint('user_agreement_section_6_2_bullet_$i'));
    }
    
    // Subsection 6.3
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: bulletSpacing, top: bulletSpacing),
        child: Text(
          tr('user_agreement_section_6_3'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: isMobile ? 15 : 16,
          ),
        ),
      ),
    );
    widgets.add(createSectionContent('user_agreement_section_6_3_content'));
    
    // Section 7 - Data Storage and Security
    widgets.add(createSectionHeader('user_agreement_section_7'));
    
    // Bullet points for section 7
    for (int i = 1; i <= 3; i++) {
      widgets.add(createBulletPoint('user_agreement_section_7_bullet_$i'));
    }
    widgets.add(SizedBox(height: isMobile ? 8 : 16));
    
    // Section 8 - Third Party Integrations
    widgets.add(createSectionHeader('user_agreement_section_8'));
    
    // Bullet points for section 8
    for (int i = 1; i <= 3; i++) {
      widgets.add(createBulletPoint('user_agreement_section_8_bullet_$i'));
    }
    widgets.add(SizedBox(height: isMobile ? 8 : 16));
    
    // Section 9 - International Use and Legal Jurisdiction
    widgets.add(createSectionHeader('user_agreement_section_9'));
    
    // Bullet points for section 9
    for (int i = 1; i <= 4; i++) {
      widgets.add(createBulletPoint('user_agreement_section_9_bullet_$i'));
    }
    widgets.add(SizedBox(height: isMobile ? 8 : 16));
    
    // Section 10 - Termination of Agreement
    widgets.add(createSectionHeader('user_agreement_section_10'));
    
    // Bullet points for section 10
    for (int i = 1; i <= 3; i++) {
      widgets.add(createBulletPoint('user_agreement_section_10_bullet_$i'));
    }
    widgets.add(SizedBox(height: isMobile ? 8 : 16));
    
    // Section 11 - Contact Information
    widgets.add(createSectionHeader('user_agreement_section_11'));
    widgets.add(createSectionContent('user_agreement_section_11_content'));
    
    // Section 12 - Effectiveness and Acceptance
    widgets.add(createSectionHeader('user_agreement_section_12'));
    widgets.add(createSectionContent('user_agreement_section_12_content'));

    // Add last updated information
    widgets.add(SizedBox(height: isMobile ? 12 : 16));
    widgets.add(
      Center(
        child: Text(
          tr('user_agreement_last_updated'),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isMobile ? 12 : 14,
          ),
        ),
      ),
    );
    widgets.add(const SizedBox(height: 16));

    return widgets;
  }
}
