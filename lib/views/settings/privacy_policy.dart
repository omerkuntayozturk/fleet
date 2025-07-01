import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final bool isDialog;
  
  const PrivacyPolicyPage({Key? key, this.isDialog = false}) : super(key: key);

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
                  children: formatPolicyText(context, Colors.red, constraints.maxWidth),
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
                  tooltip: tr('privacy_close'),
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
              title: Text(tr('privacy_title')),
              backgroundColor: Colors.red,
              elevation: 0,
            ),
            body: content,
          );
        }
      }
    );
  }
  
  // Formats policy text by parsing headings, sections and lists
  static List<Widget> formatPolicyText(BuildContext context, Color color, double maxWidth) {
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
        tr('privacy_main_title'),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: isMobile ? 18 : 24,
        ),
      ),
    );
    widgets.add(SizedBox(height: bulletSpacing));

    // Add company and app info
    widgets.add(
      Text(
        tr('privacy_company_name'),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: isMobile ? 14 : 16,
        ),
      ),
    );
    widgets.add(SizedBox(height: bulletSpacing / 2));
    
    widgets.add(
      Text(
        tr('privacy_app_name'),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: isMobile ? 14 : 16,
        ),
      ),
    );
    widgets.add(SizedBox(height: bulletSpacing / 2));
    
    widgets.add(
      Text(
        tr('privacy_effective_date'),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: isMobile ? 13 : 14,
        ),
      ),
    );
    widgets.add(SizedBox(height: titleSpacing));

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

    // Section 1: Introduction
    widgets.add(createSectionHeader('privacy_section_1_title'));
    widgets.add(createSectionContent('privacy_section_1_content'));

    // Section 2: Collected Information
    widgets.add(createSectionHeader('privacy_section_2_title'));
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: bulletSpacing),
        child: Text(
          tr('privacy_section_2_content'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: isMobile ? 14 : 16,
          ),
        ),
      ),
    );

    // Bullet points for section 2
    for (int i = 1; i <= 4; i++) {
      widgets.add(createBulletPoint('privacy_section_2_bullet_$i'));
    }
    widgets.add(SizedBox(height: isMobile ? 8 : 16));

    // Section 3: Data Usage
    widgets.add(createSectionHeader('privacy_section_3_title'));
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: bulletSpacing),
        child: Text(
          tr('privacy_section_3_content'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: isMobile ? 14 : 16,
          ),
        ),
      ),
    );

    // Bullet points for section 3
    for (int i = 1; i <= 5; i++) {
      widgets.add(createBulletPoint('privacy_section_3_bullet_$i'));
    }
    widgets.add(SizedBox(height: isMobile ? 8 : 16));

    // Section 4: Data Sharing
    widgets.add(createSectionHeader('privacy_section_4_title'));
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: bulletSpacing),
        child: Text(
          tr('privacy_section_4_content'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: isMobile ? 14 : 16,
          ),
        ),
      ),
    );

    // Bullet points for section 4
    for (int i = 1; i <= 3; i++) {
      widgets.add(createBulletPoint('privacy_section_4_bullet_$i'));
    }
    widgets.add(SizedBox(height: isMobile ? 8 : 16));

    // Section 5: Data Storage
    widgets.add(
      Text(
        tr('privacy_section_5_title'),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
    widgets.add(const SizedBox(height: 16));

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          tr('privacy_section_5_content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );

    // Section 6: Security
    widgets.add(
      Text(
        tr('privacy_section_6_title'),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
    widgets.add(const SizedBox(height: 16));

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          tr('privacy_section_6_content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );

    // Section 7: International Transfer
    widgets.add(
      Text(
        tr('privacy_section_7_title'),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
    widgets.add(const SizedBox(height: 16));

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          tr('privacy_section_7_content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );

    // Section 8: Children's Privacy
    widgets.add(
      Text(
        tr('privacy_section_8_title'),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
    widgets.add(const SizedBox(height: 16));

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          tr('privacy_section_8_content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );

    // Section 9: User Rights
    widgets.add(
      Text(
        tr('privacy_section_9_title'),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
    widgets.add(const SizedBox(height: 16));

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          tr('privacy_section_9_content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );

    // Section 10: Changes
    widgets.add(
      Text(
        tr('privacy_section_10_title'),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
    widgets.add(const SizedBox(height: 16));

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          tr('privacy_section_10_content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );

    // Section 11: Contact
    widgets.add(
      Text(
        tr('privacy_section_11_title'),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
    widgets.add(const SizedBox(height: 16));

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          tr('privacy_section_11_content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );

    // Add contact information at the end (keeping only one container with responsive design)
    widgets.add(
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('privacy_more_info'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 15 : 16,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, size: isMobile ? 14 : 16, color: color),
                SizedBox(width: isMobile ? 6 : 8),
                Expanded(
                  child: Text(
                    tr('privacy_email'),
                    style: TextStyle(fontSize: isMobile ? 13 : 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return widgets;
  }
}
