import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';

class SSSPage extends StatefulWidget {
  const SSSPage({Key? key}) : super(key: key);

  @override
  State<SSSPage> createState() => _SSSPageState();
}

class _SSSPageState extends State<SSSPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  List<Map<String, dynamic>> _filteredFaqs = [];
  
  // Updated FAQ data with Turkish categories and questions
  final List<Map<String, dynamic>> _allFaqs = [
    {
      'category': tr('faq_category_dashboard'),
      'faqs': [
        {
          'question': tr('faq_dashboard_q1'),
          'answer': tr('faq_dashboard_a1')
        },
        {
          'question': tr('faq_dashboard_q2'),
          'answer': tr('faq_dashboard_a2')
        },
        {
          'question': tr('faq_dashboard_q3'),
          'answer': tr('faq_dashboard_a3')
        },
        {
          'question': tr('faq_dashboard_q4'),
          'answer': tr('faq_dashboard_a4')
        },
        {
          'question': tr('faq_dashboard_q5'),
          'answer': tr('faq_dashboard_a5')
        },
        {
          'question': tr('faq_dashboard_q6'),
          'answer': tr('faq_dashboard_a6')
        },
        {
          'question': tr('faq_dashboard_q7'),
          'answer': tr('faq_dashboard_a7')
        },
        {
          'question': tr('faq_dashboard_q8'),
          'answer': tr('faq_dashboard_a8')
        },
        {
          'question': tr('faq_dashboard_q9'),
          'answer': tr('faq_dashboard_a9')
        },
        {
          'question': tr('faq_dashboard_q10'),
          'answer': tr('faq_dashboard_a10')
        }
      ]
    },
    {
      'category': tr('faq_category_contacts'),
      'faqs': [
        {
          'question': tr('faq_contacts_q1'),
          'answer': tr('faq_contacts_a1')
        },
        {
          'question': tr('faq_contacts_q2'),
          'answer': tr('faq_contacts_a2')
        },
        {
          'question': tr('faq_contacts_q3'),
          'answer': tr('faq_contacts_a3')
        },
        {
          'question': tr('faq_contacts_q4'),
          'answer': tr('faq_contacts_a4')
        },
        {
          'question': tr('faq_contacts_q5'),
          'answer': tr('faq_contacts_a5')
        },
        {
          'question': tr('faq_contacts_q6'),
          'answer': tr('faq_contacts_a6')
        },
        {
          'question': tr('faq_contacts_q7'),
          'answer': tr('faq_contacts_a7')
        },
        {
          'question': tr('faq_contacts_q8'),
          'answer': tr('faq_contacts_a8')
        },
        {
          'question': tr('faq_contacts_q9'),
          'answer': tr('faq_contacts_a9')
        },
        {
          'question': tr('faq_contacts_q10'),
          'answer': tr('faq_contacts_a10')
        }
      ]
    },
    {
      'category': tr('faq_category_products'),
      'faqs': [
        {
          'question': tr('faq_products_q1'),
          'answer': tr('faq_products_a1')
        },
        {
          'question': tr('faq_products_q2'),
          'answer': tr('faq_products_a2')
        },
        {
          'question': tr('faq_products_q3'),
          'answer': tr('faq_products_a3')
        },
        {
          'question': tr('faq_products_q4'),
          'answer': tr('faq_products_a4')
        },
        {
          'question': tr('faq_products_q5'),
          'answer': tr('faq_products_a5')
        },
        {
          'question': tr('faq_products_q6'),
          'answer': tr('faq_products_a6')
        },
        {
          'question': tr('faq_products_q7'),
          'answer': tr('faq_products_a7')
        },
        {
          'question': tr('faq_products_q8'),
          'answer': tr('faq_products_a8')
        },
        {
          'question': tr('faq_products_q9'),
          'answer': tr('faq_products_a9')
        },
        {
          'question': tr('faq_products_q10'),
          'answer': tr('faq_products_a10')
        }
      ]
    },
    {
      'category': tr('faq_category_leads'),
      'faqs': [
        {
          'question': tr('faq_leads_q1'),
          'answer': tr('faq_leads_a1')
        },
        {
          'question': tr('faq_leads_q2'),
          'answer': tr('faq_leads_a2')
        },
        {
          'question': tr('faq_leads_q3'),
          'answer': tr('faq_leads_a3')
        },
        {
          'question': tr('faq_leads_q4'),
          'answer': tr('faq_leads_a4')
        },
        {
          'question': tr('faq_leads_q5'),
          'answer': tr('faq_leads_a5')
        },
        {
          'question': tr('faq_leads_q6'),
          'answer': tr('faq_leads_a6')
        },
        {
          'question': tr('faq_leads_q7'),
          'answer': tr('faq_leads_a7')
        },
        {
          'question': tr('faq_leads_q8'),
          'answer': tr('faq_leads_a8')
        },
        {
          'question': tr('faq_leads_q9'),
          'answer': tr('faq_leads_a9')
        },
        {
          'question': tr('faq_leads_q10'),
          'answer': tr('faq_leads_a10')
        }
      ]
    },
    {
      'category': tr('faq_category_settings'),
      'faqs': [
        {
          'question': tr('faq_settings_q1'),
          'answer': tr('faq_settings_a1')
        },
        {
          'question': tr('faq_settings_q2'),
          'answer': tr('faq_settings_a2')
        },
        {
          'question': tr('faq_settings_q3'),
          'answer': tr('faq_settings_a3')
        },
        {
          'question': tr('faq_settings_q4'),
          'answer': tr('faq_settings_a4')
        },
        {
          'question': tr('faq_settings_q5'),
          'answer': tr('faq_settings_a5')
        },
        {
          'question': tr('faq_settings_q6'),
          'answer': tr('faq_settings_a6')
        },
        {
          'question': tr('faq_settings_q7'),
          'answer': tr('faq_settings_a7')
        },
        {
          'question': tr('faq_settings_q8'),
          'answer': tr('faq_settings_a8')
        },
        {
          'question': tr('faq_settings_q9'),
          'answer': tr('faq_settings_a9')
        },
        {
          'question': tr('faq_settings_q10'),
          'answer': tr('faq_settings_a10')
        }
      ]
    },
    {
      'category': tr('faq_category_subscription'),
      'faqs': [
        {
          'question': tr('faq_subscription_q1'),
          'answer': tr('faq_subscription_a1')
        },
        {
          'question': tr('faq_subscription_q2'),
          'answer': tr('faq_subscription_a2')
        },
        {
          'question': tr('faq_subscription_q3'),
          'answer': tr('faq_subscription_a3')
        },
        {
          'question': tr('faq_subscription_q4'),
          'answer': tr('faq_subscription_a4')
        },
        {
          'question': tr('faq_subscription_q5'),
          'answer': tr('faq_subscription_a5')
        },
        {
          'question': tr('faq_subscription_q6'),
          'answer': tr('faq_subscription_a6')
        },
        {
          'question': tr('faq_subscription_q7'),
          'answer': tr('faq_subscription_a7')
        }
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _filteredFaqs = List.from(_allFaqs);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterFAQs(_searchController.text);
  }

  void _filterFAQs(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredFaqs = List.from(_allFaqs);
      });
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      _filteredFaqs = _allFaqs.map((category) {
        final matchedFaqs = (category['faqs'] as List).where((faq) {
          final question = faq['question']?.toString().toLowerCase() ?? '';
          final answer = faq['answer']?.toString().toLowerCase() ?? '';
          return question.contains(lowerCaseQuery) || answer.contains(lowerCaseQuery);
        }).toList();

        if (matchedFaqs.isNotEmpty) {
          return {
            'category': category['category'],
            'faqs': matchedFaqs,
          };
        }
        
        return null;
      }).where((element) => element != null).toList().cast<Map<String, dynamic>>();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDialog = ModalRoute.of(context)?.settings.name == null;
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isMobile),
                  SizedBox(height: isMobile ? 16.0 : 24.0),
                  
                  // Search bar for filtering FAQs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: tr('faq_search_hint'),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 24.0 : 32.0),
                  
                  // Show different views based on search results
                  _filteredFaqs.isEmpty 
                    ? _buildEmptyState(context)
                    : _buildFaqSections(context, isMobile),
                    
                  SizedBox(height: isMobile ? 30 : 40),
                  
                  // Contact support section
                  _buildContactSupportSection(context, isMobile),
                ],
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
                  tooltip: tr('faq_close'),
                ),
              ),
          ],
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

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isMobile 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr('faq_page_title'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: isMobile ? 22 : null,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    tr('faq_page_title'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
        const SizedBox(height: 16),
        Text(
          tr('faq_page_subtitle'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey[600],
            fontSize: isMobile ? 14 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
        )),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  tr('faq_no_results'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  tr('faq_try_different_search'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.clear),
                  label: Text(tr('faq_clear_search')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqSections(BuildContext context, bool isMobile) {
    return Column(
      children: _filteredFaqs.map((category) {
        return _buildFaqCategory(context, category, isMobile);
      }).toList(),
    );
  }

  Widget _buildFaqCategory(BuildContext context, Map<String, dynamic> category, bool isMobile) {
    final faqs = category['faqs'] as List;
    if (faqs.isEmpty) return const SizedBox.shrink();
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category['category'],
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: isMobile ? 18 : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  return _buildFAQItem(
                    context,
                    faqs[index],
                    index,
                    faqs.length,
                    isMobile,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, Map<String, dynamic> faq, int index, int totalItems, bool isMobile) {
    return FaqExpansionTile(
      question: faq['question'],
      answer: faq['answer'],
      isLastItem: index == totalItems - 1,
      isMobile: isMobile,
    );
  }

  Widget _buildContactSupportSection(BuildContext context, bool isMobile) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.support_agent,
                            color: Colors.orange,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          tr('faq_still_have_questions'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 18 : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('faq_contact_support_desc'),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isMobile ? 14 : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.support_agent,
                          color: Colors.orange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('faq_still_have_questions'),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tr('faq_contact_support_desc'),
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              SizedBox(height: isMobile ? 16 : 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 500) {
                    return _buildContactMethod(
                      context,
                      Icons.email_outlined,
                      tr('faq_contact_email'),
                      tr('faq_email_address'),
                      Colors.blue,
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildContactMethod(
                            context,
                            Icons.email_outlined,
                            tr('faq_contact_email'),
                            tr('faq_email_address'),
                            Colors.blue,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactMethod(BuildContext context, IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class FaqExpansionTile extends StatefulWidget {
  final String question;
  final String answer;
  final bool isLastItem;
  final bool isMobile;
  
  const FaqExpansionTile({
    Key? key,
    required this.question,
    required this.answer,
    required this.isLastItem,
    this.isMobile = false,
  }) : super(key: key);

  @override
  State<FaqExpansionTile> createState() => _FaqExpansionTileState();
}

class _FaqExpansionTileState extends State<FaqExpansionTile> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.isMobile ? 14 : 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isExpanded ? null : 0,
          curve: Curves.easeInOut,
          child: Container(
            padding: EdgeInsets.only(
              left: widget.isMobile ? 12 : 16,
              right: widget.isMobile ? 12 : 16,
              bottom: widget.isMobile ? 12 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 1,
                  color: Colors.grey[200],
                  margin: const EdgeInsets.only(bottom: 16),
                ),
                Text(
                  widget.answer,
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.5,
                    fontSize: widget.isMobile ? 13 : 14,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ),
        if (!widget.isLastItem) const Divider(height: 1),
      ],
    );
  }
}
