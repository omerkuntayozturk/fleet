import 'package:fleet/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../../services/user_service.dart'; // Import UserService
import 'package:firebase_auth/firebase_auth.dart'; // Kullanıcı id için
import '../../services/employee_service.dart'; // EmployeeService import edildi
import '../../services/firebase_service.dart'; // Firestore erişimi için ekle

// Convert to StatefulWidget
class SalesActivities extends StatefulWidget {
  final Map<String, int> contractStatusCounts;
  final double averageContractDuration;
  final double averageSkillLevel;
  final int totalDepartments;
  final int totalEmployees;
  final int totalSkills;
  final String membershipPlan;
  final bool isLoading;
  final String Function(double) formatCurrency;
  // Add callback function for date range changes
  final Function(String dateRange, {DateTimeRange? customDateRange})? onDateRangeChanged;

  const SalesActivities({
    Key? key,
    required this.contractStatusCounts,
    required this.averageContractDuration,
    required this.averageSkillLevel,
    required this.totalDepartments,
    required this.totalEmployees,
    required this.totalSkills,
    required this.membershipPlan,
    required this.isLoading,
    required this.formatCurrency,
    this.onDateRangeChanged,
  }) : super(key: key);

  @override
  State<SalesActivities> createState() => _SalesActivitiesState();
}

class _SalesActivitiesState extends State<SalesActivities> {
  final UserService _userService = UserService();
  final EmployeeService _employeeService = EmployeeService(); // EmployeeService örneği
  final FirestoreService _firestoreService = FirestoreService(); // Firestore servisi eklendi
  String _currencySymbol = '₺'; // Default currency symbol
  String _selectedDateRange = 'this_month'; // Default to "this month"
  DateTimeRange? _customDateRange; // Store custom date range when selected

  // Sözleşme istatistikleri
  int _activeContracts = 0;
  int _endingSoonContracts = 0;
  int _completedContracts = 0;
  bool _statsLoading = true;
// Ortalama sözleşme süresi (gün)
  double _totalOdometer = 0; // Toplam kilometre (tarih filtresine göre)
  int _totalVehicles = 0; // Toplam araç sayısı
  int _totalServiceEntries = 0; // Toplam servis kaydı
  int _totalEmployees = 0; // Toplam çalışan sayısı

  // Araç ve son km bilgisini tutmak için yeni bir liste

  // Define date range options with icons and labels
  final List<Map<String, dynamic>> _dateRangeOptions = [
    {'value': 'today', 'label': 'sales_activities_today', 'icon': Icons.today},
    {'value': 'yesterday', 'label': 'sales_activities_yesterday', 'icon': Icons.history},
    {'value': 'last_week', 'label': 'sales_activities_last_week', 'icon': Icons.calendar_view_week},
    {'value': 'last_month', 'label': 'sales_activities_last_month', 'icon': Icons.calendar_view_month},
    {'value': 'this_month', 'label': 'sales_activities_this_month', 'icon': Icons.calendar_today},
    {'value': 'all_time', 'label': 'sales_activities_all_time', 'icon': Icons.all_inclusive}, // <-- eklendi
    {'value': 'custom', 'label': 'sales_activities_custom_date', 'icon': Icons.date_range},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrencySymbol();
    _loadContractStats(); // Sözleşme istatistiklerini yükle
    _loadOdometerStats(); // Odometer bilgisini yükle
    _loadVehicleStats(); // Araç bilgisini yükle
    _loadServiceEntryStats(); // Servis kaydı bilgisini yükle
    _loadEmployeeStats(); // Çalışan bilgisini yükle
  }

  // Load user's currency symbol
  Future<void> _loadCurrencySymbol() async {
    try {
      final currencyCode = await _userService.getUserCurrency();
      if (currencyCode != null) {
        // Find matching currency symbol from the code
        final symbol = _getCurrencySymbolFromCode(currencyCode);
        setState(() {
          _currencySymbol = symbol;
        });
      } else {
        setState(() {
          _currencySymbol = '₺'; // Default to Turkish Lira
        });
      }
    } catch (e, st) {
      debugPrint('Error loading currency symbol: $e\n$st');
      setState(() {
        _currencySymbol = '₺'; // Default to Turkish Lira
      });
    }
  }

  // Get currency symbol from currency code
  String _getCurrencySymbolFromCode(String code) {
    // Map common currency codes to symbols
    final Map<String, String> symbolMap = {
      'TRY': '₺',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CNY': '¥',
      'CAD': 'CA\$',
      'CHF': 'CHF',
      'AUD': 'A\$',
      'KRW': '₩',
      'SGD': 'S\$',
      'HKD': 'HK\$',
      'NOK': 'kr',
      'SEK': 'kr',
      'NZD': 'NZ\$',
      'INR': '₹',
      'RUB': '₽',
      'BRL': 'R\$',
      'ZAR': 'R',
      'THB': '฿',
      'PLN': 'zł',
      'MXN': '\$',
      'MYR': 'RM',
      'ILS': '₪',
      'IDR': 'Rp',
      'SAR': '﷼',
      'AED': 'د.إ',
      'CZK': 'Kč',
      'PHP': '₱',
      'DKK': 'kr',
    };

    return symbolMap[code] ?? code; // Return the code itself as a fallback
  }

  // Format currency with current symbol
  String _formatWithCurrencySymbol(double amount) {
    // Use the current currency symbol with the existing format logic
    String formatted = widget.formatCurrency(amount);
    // Replace any existing currency symbol with the current one
    return _currencySymbol + formatted.replaceAll(RegExp(r'[^\d.,]'), '');
  }

  // Get formatted membership plan name for display
  String _getFormattedPlanName() {
    switch (widget.membershipPlan.toLowerCase()) {
      case 'monthly':
        return tr('sales_activities_monthly_premium');
      case 'yearly':
        return tr('sales_activities_yearly_premium');
      case 'free':
      default:
        return tr('sales_activities_free_plan');
    }
  }

  // Get current selected date range display text
  String _getSelectedDateRangeDisplayText() {
    if (_selectedDateRange == 'custom' && _customDateRange != null) {
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      return '${formatter.format(_customDateRange!.start)} - ${formatter.format(_customDateRange!.end)}';
    }
    // ...all_time için özel çeviri...
    if (_selectedDateRange == 'all_time') {
      return tr('sales_activities_all_time');
    }
    return tr(_dateRangeOptions.firstWhere(
      (option) => option['value'] == _selectedDateRange, 
      orElse: () => _dateRangeOptions[4] // Default to "this month"
    )['label']);
  }

  // Show date filter popup menu - REPLACE with a better dialog
  void _showDateFilterMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DateRangeSelectionDialog(
          selectedRange: _selectedDateRange,
          dateRangeOptions: _dateRangeOptions,
          customDateRange: _customDateRange,
          onRangeSelected: (value, customRange) {
            setState(() {
              _selectedDateRange = value;
              if (customRange != null) {
                // Make sure we create a new instance to trigger proper updates
                _customDateRange = DateTimeRange(
                  start: customRange.start,
                  end: customRange.end,
                );
                debugPrint('Custom date range set to: ${_customDateRange!.start} - ${_customDateRange!.end}');
              }
            });
            
            // Always notify parent of the change, even for custom ranges
            _notifyParentOfDateChange();
          },
        );
      },
    );
  }
  
  // Notify parent component about date change
  void _notifyParentOfDateChange() async {
    try {
      if (widget.onDateRangeChanged != null) {
        if (_selectedDateRange == 'custom' && _customDateRange == null) {
          final now = DateTime.now();
          _customDateRange = DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          );
        }
        widget.onDateRangeChanged!(
          _selectedDateRange,
          customDateRange: _selectedDateRange == 'custom' ? _customDateRange : null,
        );
      }
      setState(() {
        _statsLoading = true;
      });

      // Her yükleme fonksiyonunu sırayla çağır, böylece biri hata verirse diğerleri yine de çalışır.
      await _loadContractStats();
      await _loadOdometerStats();
      await _loadVehicleStats();
      await _loadServiceEntryStats();

      setState(() {
        _statsLoading = false;
      });
    } catch (e, st) {
      debugPrint('Error in _notifyParentOfDateChange: $e\n$st');
      setState(() {
        _statsLoading = false;
      });
    }
  }

  // Firestore'dan aktif, yakında bitecek ve tamamlanan sözleşme sayılarını ve ortalama süreyi çek
  Future<void> _loadContractStats() async {
    try {
      setState(() {
        _statsLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _activeContracts = 0;
          _endingSoonContracts = 0;
          _completedContracts = 0;
          _statsLoading = false;
        });
        return;
      }

      // Tarih aralığını belirle
      DateTime? startDate;
      DateTime? endDate;
      if (_selectedDateRange == 'custom' && _customDateRange != null) {
        startDate = _customDateRange!.start;
        endDate = _customDateRange!.end;
      } else {
        final now = DateTime.now();
        switch (_selectedDateRange) {
          case 'today':
            startDate = DateTime(now.year, now.month, now.day);
            endDate = now;
            break;
          case 'yesterday':
            final yesterday = now.subtract(const Duration(days: 1));
            startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
            endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
            break;
          case 'last_week':
            startDate = now.subtract(const Duration(days: 7));
            endDate = now;
            break;
          case 'last_month':
            startDate = DateTime(now.year, now.month - 1, now.day);
            endDate = now;
            break;
          case 'this_month':
            startDate = DateTime(now.year, now.month, 1);
            endDate = now;
            break;
          case 'all_time':
            startDate = DateTime(2000, 1, 1); // Çok eski bir tarih
            endDate = DateTime(2100, 1, 1);  // Uzak gelecek tarihi
            break;
          default:
            startDate = DateTime(now.year, now.month, 1);
            endDate = now;
            break;
        }
      }

      debugPrint('Loading contracts from $startDate to $endDate');
      
      // Firestore'dan sözleşmeleri çek
      final contracts = await _firestoreService.fetchContracts(userId: user.uid);
      
      // İstatistikleri hesapla
      int active = 0;
      int endingSoon = 0;
      int completed = 0;
      final now = DateTime.now();
      
      debugPrint('Toplam ${contracts.length} sözleşme bulundu.');
      
      for (final contract in contracts) {
        // Debug çıktıları ekleyelim
        debugPrint('Sözleşme ID: ${contract.id}, Durum: ${contract.status}, Bitiş: ${contract.endDate}');
        
        // Aktif sözleşme kontrolü - String ve enum kontrolleri birlikte
        bool isActive = false;
        
        // Durumu string olarak kontrol et (Firestore'dan string formatında gelmiş olabilir)
        final statusStr = contract.status.toString();
        if (statusStr.contains('ongoing') || statusStr == 'ContractStatus.ongoing') {
          isActive = true;
        }
        
        // Bitiş tarihi kontrolü
        if (isActive || contract.endDate.isAfter(now)) {
          // Sözleşme aktif
          active++;
          debugPrint('Aktif sözleşme: ${contract.id}, bitiş: ${contract.endDate}');
          
          // Yakında bitecek mi kontrol et (30 gün içinde)
          final daysUntilEnd = contract.endDate.difference(now).inDays;
          if (daysUntilEnd <= 30 && daysUntilEnd >= 0) {
            endingSoon++;
            debugPrint('Yakında bitecek: ${contract.id}, kalan gün: $daysUntilEnd');
          }
        } 
        // Tamamlanmış sözleşmeler
        else if (contract.status.toString().contains('expired') || 
                 contract.status.toString().contains('terminated') ||
                 contract.endDate.isBefore(now)) {
          completed++;
          debugPrint('Tamamlanmış sözleşme: ${contract.id}');
        }
      }

      debugPrint('Aktif: $active, Yakında bitecek: $endingSoon, Tamamlanmış: $completed');

      setState(() {
        _activeContracts = active;
        _endingSoonContracts = endingSoon;
        _completedContracts = completed;
        _statsLoading = false;
      });
    } catch (e, st) {
      debugPrint('Error loading contract stats: $e\n$st');
      setState(() {
        _activeContracts = 0;
        _endingSoonContracts = 0;
        _completedContracts = 0;
        _statsLoading = false;
      });
    }
  }

  // Toplam kilometreyi Firestore'dan, seçilen tarih filtresine göre hesapla
  Future<void> _loadOdometerStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _totalOdometer = 0;
        });
        return;
      }

      // Tarih aralığını belirle
      DateTime? startDate;
      DateTime? endDate;
      if (_selectedDateRange == 'custom' && _customDateRange != null) {
        startDate = _customDateRange!.start;
        endDate = _customDateRange!.end;
      } else {
        final now = DateTime.now();
        switch (_selectedDateRange) {
          case 'today':
            startDate = DateTime(now.year, now.month, now.day);
            endDate = now;
            break;
          case 'yesterday':
            final yesterday = now.subtract(const Duration(days: 1));
            startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
            endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
            break;
          case 'last_week':
            startDate = now.subtract(const Duration(days: 7));
            endDate = now;
            break;
          case 'last_month':
            startDate = DateTime(now.year, now.month - 1, now.day);
            endDate = now;
            break;
          case 'this_month':
          default:
            startDate = DateTime(now.year, now.month, 1);
            endDate = now;
            break;
        }
      }

      // Firestore'dan odometer kayıtlarını çek (createdAt'e göre filtrele)
      final firestore = FirebaseService().firestore;
      final odometerQuery = firestore
          .collection('users')
          .doc(user.uid)
          .collection('odometers')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate);

      final odometerSnapshot = await odometerQuery.get();

      double total = 0;
      List<Map<String, dynamic>> vehicleOdoList = [];

      // Her kaydı işle
      for (final doc in odometerSnapshot.docs) {
        final data = doc.data();
        final value = (data['value'] ?? 0).toDouble();
        total += value;

        // Araç detayları için (model/plate) Firestore'dan çekmek gerekirse burada eklenebilir
        vehicleOdoList.add({
          'model': data['vehicleModel'] ?? '',
          'plate': data['vehiclePlate'] ?? '',
          'lastOdometer': value,
        });
      }

      setState(() {
        _totalOdometer = total;
      });
    } catch (e, st) {
      debugPrint('Error loading odometer stats: $e\n$st');
      setState(() {
        _totalOdometer = 0;
      });
    }
  }

  // Toplam araç sayısını Firestore'dan, seçilen tarih filtresine göre hesapla
  Future<void> _loadVehicleStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _totalVehicles = 0;
        });
        return;
      }

      // Tarih aralığını belirle
      DateTime? startDate;
      DateTime? endDate;
      if (_selectedDateRange == 'custom' && _customDateRange != null) {
        startDate = _customDateRange!.start;
        endDate = _customDateRange!.end;
      } else {
        final now = DateTime.now();
        switch (_selectedDateRange) {
          case 'today':
            startDate = DateTime(now.year, now.month, now.day);
            endDate = now;
            break;
          case 'yesterday':
            final yesterday = now.subtract(const Duration(days: 1));
            startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
            endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
            break;
          case 'last_week':
            startDate = now.subtract(const Duration(days: 7));
            endDate = now;
            break;
          case 'last_month':
            startDate = DateTime(now.year, now.month - 1, now.day);
            endDate = now;
            break;
          case 'this_month':
          default:
            startDate = DateTime(now.year, now.month, 1);
            endDate = now;
            break;
        }
      }

      // Firestore'dan araç kayıtlarını çek (createdAt'e göre filtrele)
      final firestore = FirebaseService().firestore;
      final vehiclesQuery = firestore
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate);

      final vehiclesSnapshot = await vehiclesQuery.get();

      setState(() {
        _totalVehicles = vehiclesSnapshot.size;
      });
    } catch (e, st) {
      debugPrint('Error loading vehicle stats: $e\n$st');
      setState(() {
        _totalVehicles = 0;
      });
    }
  }

  // Toplam servis kaydı sayısını Firestore'dan, seçilen tarih filtresine göre hesapla
  Future<void> _loadServiceEntryStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _totalServiceEntries = 0;
        });
        return;
      }

      // Tarih aralığını belirle
      DateTime? startDate;
      DateTime? endDate;
      if (_selectedDateRange == 'custom' && _customDateRange != null) {
        startDate = _customDateRange!.start;
        endDate = _customDateRange!.end;
      } else {
        final now = DateTime.now();
        switch (_selectedDateRange) {
          case 'today':
            startDate = DateTime(now.year, now.month, now.day);
            endDate = now;
            break;
          case 'yesterday':
            final yesterday = now.subtract(const Duration(days: 1));
            startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
            endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
            break;
          case 'last_week':
            startDate = now.subtract(const Duration(days: 7));
            endDate = now;
            break;
          case 'last_month':
            startDate = DateTime(now.year, now.month - 1, now.day);
            endDate = now;
            break;
          case 'this_month':
          default:
            startDate = DateTime(now.year, now.month, 1);
            endDate = now;
            break;
        }
      }

      // Firestore'dan servis kayıtlarını çek (createdAt'e göre filtrele)
      final firestore = FirebaseService().firestore;
      final servicesQuery = firestore
          .collection('users')
          .doc(user.uid)
          .collection('services')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate);

      final servicesSnapshot = await servicesQuery.get();

      // Her servise giden aracın id'sini benzersiz olarak say
      final vehicleIds = <String>{};
      for (final doc in servicesSnapshot.docs) {
        final data = doc.data();
        final vehicleId = data['vehicleId'];
        if (vehicleId != null && vehicleId.toString().isNotEmpty) {
          vehicleIds.add(vehicleId.toString());
        }
      }

      setState(() {
        _totalServiceEntries = vehicleIds.length;
      });
    } catch (e, st) {
      debugPrint('Error loading service entry stats: $e\n$st');
      setState(() {
        _totalServiceEntries = 0;
      });
    }
  }

  // Toplam çalışan sayısını hesapla
  Future<void> _loadEmployeeStats() async {
    try {
      final employees = await _employeeService.getAll();
      setState(() {
        _totalEmployees = employees.length;
      });
    } catch (e, st) {
      debugPrint('Error loading employee stats: $e\n$st');
      setState(() {
        _totalEmployees = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're on a mobile device or small screen
        final isMobile = constraints.maxWidth < 768;
        final isVerySmall = constraints.maxWidth < 480;
        
        // Adjust card sizes based on screen width
        final cardPadding = isVerySmall ? 12.0 : (isMobile ? 16.0 : 20.0);
        final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 20 : 24,
        );
        
        return FadeTransition(
          opacity: const AlwaysStoppedAnimation(1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and date filter in a row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('hr_dashboard_title'),
                    style: titleStyle,
                  ),
                  // Date filter button with popup menu
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showDateFilterMenu,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              _selectedDateRange == 'custom' 
                                  ? Icons.date_range 
                                  : _dateRangeOptions.firstWhere(
                                      (option) => option['value'] == _selectedDateRange,
                                      orElse: () => {'icon': Icons.calendar_today}
                                    )['icon'],
                              size: 18,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getSelectedDateRangeDisplayText(),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Theme.of(context).primaryColor,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_statsLoading || widget.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildResponsiveCardGrid(
                  context,
                  [
                    _buildStatCardData(
                      Icons.trending_up,
                      tr('hr_active_contracts'),
                      '$_activeContracts',
                      Colors.green,
                    ),
                    _buildStatCardData(
                      Icons.access_time,
                      tr('hr_ending_soon_contracts'),
                      '$_endingSoonContracts',
                      Colors.orange,
                    ),
                    _buildStatCardData(
                      Icons.check_circle,
                      tr('hr_completed_contracts'),
                      '$_completedContracts',
                      Colors.blue,
                    ),
                    _buildStatCardData(
                      Icons.people, // Çalışanlar için uygun ikon
                      tr('hr_employees'), // Çeviri anahtarı: çalışanlar
                      '$_totalEmployees',
                      Colors.amber,
                    ),
                  ],
                  isMobile,
                  isVerySmall,
                  cardPadding,
                ),
              const SizedBox(height: 16),
              if (!widget.isLoading)
                _buildResponsiveCardGrid(
                  context,
                  [
                    _buildStatCardData(
                      Icons.speed,
                      tr('hr_total_odometer'),
                      _totalOdometer.toStringAsFixed(0) + ' km',
                      Colors.purple,
                    ),
                    _buildStatCardData(
                      Icons.directions_car,
                      tr('hr_vehicles'),
                      '$_totalVehicles',
                      Colors.teal,
                    ),
                    _buildStatCardData(
                      Icons.build,
                      tr('hr_service_entries'),
                      '$_totalServiceEntries',
                      Colors.deepOrange,
                    ),
                    _buildStatCardData(
                      Icons.card_membership,
                      tr('hr_subscription_plan'),
                      _getFormattedPlanName(),
                      Colors.indigo,
                    ),
                  ],
                  isMobile,
                  isVerySmall,
                  cardPadding,
                ),
            ],
          ),
        );
      }
    );
  }

  // Data class for stat card properties
  Map<String, dynamic> _buildStatCardData(IconData icon, String title, String value, Color color) {
    return {
      'icon': icon,
      'title': title,
      'value': value,
      'color': color,
    };
  }

  // Build a responsive grid of cards that adapts to screen size
  Widget _buildResponsiveCardGrid(
    BuildContext context,
    List<Map<String, dynamic>> cardDataList,
    bool isMobile,
    bool isVerySmall,
    double cardPadding,
  ) {
    // For very small screens, stack all cards vertically
    if (isVerySmall) {
      return Column(
        children: cardDataList.map((data) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildStatCard(
              context,
              data['icon'],
              data['title'],
              data['value'],
              data['color'],
              cardPadding,
            ),
          );
        }).toList(),
      );
    }
    
    // For mobile screens, display two cards per row
    if (isMobile) {
      return Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        children: cardDataList.map((data) {
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 12.0) / 2, // 2 cards per row with spacing
            child: _buildStatCard(
              context,
              data['icon'],
              data['title'],
              data['value'],
              data['color'],
              cardPadding,
            ),
          );
        }).toList(),
      );
    }
    
    // For desktop/tablet, use a row layout
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cardDataList.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 16.0,
              right: index == cardDataList.length - 1 ? 0 : 0,
            ),
            child: _buildStatCard(
              context,
              data['icon'],
              data['title'],
              data['value'],
              data['color'],
              cardPadding,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Modified stat card with adaptive sizing
  Widget _buildStatCard(
    BuildContext context, 
    IconData icon, 
    String title, 
    String value, 
    Color color, 
    double padding
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: isSmallScreen ? 14 : null,
                ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: isSmallScreen ? 16 : 20,
                ),
          ),
        ],
      ),
    );
  }
}

// Completely redesigned date range selection dialog with better UI/UX
class DateRangeSelectionDialog extends StatefulWidget {
  final String selectedRange;
  final List<Map<String, dynamic>> dateRangeOptions;
  final DateTimeRange? customDateRange;
  final Function(String, DateTimeRange?) onRangeSelected;

  const DateRangeSelectionDialog({
    Key? key,
    required this.selectedRange,
    required this.dateRangeOptions,
    this.customDateRange,
    required this.onRangeSelected,
  }) : super(key: key);

  @override
  State<DateRangeSelectionDialog> createState() => _DateRangeSelectionDialogState();
}

class _DateRangeSelectionDialogState extends State<DateRangeSelectionDialog> {
  late String _selectedRange;
  DateTimeRange? _customDateRange;
  bool _isCustomDateVisible = false;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  
  @override
  void initState() {
    super.initState();
    _selectedRange = widget.selectedRange;
    _customDateRange = widget.customDateRange;
    _isCustomDateVisible = _selectedRange == 'custom';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenSize.width > 500 ? 500 : screenSize.width * 0.9,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('sales_activities_select_period'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    splashRadius: 24,
                  ),
                ],
              ),
            ),
            const Divider(),
            const SizedBox(height: 4),
            // Date range options grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: widget.dateRangeOptions.length,
              itemBuilder: (context, index) {
                final option = widget.dateRangeOptions[index];
                final isSelected = _selectedRange == option['value'];
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedRange = option['value'];
                      _isCustomDateVisible = _selectedRange == 'custom';
                      
                      // If not custom, we can close the dialog and apply right away
                      if (_selectedRange != 'custom') {
                        widget.onRangeSelected(_selectedRange, null);
                        Navigator.of(context).pop();
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.15)
                          : isDarkMode 
                              ? Colors.grey[800]
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option['icon'],
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : isDarkMode 
                                  ? Colors.white 
                                  : Colors.grey[700],
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tr(option['label']),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : isDarkMode 
                                    ? Colors.white 
                                    : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Custom date range picker
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isCustomDateVisible
                  ? _buildCustomDatePicker()
                  : const SizedBox(height: 0),
            ),
            if (_isCustomDateVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        tr('cancel'),
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _customDateRange != null
                          ? () {
                              widget.onRangeSelected(_selectedRange, _customDateRange);
                              Navigator.of(context).pop();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(tr('apply')),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Custom date range picker UI
  Widget _buildCustomDatePicker() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('sales_activities_custom_range'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  tr('sales_activities_start_date'),
                  _customDateRange?.start ?? DateTime.now().subtract(const Duration(days: 7)),
                  () => _selectDate(true),
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateSelector(
                  tr('sales_activities_end_date'),
                  _customDateRange?.end ?? DateTime.now(),
                  () => _selectDate(false),
                  isDarkMode,
                ),
              ),
            ],
          ),
          if (_customDateRange != null) 
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    // +1 because duration.inDays doesn't count the last day
                    '${_customDateRange!.duration.inDays + 1} ${tr('sales_activities_days_selected')}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Date selector button
  Widget _buildDateSelector(String label, DateTime date, VoidCallback onTap, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[700] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateFormat.format(date),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Date picker function
  Future<void> _selectDate(bool isStartDate) async {
    final DateTime initialDate = isStartDate 
        ? _customDateRange?.start ?? DateTime.now().subtract(const Duration(days: 7))
        : _customDateRange?.end ?? DateTime.now();
    
    final DateTime firstDate = isStartDate 
        ? DateTime(2020) 
        : (_customDateRange?.start ?? DateTime(2020));
    
    final DateTime lastDate = isStartDate
        ? (_customDateRange?.end ?? DateTime.now())
        : DateTime.now().add(const Duration(days: 365 * 10)); // Allow future dates
        
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          // When start date changes, make sure it's not after end date
          DateTime endDate = _customDateRange?.end ?? DateTime.now();
          if (picked.isAfter(endDate)) {
            endDate = picked.add(const Duration(days: 1)); // Set end date to next day
          }
          
          _customDateRange = DateTimeRange(
            start: picked,
            end: endDate,
          );
        } else {
          // When end date changes, make sure it's not before start date
          DateTime startDate = _customDateRange?.start ?? DateTime.now().subtract(const Duration(days: 7));
          if (picked.isBefore(startDate)) {
            startDate = picked.subtract(const Duration(days: 1)); // Set start date to previous day
          }
          
          _customDateRange = DateTimeRange(
            start: startDate,
            end: picked,
          );
        }
        
        // Debug to verify the date range is correctly set
        debugPrint('Custom date range: ${_customDateRange!.start} - ${_customDateRange!.end}');
      });
    }
  }
}

// Custom Dialog for Date Range Selection
class CustomDateRangeDialog extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final Function(DateTimeRange) onDateRangeSelected;
  final VoidCallback onCancel;

  const CustomDateRangeDialog({
    Key? key,
    this.initialDateRange,
    required this.onDateRangeSelected,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<CustomDateRangeDialog> createState() => _CustomDateRangeDialogState();
}

class _CustomDateRangeDialogState extends State<CustomDateRangeDialog> {
  late DateTimeRange _selectedDateRange;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // Initialize with provided date range or default to last 7 days
    _selectedDateRange = widget.initialDateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
  }

  // Show date picker to select start date
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateRange.start,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDateRange.start) {
      // Ensure end date is after start date
      final DateTime newEnd = picked.isAfter(_selectedDateRange.end) 
          ? picked 
          : _selectedDateRange.end;
          
      setState(() {
        _selectedDateRange = DateTimeRange(
          start: picked,
          end: newEnd,
        );
      });
    }
  }

  // Show date picker to select end date
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateRange.end,
      // First date can't be before start date
      firstDate: _selectedDateRange.start,
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDateRange.end) {
      setState(() {
        _selectedDateRange = DateTimeRange(
          start: _selectedDateRange.start,
          end: picked,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        tr('sales_activities_select_date_range'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('sales_activities_select_date_description'),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    tr('sales_activities_start_date'),
                    _dateFormat.format(_selectedDateRange.start),
                    _selectStartDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateSelector(
                    tr('sales_activities_end_date'),
                    _dateFormat.format(_selectedDateRange.end),
                    _selectEndDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedDateRange.duration.inDays + 1} ${tr('sales_activities_days_selected')}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onCancel();
            Navigator.of(context).pop();
          },
          child: Text(
            tr('cancel'),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onDateRangeSelected(_selectedDateRange);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(tr('apply')),
        ),
      ],
    );
  }

  // Build a date selector widget
  Widget _buildDateSelector(String label, String date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
