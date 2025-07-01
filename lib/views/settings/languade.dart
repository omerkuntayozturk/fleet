import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fleet/info_card.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../services/user_service.dart';

class LanguagePage extends StatefulWidget {
  final bool isDialog;
  
  const LanguagePage({Key? key, this.isDialog = false}) : super(key: key);

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> 
    with SingleTickerProviderStateMixin {
  String selectedLanguage = 'Türkçe';
  late AnimationController _controller;
  final UserService _userService = UserService();
  bool _isLoading = false;
  bool _dataLoaded = false; // Add this flag to track if data is loaded

  // Language options
  final List<String> languages = [
    'Türkçe', 
    'English', 
    'Deutsch', 
    'Français', 
    'Español',
    'العربية',    // Arabic
    'Italiano',   // Italian
    '日本語',      // Japanese
    '한국어',      // Korean
    'Português',  // Portuguese
    'Русский',    // Russian
    '中文',        // Chinese
  ];

  final Map<String, String> languageDescriptions = {
    'Türkçe': tr('language_turkish_desc'),
    'English': tr('language_english_desc'),
    'Deutsch': tr('language_german_desc'),
    'Français': tr('language_french_desc'),
    'Español': tr('language_spanish_desc'),
    'العربية': tr('language_arabic_desc'),
    'Italiano': tr('language_italian_desc'),
    '日本語': tr('language_japanese_desc'),
    '한국어': tr('language_korean_desc'),
    'Português': tr('language_portuguese_desc'),
    'Русский': tr('language_russian_desc'),
    '中文': tr('language_chinese_desc'),
  };

  final Map<String, String> flagImages = {
    'Türkçe': 'assets/flags/tr.png',
    'English': 'assets/flags/gb.png',
    'Deutsch': 'assets/flags/de.png',
    'Français': 'assets/flags/fr.png',
    'Español': 'assets/flags/es.png',
    'العربية': 'assets/flags/sa.png',
    'Italiano': 'assets/flags/it.png',
    '日本語': 'assets/flags/jp.png',
    '한국어': 'assets/flags/kr.png',
    'Português': 'assets/flags/pt.png',
    'Русский': 'assets/flags/ru.png',
    '中文': 'assets/flags/cn.png',
  };

  // Map language names to locale codes for easy_localization
  final Map<String, String> languageCodes = {
    'Türkçe': 'tr',
    'English': 'en',
    'Deutsch': 'de',
    'Français': 'fr',
    'Español': 'es',
    'العربية': 'ar',
    'Italiano': 'it',
    '日本語': 'ja',
    '한국어': 'ko',
    'Português': 'pt',
    'Русский': 'ru',
    '中文': 'zh',
  };

  // Add any future or async operations here

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Load language data here instead
    if (!_dataLoaded) {
      // Synchronize language settings before loading
      _userService.synchronizeLanguageSettings().then((_) {
        _loadLanguageData();
      });
      _dataLoaded = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Load current language from the system
  Future<void> _loadLanguageData() async {
    if (_isLoading) return;
    
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      // Always prioritize the current app locale
      final currentLocale = context.locale.languageCode;
      debugPrint('Current app locale: $currentLocale');
      
      // Find the language name for the current locale
      bool foundMatch = false;
      for (var langName in languages) {
        if (languageCodes[langName] == currentLocale) {
          setStateIfMounted(() {
            selectedLanguage = langName;
          });
          foundMatch = true;
          debugPrint('Matched current locale to language: $langName');
          break;
        }
      }
      
      // Only fall back to saved preference if we couldn't match the current locale
      if (!foundMatch) {
        debugPrint('No match found for current locale, checking saved preference');
        String? savedLanguage = await _userService.getUserLanguage();
        if (savedLanguage != null && savedLanguage.isNotEmpty) {
          debugPrint('Using saved language preference: $savedLanguage');
          for (var langName in languages) {
            if (languageCodes[langName] == savedLanguage) {
              setStateIfMounted(() {
                selectedLanguage = langName;
              });
              debugPrint('Using saved language: $langName');
              break;
            }
          }
        }
      }
      
      setStateIfMounted(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading language data: $e');
      setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }

  // Update language selection, save it and close dialog if needed
  void _updateLanguageSelection(String language) {
    if (language == selectedLanguage) return; // Don't do anything if the same language is selected
    
    setStateIfMounted(() {
      selectedLanguage = language;
      _isLoading = true;
    });
    
    // Save the language after selection
    _saveSelectedLanguage(language);
  }
  
  // New method to save selected language and handle dialog closing
  Future<void> _saveSelectedLanguage(String language) async {
    try {
      // Get the locale code for the selected language
      final localeCode = languageCodes[language];
      debugPrint('Saving language selection: $language (code: $localeCode)');
      
      if (localeCode != null) {
        // First save the preference to both SharedPreferences and Firestore
        bool savedSuccessfully = await _userService.updateUserLanguage(localeCode);
        
        if (!savedSuccessfully) {
          throw Exception('Failed to save language preference');
        }
        
        // Then change the app locale
        await context.setLocale(Locale(localeCode));
        debugPrint('App locale changed to: $localeCode');
        
        // Show success message
        if (mounted) {
          InfoCard.showInfoCard(
            context,
            tr('language_save_success'),
            Colors.green,
            icon: Icons.check_circle,
          );
          
          // Close dialog if we're in dialog mode
          if (widget.isDialog && mounted) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving language settings: $e');
      // Handle errors
      if (mounted) {
        InfoCard.showInfoCard(
          context,
          tr('language_save_error'),
          Colors.red,
          icon: Icons.error,
        );
      }
    } finally {
      setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }

  // Safe setState helper method
  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    
    // Responsive padding based on screen size
    final EdgeInsets contentPadding = isMobile 
        ? const EdgeInsets.all(16)
        : isTablet 
            ? const EdgeInsets.all(20)
            : const EdgeInsets.all(24);

    Widget content = Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: contentPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Only show header section if not a dialog
                      if (!widget.isDialog)
                        _buildHeaderSection(context, isMobile),
                      
                      // If it's a dialog, we need our own title since appBar is not available
                      if (widget.isDialog)
                        _buildDialogHeader(context, isMobile),
                      
                      // Language options - now always visible
                      _buildLanguageOptionsSection(context, isMobile, isTablet),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        
        // Show loading indicator when processing language change
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        
        // Add X button in the top-right corner if shown as dialog
        if (widget.isDialog)
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              color: Colors.grey[700],
              tooltip: tr('language_close'),
            ),
          ),
      ],
    );

    // Return appropriate widget based on whether it's shown as dialog or full page
    if (widget.isDialog) {
      return content;
    } else {
      return Scaffold(
        appBar: const TopBar(),
        drawer: const SideMenu(currentPage: '/settings'),
        body: SafeArea(child: content),
      );
    }
  }

  Widget _buildDialogHeader(BuildContext context, bool isMobile) {
    final titleStyle = isMobile
        ? Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            )
        : Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            );
            
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
          fontSize: isMobile ? 12 : 14,
        );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('language_title'),
          style: titleStyle,
        ),
        const SizedBox(height: 8),
        Text(
          tr('language_subtitle'),
          style: subtitleStyle,
        ),
        SizedBox(height: isMobile ? 16 : 24),
      ],
    );
  }

  Widget _buildHeaderSection(BuildContext context, bool isMobile) {
    // On mobile, stack the title and back button in a more compact layout
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                  )),
                  child: Text(
                    tr('language_title'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                tooltip: tr('language_back'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
              ),
            ),
            child: Text(
              tr('language_subtitle'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    } else {
      // For larger screens, use the original layout
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
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
                        tr('language_title'),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
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
                        tr('language_subtitle'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                tooltip: tr('language_back'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      );
    }
  }

  Widget _buildLanguageOptionsSection(BuildContext context, bool isMobile, bool isTablet) {
    // Adjust font sizes based on screen size
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 18 : isTablet ? 20 : 22,
        );
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('language_options'),
          style: titleStyle,
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: languages.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final language = languages[index];
              return _buildLanguageOptionTile(
                context, 
                language, 
                languageDescriptions[language] ?? '',
                flagImages[language] ?? '',
                isMobile,
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildLanguageOptionTile(
    BuildContext context, 
    String language, 
    String description,
    String flagImagePath,
    bool isMobile,
  ) {
    final isSelected = selectedLanguage == language;
    
    // Create a more compact tile for mobile
    if (isMobile) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _updateLanguageSelection(language);
          },
          child: Container(
            color: isSelected 
                ? Colors.teal.withOpacity(0.05) 
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Row(
              children: [
                // Flag container
                Container(
                  width: 32,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.grey.shade300, 
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      language.substring(0, language.length >= 2 ? 2 : 1),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Language name and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.teal : null,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Selected indicator
                if (isSelected) 
                  const Icon(Icons.check_circle, color: Colors.teal, size: 20)
              ],
            ),
          ),
        ),
      );
    } else {
      // Original design for larger screens
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _updateLanguageSelection(language);
          },
          child: Container(
            color: isSelected 
                ? Colors.teal.withOpacity(0.05) 
                : Colors.transparent,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.grey.shade300, 
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    language.substring(0, 2),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              title: Text(
                language,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.teal : null,
                ),
              ),
              subtitle: Text(
                description,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: isSelected 
                ? const Icon(Icons.check_circle, color: Colors.teal)
                : null,
              contentPadding: 
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      );
    }
  }
}
