import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class KVKKPage extends StatelessWidget {
  final bool isDialog;
  
  const KVKKPage({super.key, this.isDialog = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're on a small screen (like mobile)
        final bool isSmallScreen = constraints.maxWidth < 600;
        
        // Adjust padding based on screen size
        final double horizontalPadding = isSmallScreen ? 16.0 : 24.0;
        
        Widget content = Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: formatKVKKText(context, Colors.blue, isSmallScreen),
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
                  tooltip: tr('kvkk_close'),
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
              title: Text(tr('kvkk_title')),
              elevation: 0,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            body: content,
          );
        }
      }
    );
  }

  static List<Widget> formatKVKKText(BuildContext context, Color color, bool isSmallScreen) {
    final List<Widget> widgets = [];
    
    // Calculate responsive font sizes and spacing
    final double titleSize = isSmallScreen ? 20.0 : 24.0;
    final double subtitleSize = isSmallScreen ? 16.0 : 18.0;
    final double bodySize = isSmallScreen ? 14.0 : 16.0;
    final double sectionSpacing = isSmallScreen ? 16.0 : 24.0;
    final double paragraphSpacing = isSmallScreen ? 8.0 : 12.0;
    final double bulletPadding = isSmallScreen ? 12.0 : 16.0;
    final double bulletSize = isSmallScreen ? 5.0 : 6.0;

    // Add title
    widgets.add(
      Text(
        tr('kvkk_main_title'),
        style: TextStyle(
          fontSize: titleSize,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
    widgets.add(SizedBox(height: paragraphSpacing));
    
    // Add subtitle
    widgets.add(
      Text(
        tr('kvkk_subtitle'),
        style: TextStyle(
          fontSize: subtitleSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    widgets.add(SizedBox(height: paragraphSpacing));
    
    // Add effective date
    widgets.add(
      Text(
        tr('kvkk_effective_date'),
        style: TextStyle(fontSize: bodySize),
      ),
    );
    
    // Add company info
    widgets.add(
      Text(
        tr('kvkk_company'),
        style: TextStyle(fontSize: bodySize),
      ),
    );
    
    // Add application info
    widgets.add(
      Text(
        tr('kvkk_app_name'),
        style: TextStyle(fontSize: bodySize),
      ),
    );
    
    // Add contact info
    widgets.add(
      Text(
        tr('kvkk_contact'),
        style: TextStyle(fontSize: bodySize),
      ),
    );
    widgets.add(SizedBox(height: sectionSpacing));
    
    // 1. Purpose and Scope
    widgets.add(
      Text(
        tr('kvkk_section_1_title'),
        style: TextStyle(
          fontSize: subtitleSize,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
    widgets.add(SizedBox(height: paragraphSpacing));
    
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: paragraphSpacing),
        child: Text(
          tr('kvkk_section_1_content'),
          style: TextStyle(fontSize: bodySize),
        ),
      ),
    );
    
    // Helper function for section headers
    Widget sectionHeader(String title) {
      return Padding(
        padding: EdgeInsets.only(top: paragraphSpacing),
        child: Text(
          tr(title),
          style: TextStyle(
            fontSize: subtitleSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      );
    }
    
    // Helper function for creating bullet points
    Widget bulletPoint(String textKey) {
      return Padding(
        padding: EdgeInsets.only(
          left: bulletPadding,
          bottom: paragraphSpacing,
          right: isSmallScreen ? 4.0 : 8.0
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: bodySize / 2),
              width: bulletSize,
              height: bulletSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: bulletPadding - 4),
            Expanded(
              child: Text(
                tr(textKey),
                style: TextStyle(fontSize: bodySize),
              ),
            ),
          ],
        ),
      );
    }
    
    // 2. Data Controller
    widgets.add(sectionHeader('kvkk_section_2_title'));
    widgets.add(SizedBox(height: paragraphSpacing));
    
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: paragraphSpacing),
        child: Text(
          tr('kvkk_section_2_content'),
          style: TextStyle(fontSize: bodySize),
        ),
      ),
    );
    
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: 4.0),
        child: Text(
          tr('kvkk_section_2_company'),
          style: TextStyle(fontSize: bodySize),
        ),
      ),
    );
    
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: 4.0),
        child: Text(
          tr('kvkk_section_2_address'),
          style: TextStyle(fontSize: bodySize),
        ),
      ),
    );
    
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: sectionSpacing),
        child: Text(
          tr('kvkk_section_2_email'),
          style: TextStyle(fontSize: bodySize),
        ),
      ),
    );
    
    // 3. Processed Personal Data
    widgets.add(sectionHeader('kvkk_section_3_title'));
    widgets.add(SizedBox(height: paragraphSpacing));
    
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: paragraphSpacing),
        child: Text(
          tr('kvkk_section_3_intro'),
          style: TextStyle(fontSize: bodySize),
        ),
      ),
    );
    
    // Bullet points for section 3
    for (int i = 1; i <= 4; i++) {
      widgets.add(bulletPoint('kvkk_section_3_bullet_$i'));
    }
    widgets.add(SizedBox(height: paragraphSpacing));
    
    // 4. Purpose of Processing Personal Data
    widgets.add(sectionHeader('kvkk_section_4_title'));
    widgets.add(SizedBox(height: paragraphSpacing));
    
    // Bullet points for section 4
    for (int i = 1; i <= 4; i++) {
      widgets.add(bulletPoint('kvkk_section_4_bullet_$i'));
    }
    widgets.add(SizedBox(height: paragraphSpacing));
    
    // 5. Legal Reasons
    widgets.add(sectionHeader('kvkk_section_5_title'));
    widgets.add(SizedBox(height: paragraphSpacing));
    
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: paragraphSpacing),
        child: Text(
          tr('kvkk_section_5_intro'),
          style: TextStyle(fontSize: bodySize),
        ),
      ),
    );
    
    // Bullet points for section 5
    for (int i = 1; i <= 4; i++) {
      widgets.add(bulletPoint('kvkk_section_5_bullet_$i'));
    }
    widgets.add(SizedBox(height: paragraphSpacing));
    
    // 6. Data Transfer
    widgets.add(sectionHeader('kvkk_section_6_title'));
    widgets.add(SizedBox(height: paragraphSpacing));
    
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: paragraphSpacing),
        child: Text(
          tr('kvkk_section_6_content'),
          style: TextStyle(fontSize: bodySize),
        ),
      ),
    );
    
    // Bullet points for section 6
    for (int i = 1; i <= 2; i++) {
      widgets.add(bulletPoint('kvkk_section_6_bullet_$i'));
    }
    widgets.add(SizedBox(height: paragraphSpacing));
    
    // 7. Storage Period
    widgets.add(sectionHeader('kvkk_section_7_title'));
    widgets.add(SizedBox(height: paragraphSpacing));
    
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: sectionSpacing),
        child: Text(
          tr('kvkk_section_7_content'),
          style: TextStyle(fontSize: bodySize),
        ),
      ),
    );
    
    // 8. Your Rights Under KVKK
    widgets.add(sectionHeader('kvkk_section_8_title'));
    widgets.add(SizedBox(height: paragraphSpacing));
    
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: paragraphSpacing),
        child: Text(
          tr('kvkk_section_8_intro'),
          style: TextStyle(fontSize: bodySize),
        ),
      ),
    );
    
    // Bullet points for section 8
    for (int i = 1; i <= 9; i++) {
      widgets.add(bulletPoint('kvkk_section_8_bullet_$i'));
    }
    widgets.add(SizedBox(height: paragraphSpacing));
    
    // 9. Application Method
    widgets.add(sectionHeader('kvkk_section_9_title'));
    widgets.add(SizedBox(height: paragraphSpacing));
    
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: sectionSpacing),
        child: Text(
          tr('kvkk_section_9_content'),
          style: TextStyle(fontSize: bodySize),
        ),
      ),
    );
    
    // 10. Updates
    widgets.add(sectionHeader('kvkk_section_10_title'));
    widgets.add(SizedBox(height: paragraphSpacing));
    
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: sectionSpacing),
        child: Text(
          tr('kvkk_section_10_content'),
          style: TextStyle(fontSize: bodySize),
        ),
      ),
    );

    return widgets;
  }
  static List<Widget> formatKVKKTextOld(BuildContext context, Color color) {
    final List<Widget> widgets = [];
    widgets.add(const SizedBox(height: 16));
    
    // 7. Storage Period
    widgets.add(
      Text(
        tr('kvkk_section_7_title'),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
    widgets.add(const SizedBox(height: 12));
    
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          tr('kvkk_section_7_content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
    
    // 8. Your Rights Under KVKK
    widgets.add(
      Text(
        tr('kvkk_section_8_title'),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
    widgets.add(const SizedBox(height: 12));
    
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          tr('kvkk_section_8_intro'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
    
    // Bullet points for section 8
    for (int i = 1; i <= 9; i++) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr('kvkk_section_8_bullet_$i'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }
    widgets.add(const SizedBox(height: 16));
    
    // 9. Application Method
    widgets.add(
      Text(
        tr('kvkk_section_9_title'),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
    widgets.add(const SizedBox(height: 12));
    
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          tr('kvkk_section_9_content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
    
    // 10. Updates
    widgets.add(
      Text(
        tr('kvkk_section_10_title'),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
    widgets.add(const SizedBox(height: 12));
    
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          tr('kvkk_section_10_content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );

    return widgets;
  }
}
