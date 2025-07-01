import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class CookiesPage extends StatelessWidget {
  final bool isDialog;
  
  const CookiesPage({super.key, this.isDialog = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        
        Widget content = Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16.0 : 24.0,
                  vertical: isSmallScreen ? 16.0 : 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: formatCookiesText(context, Colors.blue, constraints.maxWidth),
                ),
              ),
            ),
            
            // Add X button in the top-right corner if shown as dialog
            if (isDialog)
              Positioned(
                top: isSmallScreen ? 5 : 10,
                right: isSmallScreen ? 5 : 10,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  color: Colors.grey[700],
                  tooltip: tr('cookies_close'),
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
              title: Text(tr('cookies_title')),
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

  static List<Widget> formatCookiesText(BuildContext context, Color color, double maxWidth) {
    final List<Widget> widgets = [];
    
    // Determine if we're on a small screen (e.g., mobile)
    final isSmallScreen = maxWidth < 600;
    
    // Define responsive spacing
    final double sectionSpacing = isSmallScreen ? 16.0 : 24.0;
    final double paragraphSpacing = isSmallScreen ? 8.0 : 16.0;
    final double bulletPadding = isSmallScreen ? 8.0 : 16.0;
    
    // Define responsive text styles
    final titleStyle = isSmallScreen 
        ? Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          )
        : Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          );
        
    final sectionTitleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: color,
      fontSize: isSmallScreen ? 16.0 : null,
    );
    
    final bodyTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: isSmallScreen ? 14.0 : null,
    );
    
    // Helper function to add section titles
    void addSectionTitle(String translationKey) {
      widgets.add(
        Text(
          tr(translationKey),
          style: sectionTitleStyle,
        ),
      );
      widgets.add(SizedBox(height: paragraphSpacing));
    }
    
    // Helper function to add paragraphs
    void addParagraph(String translationKey, {double bottomPadding = 16.0}) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: isSmallScreen ? bottomPadding * 0.75 : bottomPadding),
          child: Text(
            tr(translationKey),
            style: bodyTextStyle,
          ),
        ),
      );
    }
    
    // Helper function to add bullet points
    void addBulletPoints(List<String> translationKeys) {
      for (String key in translationKeys) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              left: bulletPadding, 
              bottom: isSmallScreen ? 6.0 : 8.0
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: isSmallScreen ? 6 : 8),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Text(
                    tr(key),
                    style: bodyTextStyle,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      widgets.add(SizedBox(height: paragraphSpacing));
    }

    // Add title
    widgets.add(
      Text(
        tr('cookies_main_title'),
        style: titleStyle,
      ),
    );
    widgets.add(SizedBox(height: paragraphSpacing));
    
    // Add effective date and company info with adaptive wrapping
    final infoTextStyle = bodyTextStyle;
    
    widgets.add(
      Text(
        tr('cookies_effective_date'),
        style: infoTextStyle,
      ),
    );
    
    widgets.add(
      Text(
        tr('cookies_company'),
        style: infoTextStyle,
      ),
    );
    
    widgets.add(
      Text(
        tr('cookies_app_name'),
        style: infoTextStyle,
      ),
    );
    
    widgets.add(
      Text(
        tr('cookies_contact'),
        style: infoTextStyle,
      ),
    );
    widgets.add(SizedBox(height: paragraphSpacing));
    
    // Introduction text
    widgets.add(
      Text(
        tr('cookies_intro'),
        style: bodyTextStyle,
      ),
    );
    widgets.add(SizedBox(height: sectionSpacing));
    
    // 1. What are Cookies?
    addSectionTitle('cookies_section_1_title');
    addParagraph('cookies_section_1_content');
    
    // 2. Types of Cookies Used
    addSectionTitle('cookies_section_2_title');
    addParagraph('cookies_section_2_content', bottomPadding: 8.0);
    
    // Bullet points for section 2
    addBulletPoints([
      'cookies_section_2_essential',
      'cookies_section_2_functional',
      'cookies_section_2_analytics',
      'cookies_section_2_third_party'
    ]);
    
    // 3. Purposes of Cookies
    addSectionTitle('cookies_section_3_title');
    
    // Bullet points for section 3
    addBulletPoints([
      'cookies_section_3_identify',
      'cookies_section_3_preferences',
      'cookies_section_3_performance',
      'cookies_section_3_security',
      'cookies_section_3_statistics'
    ]);
    
    // 4. Cookie Management
    addSectionTitle('cookies_section_4_title');
    addParagraph('cookies_section_4_content', bottomPadding: 8.0);
    
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: isSmallScreen ? 6.0 : 8.0),
        child: Text(
          tr('cookies_section_4_steps'),
          style: bodyTextStyle?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    
    // Management steps for different browsers
    addBulletPoints([
      'cookies_section_4_chrome',
      'cookies_section_4_safari',
      'cookies_section_4_firefox',
      'cookies_section_4_mobile'
    ]);
    
    // 5. Consent
    addSectionTitle('cookies_section_5_title');
    addParagraph('cookies_section_5_content');
    
    // 6. Third-Party Cookies
    addSectionTitle('cookies_section_6_title');
    addParagraph('cookies_section_6_content');
    
    // 7. Changes to Policy
    addSectionTitle('cookies_section_7_title');
    addParagraph('cookies_section_7_content');
    
    // 8. Contact
    addSectionTitle('cookies_section_8_title');
    addParagraph('cookies_section_8_content');

    return widgets;
  }
}
    
    // Management steps for different browsers
    final browsers = [
      'cookies_section_4_chrome',
      'cookies_section_4_safari',
      'cookies_section_4_firefox',
      'cookies_section_4_mobile'
    ];
  List<Widget> formatCookiesText(BuildContext context, Color color, double maxWidth) {
    final List<Widget> widgets = [];
    
    for (String browser in browsers) {
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
                  tr(browser),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }
    widgets.add(const SizedBox(height: 16));
    
    // 5. Consent
    widgets.add(
      Text(
        tr('cookies_section_5_title'),
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
          tr('cookies_section_5_content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
    
    // 6. Third-Party Cookies
    widgets.add(
      Text(
        tr('cookies_section_6_title'),
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
          tr('cookies_section_6_content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
    
    // 7. Changes to Policy
    widgets.add(
      Text(
        tr('cookies_section_7_title'),
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
          tr('cookies_section_7_content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
    
    // 8. Contact
    widgets.add(
      Text(
        tr('cookies_section_8_title'),
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
          tr('cookies_section_8_content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );

    return widgets;
  }
