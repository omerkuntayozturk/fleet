import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fleet/info_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../services/user_service.dart';

class CurrencyPage extends StatefulWidget {
  final bool isDialog;
  final Function(Map<String, dynamic>)? onCurrencySelected;

  const CurrencyPage({
    Key? key,
    this.isDialog = false,
    this.onCurrencySelected,
  }) : super(key: key);

  @override
  State<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCurrencyIndex = 0; // Default to the first currency
  late AnimationController _controller;
  bool _isLoading = false;

  // Instance of UserService
  final UserService _userService = UserService();

  // Constants for SharedPreferences keys
  static const String _currencyPrefKey = 'selected_currency';

  // List of currencies with their symbols, names, and codes
  final List<Map<String, dynamic>> _currencies = [
    {'symbol': '₺', 'nameKey': 'currency_try', 'code': 'TRY'},
    {'symbol': '\$', 'nameKey': 'currency_usd', 'code': 'USD'},
    {'symbol': '€', 'nameKey': 'currency_eur', 'code': 'EUR'},
    {'symbol': '¥', 'nameKey': 'currency_jpy', 'code': 'JPY'},
    {'symbol': '£', 'nameKey': 'currency_gbp', 'code': 'GBP'},
    {'symbol': '¥', 'nameKey': 'currency_cny', 'code': 'CNY'},
    {'symbol': 'CA\$', 'nameKey': 'currency_cad', 'code': 'CAD'},
    {'symbol': 'CHF', 'nameKey': 'currency_chf', 'code': 'CHF'},
    {'symbol': 'A\$', 'nameKey': 'currency_aud', 'code': 'AUD'},
    {'symbol': '₩', 'nameKey': 'currency_krw', 'code': 'KRW'},
    {'symbol': 'S\$', 'nameKey': 'currency_sgd', 'code': 'SGD'},
    {'symbol': 'HK\$', 'nameKey': 'currency_hkd', 'code': 'HKD'},
    {'symbol': 'kr', 'nameKey': 'currency_nok', 'code': 'NOK'},
    {'symbol': 'kr', 'nameKey': 'currency_sek', 'code': 'SEK'},
    {'symbol': 'NZ\$', 'nameKey': 'currency_nzd', 'code': 'NZD'},
    {'symbol': '₹', 'nameKey': 'currency_inr', 'code': 'INR'},
    {'symbol': '₽', 'nameKey': 'currency_rub', 'code': 'RUB'},
    {'symbol': 'R\$', 'nameKey': 'currency_brl', 'code': 'BRL'},
    {'symbol': 'R', 'nameKey': 'currency_zar', 'code': 'ZAR'},
    {'symbol': '฿', 'nameKey': 'currency_thb', 'code': 'THB'},
    {'symbol': 'zł', 'nameKey': 'currency_pln', 'code': 'PLN'},
    {'symbol': '\$', 'nameKey': 'currency_mxn', 'code': 'MXN'},
    {'symbol': 'RM', 'nameKey': 'currency_myr', 'code': 'MYR'},
    {'symbol': '₪', 'nameKey': 'currency_ils', 'code': 'ILS'},
    {'symbol': 'Rp', 'nameKey': 'currency_idr', 'code': 'IDR'},
    {'symbol': '﷼', 'nameKey': 'currency_sar', 'code': 'SAR'},
    {'symbol': 'د.إ', 'nameKey': 'currency_aed', 'code': 'AED'},
    {'symbol': 'Kč', 'nameKey': 'currency_czk', 'code': 'CZK'},
    {'symbol': '₱', 'nameKey': 'currency_php', 'code': 'PHP'},
    {'symbol': 'kr', 'nameKey': 'currency_dkk', 'code': 'DKK'},
  ];

  // Get the translated name for a currency
  String _getTranslatedCurrencyName(String nameKey) {
    return tr(nameKey);
  }

  List<Map<String, dynamic>> get _filteredCurrencies {
    if (_searchQuery.isEmpty) {
      return _currencies;
    }
    
    return _currencies.where((currency) {
      final translatedName = _getTranslatedCurrencyName(currency['nameKey']);
      return translatedName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          currency['code'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _searchController.addListener(_onSearchChanged);
    _loadCurrencyData();
    
    // Synchronize currency settings and load saved currency
    _userService.synchronizeCurrencySettings().then((_) {
      _loadSavedCurrency();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Load saved currency from UserService
  Future<void> _loadSavedCurrency() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // First try to get from UserService (which checks both Firestore and SharedPreferences)
      final savedCurrencyCode = await _userService.getUserCurrency();
      
      if (savedCurrencyCode != null) {
        // Find the index of the saved currency in the currencies list
        for (int i = 0; i < _currencies.length; i++) {
          if (_currencies[i]['code'] == savedCurrencyCode) {
            if (mounted) {
              setState(() {
                _selectedCurrencyIndex = i;
              });
            }
            break;
          }
        }
      } else {
        // Fallback to SharedPreferences for backwards compatibility
        final prefs = await SharedPreferences.getInstance();
        final localCurrencyCode = prefs.getString(_currencyPrefKey);
        
        if (localCurrencyCode != null) {
          // Find the index of the saved currency in the currencies list
          for (int i = 0; i < _currencies.length; i++) {
            if (_currencies[i]['code'] == localCurrencyCode) {
              if (mounted) {
                setState(() {
                  _selectedCurrencyIndex = i;
                });
              }
              break;
            }
          }
          
          // Update the UserService with this currency
          await _userService.updateUserCurrency(localCurrencyCode);
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading saved currency: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save selected currency using UserService
  Future<void> _saveCurrencyToPrefs(Map<String, dynamic> currency) async {
    try {
      final currencyCode = currency['code'];
      
      // Save to UserService (which saves to both Firestore and SharedPreferences)
      final success = await _userService.updateUserCurrency(currencyCode);
      
      // Show success message when currency is saved successfully
      if (mounted && success) {
        InfoCard.showInfoCard(
          context,
          tr('currency_saved_to_preferences'),
          Colors.green,
          icon: Icons.check_circle,
        );
      } else if (mounted && !success) {
        InfoCard.showInfoCard(
          context,
          tr('currency_save_error'),
          Colors.red,
          icon: Icons.error,
        );
      }
    } catch (e) {
      debugPrint('Error saving currency: $e');
      if (mounted) {
        InfoCard.showInfoCard(
          context,
          tr('currency_save_error'),
          Colors.red,
          icon: Icons.error,
        );
      }
    }
  }

  // Example method for async operations
  Future<void> _loadCurrencyData() async {
    if (_isLoading) return;
    
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      // Simulate network request
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _selectCurrency(int index) {
    setState(() {
      _selectedCurrencyIndex = index;
    });

    // Save and close dialog immediately when in dialog mode
    if (widget.isDialog) {
      final selectedCurrency = _currencies[index];
      
      // Save to preferences
      _saveCurrencyToPrefs(selectedCurrency);
      
      // Prepare the currency data to send back to the parent widget
      final Map<String, dynamic> currencyData = {
        'symbol': selectedCurrency['symbol'],
        'name': _getTranslatedCurrencyName(selectedCurrency['nameKey']),
        'code': selectedCurrency['code'],
      };
      
      if (widget.onCurrencySelected != null) {
        widget.onCurrencySelected!(currencyData);
      }
      
      // Show success message
      InfoCard.showInfoCard(
        context,
        tr('currency_saved_successfully'),
        Colors.green,
        icon: Icons.check_circle,
      );
      
      // Close the dialog
      Navigator.of(context).pop();
    } 
    // If not in dialog mode, just save
    else if (widget.onCurrencySelected != null) {
      // Save the selected currency to preferences
      _saveCurrencyToPrefs(_currencies[index]);

      // Pass data back to parent in the expected format
      final selectedCurrency = _currencies[index];
      widget.onCurrencySelected!({
        'symbol': selectedCurrency['symbol'],
        'name': _getTranslatedCurrencyName(selectedCurrency['nameKey']),
        'code': selectedCurrency['code'],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final double horizontalPadding = isSmallScreen ? 16 : 24;
    
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isSmallScreen ? 16 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Only show header section if not a dialog
                    if (!widget.isDialog)
                      _buildResponsiveHeaderSection(context, isSmallScreen),
                    
                    // If it's a dialog, we need our own title since appBar is not available
                    if (widget.isDialog)
                      _buildDialogHeader(context, isSmallScreen),
                    
                    // Search bar
                    _buildSearchBar(context, isSmallScreen),
                    
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    
                    // Currency options
                    _buildResponsiveCurrencyOptionsSection(context, constraints, isSmallScreen),
                  ],
                ),
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
                  tooltip: tr('close'),
                ),
              ),
          ],
        );
      }
    );

    // Return appropriate widget based on whether it's shown as dialog or full page
    if (widget.isDialog) {
      return content;
    } else {
      return Scaffold(
        appBar: const TopBar(),
        drawer: const SideMenu(currentPage: '/settings'),
        body: content,
      );
    }
  }

  Widget _buildDialogHeader(BuildContext context, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('currency_selection_title'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
            fontSize: isSmallScreen ? 20 : 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr('currency_selection_subtitle'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 24),
      ],
    );
  }

  Widget _buildResponsiveHeaderSection(BuildContext context, bool isSmallScreen) {
    if (isSmallScreen) {
      // Stack header elements vertically on small screens
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  tr('currency_selection_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                tooltip: tr('back'),
              ),
            ],
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
              tr('currency_selection_subtitle'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    } else {
      // Use original row layout for larger screens
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
                  tr('currency_selection_title'),
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
                  tr('currency_selection_subtitle'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            tooltip: tr('back'),
          ),
        ],
      );
    }
  }

  Widget _buildSearchBar(BuildContext context, bool isSmallScreen) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16, 
          vertical: isSmallScreen ? 6 : 8
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: tr('currency_search_placeholder'),
            prefixIcon: const Icon(Icons.search, color: Colors.teal),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveCurrencyOptionsSection(BuildContext context, BoxConstraints constraints, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('available_currencies'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 22,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        // Responsive currency grid/list
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: constraints.maxWidth > 700 && _filteredCurrencies.length > 4
              ? _buildCurrencyGrid(context, isSmallScreen)
              : _buildCurrencyList(context, isSmallScreen),
        ),
      ],
    );
  }
  
  Widget _buildCurrencyList(BuildContext context, bool isSmallScreen) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredCurrencies.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final currency = _filteredCurrencies[index];
        final currencyIndex = _currencies.indexOf(currency);
        return _buildResponsiveCurrencyTile(context, currency, currencyIndex, isSmallScreen);
      },
    );
  }
  
  Widget _buildCurrencyGrid(BuildContext context, bool isSmallScreen) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 1 : 
                     MediaQuery.of(context).size.width > 1100 ? 3 : 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: _filteredCurrencies.length,
      itemBuilder: (context, index) {
        final currency = _filteredCurrencies[index];
        final currencyIndex = _currencies.indexOf(currency);
        return _buildResponsiveCurrencyTile(context, currency, currencyIndex, isSmallScreen);
      },
    );
  }
  
  Widget _buildResponsiveCurrencyTile(BuildContext context, Map<String, dynamic> currency, int index, bool isSmallScreen) {
    final isSelected = _selectedCurrencyIndex == index;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectCurrency(index),
        child: Container(
          color: isSelected 
              ? Colors.teal.withOpacity(0.05) 
              : Colors.transparent,
          child: ListTile(
            dense: isSmallScreen,
            leading: Container(
              width: isSmallScreen ? 36 : 40,
              height: isSmallScreen ? 36 : 40,
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 20),
              ),
              child: Center(
                child: Text(
                  currency['symbol'],
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              _getTranslatedCurrencyName(currency['nameKey']),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.teal : null,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              currency['code'],
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
            trailing: isSelected 
              ? Icon(Icons.check_circle, color: Colors.teal, size: isSmallScreen ? 20 : 24)
              : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16, 
              vertical: isSmallScreen ? 4 : 8
            ),
          ),
        ),
      ),
    );
  }
}
