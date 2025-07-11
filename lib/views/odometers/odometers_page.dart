import 'package:flutter/material.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../services/odometer_service.dart';
import '../../models/odometer_record.dart';
import 'add_odometers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart'; // Add FirestoreService import
import 'import_odometers.dart'; // <-- Add this import
import '../../info_card.dart'; // InfoCard importu eklendi
import 'package:easy_localization/easy_localization.dart'; // Add Easy Localization import

class OdometersPage extends StatefulWidget {
  const OdometersPage({super.key});
  @override
  State<OdometersPage> createState() => _OdometersPageState();
}

class _OdometersPageState extends State<OdometersPage> with SingleTickerProviderStateMixin {
  final svc = OdometerService();
  final FirestoreService _firestoreService = FirestoreService(); // Add FirestoreService
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  List<bool> _isStatsHovering = [];
  bool _isLoading = false;

  // Responsive
  late bool _isSmallScreen;
  late bool _isMediumScreen;

  // Pagination
  int _currentPage = 1;
  int _pageSize = 5;
  int _totalPages = 1;
  int _totalRecords = 0;
  List<OdometerRecord> _allRecords = [];
  List<OdometerRecord> _displayedRecords = [];
  List<OdometerRecord> _filteredRecords = [];
  
  // Add map to store vehicle plate information
  Map<String, String> _vehiclePlates = {};

  // Firebase reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _isStatsHovering = List.generate(4, (_) => false);

    _searchController.addListener(() {
      _filterRecords(_searchController.text);
    });

    _loadOdometerData();
  }

  void _setScreenSizeBreakpoints(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _isSmallScreen = screenWidth < 650;
    _isMediumScreen = screenWidth >= 650 && screenWidth < 1024;
  }
  
  // Add method to load vehicle plates
  Future<void> _loadVehiclePlates() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    try {
      final vehicles = await _firestoreService.fetchVehiclesWithDetails(userId: currentUser.uid);
      
      final Map<String, String> plates = {};
      for (var vehicle in vehicles) {
        plates[vehicle.id] = vehicle.plate;
      }
      
      if (mounted) {
        setState(() {
          _vehiclePlates = plates;
        });
      }
    } catch (e) {
      print('Error loading vehicle plates: $e');
    }
  }

  void _loadOdometerData() {
    setState(() {
      _isLoading = true;
    });

    // Get current user
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _allRecords = [];
        _totalRecords = 0;
        _totalPages = 1;
      });
      _updateDisplayedRecords();
      return;
    }
    
    // Load vehicle plates first, then load odometers
    _loadVehiclePlates().then((_) {
      // Fetch data from Firestore
      _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('odometers')
          .orderBy('date', descending: true)
          .get()
          .then((querySnapshot) {
            final List<OdometerRecord> fetchedRecords = [];
            
            for (var doc in querySnapshot.docs) {
              final data = doc.data();
              
              // Convert Firestore timestamp to DateTime
              DateTime recordDate;
              if (data['date'] is Timestamp) {
                recordDate = (data['date'] as Timestamp).toDate();
              } else if (data['date'] is DateTime) {
                recordDate = data['date'];
              } else {
                recordDate = DateTime.now(); // Fallback
              }
              
              fetchedRecords.add(OdometerRecord(
                id: data['id'] ?? doc.id,
                vehicleId: data['vehicleId'] ?? '',
                driver: data['driver'] ?? '',
                date: recordDate,
                value: (data['value'] is int) 
                    ? (data['value'] as int).toDouble()
                    : (data['value'] as double?) ?? 0.0,
              ));
            }
            
            setState(() {
              _allRecords = fetchedRecords;
              _totalRecords = fetchedRecords.length;
              _totalPages = (_totalRecords / _pageSize).ceil();
              if (_totalPages == 0) _totalPages = 1;
              _isLoading = false;
            });
            
            _updateDisplayedRecords();
          })
          .catchError((error) {
            print('Error loading odometer data: $error');
            setState(() {
              _isLoading = false;
              _allRecords = [];
              _totalRecords = 0;
              _totalPages = 1;
            });
            _updateDisplayedRecords();
          });
    });
  }

  void _updateDisplayedRecords() {
    setState(() {
      int startIndex = (_currentPage - 1) * _pageSize;
      int endIndex = startIndex + _pageSize;
      if (endIndex > _allRecords.length) endIndex = _allRecords.length;
      if (startIndex >= _allRecords.length) {
        _displayedRecords = [];
      } else {
        _displayedRecords = _allRecords.sublist(startIndex, endIndex);
      }
      _filteredRecords = _displayedRecords;
    });
  }

  void _filterRecords(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = _displayedRecords;
      } else {
        final lowercaseQuery = query.toLowerCase();
        _filteredRecords = _allRecords.where((record) =>
          record.vehicleId.toLowerCase().contains(lowercaseQuery) ||
          record.value.toString().contains(lowercaseQuery)
        ).toList();
      }
    });
  }

  void _changePage(int page) {
    setState(() {
      _currentPage = page;
      _searchController.clear();
    });
    _updateDisplayedRecords();
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _changePage(_currentPage - 1);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _changePage(_currentPage + 1);
    }
  }

  // Dummy import/export methods
  void _importOdometers(BuildContext context) {
    // TODO: Implement import logic
    InfoCard.showInfoCard(
      context,
      tr('odometer_import_not_available'),
      Colors.blue,
      icon: Icons.info_outline,
    );
  }

  void _exportOdometers(BuildContext context) {
    // Export odometer records to Excel using import_odometers.dart logic
    exportOdometersToExcel(
      context,
      vehiclePlates: _vehiclePlates,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setScreenSizeBreakpoints(context);
    return Scaffold(
      appBar: const TopBar(),
      drawer: const SideMenu(currentPage: 'odometer'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(_isSmallScreen ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(context),
                    SizedBox(height: _isSmallScreen ? 24 : 32),
                    _buildStatsSection(context, _allRecords),
                    SizedBox(height: _isSmallScreen ? 32 : 40),
                    _buildOdometersSection(context),
                  ],
                ),
              ),
            ),
      floatingActionButton: _isSmallScreen ? _buildModernFAB(context) : null,
    );
  }

  Widget _buildModernFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _addNewOdometerRecord,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    if (_isSmallScreen) {
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
              tr('odometer_page_title'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
              tr('odometer_page_subtitle'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr('odometer_search_hint'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ],
      );
    } else if (_isMediumScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      tr('odometer_page_title'),
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
                      tr('odometer_page_subtitle'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(tr('odometer_button_new_record')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _addNewOdometerRecord,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: tr('odometer_search_hint'),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: Text(tr('odometer_button_export')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => _exportOdometers(context),
              ),
            ],
          ),
        ],
      );
    } else {
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
                  tr('odometer_page_title'),
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
                  tr('odometer_page_subtitle'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: Text(tr('odometer_button_export')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => _exportOdometers(context),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(tr('odometer_button_new_record')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _addNewOdometerRecord,
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 300,
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: tr('odometer_search_hint'),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStatsSection(BuildContext context, List<OdometerRecord> items) {
    int totalRecords = items.length;
    double averageKm = 0;
    int maxKm = 0;
    DateTime? lastUpdate;
    if (items.isNotEmpty) {
      int totalKm = 0;
      for (var record in items) {
        totalKm += record.value as int;
        if (record.value > maxKm) maxKm = record.value as int;
        if (lastUpdate == null || record.date.isAfter(lastUpdate)) lastUpdate = record.date;
      }
      averageKm = totalKm / totalRecords;
    }
    final List<Map<String, dynamic>> cards = [
      {
        'icon': Icons.speed,
        'title': tr('odometer_stats_total_records'),
        'value': '$totalRecords',
        'color': Colors.indigo,
        'trend': '+2%',
        'isUp': true,
      },
      {
        'icon': Icons.timeline,
        'title': tr('odometer_stats_average_km'),
        'value': '${averageKm.toStringAsFixed(0)} ${tr('odometer_unit_km')}',
        'color': Colors.orange,
        'trend': '+3%',
        'isUp': true,
      },
      {
        'icon': Icons.trending_up,
        'title': tr('odometer_stats_max_km'),
        'value': '$maxKm ${tr('odometer_unit_km')}',
        'color': Colors.blue,
        'trend': '+5%',
        'isUp': true,
      },
      {
        'icon': Icons.calendar_today,
        'title': tr('odometer_stats_last_update'),
        'value': lastUpdate != null ? _formatDate(lastUpdate) : '-',
        'color': Colors.green,
        'trend': tr('odometer_stats_today'),
        'isUp': true,
      },
    ];

    if (_isSmallScreen || _isMediumScreen) {
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('odometer_stats_title'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard(context, cards[0], 0)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(context, cards[1], 1)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard(context, cards[2], 2)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(context, cards[3], 3)),
              ],
            ),
          ],
        ),
      );
    } else {
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('odometer_stats_title'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(4, (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 16 : 0),
                  child: _buildStatCard(context, cards[i], i),
                ),
              )),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatCard(BuildContext context, Map<String, dynamic> card, int index) {
    if (_isSmallScreen) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: card['color'].withOpacity(0.1),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: card['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(card['icon'], color: card['color'], size: 18),
                ),
                Row(
                  children: [
                    Icon(card['isUp'] ? Icons.arrow_upward : Icons.arrow_downward,
                        color: card['isUp'] ? Colors.green : Colors.red, size: 12),
                    const SizedBox(width: 4),
                    Text(card['trend'],
                        style: TextStyle(
                          color: card['isUp'] ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        )),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              card['title'],
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              card['value'],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else {
      return MouseRegion(
        onEnter: (_) => setState(() => _isStatsHovering[index] = true),
        onExit: (_) => setState(() => _isStatsHovering[index] = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _isStatsHovering[index]
              ? (Matrix4.identity()..translate(0, -5, 0))
              : Matrix4.identity(),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: card['color'].withOpacity(_isStatsHovering[index] ? 0.3 : 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: _isStatsHovering[index] ? card['color'] : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: card['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(card['icon'], color: card['color'], size: 24),
                  ),
                  Row(
                    children: [
                      Icon(card['isUp'] ? Icons.arrow_upward : Icons.arrow_downward,
                          color: card['isUp'] ? Colors.green : Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(card['trend'],
                          style: TextStyle(
                            color: card['isUp'] ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                card['title'],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                card['value'],
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildOdometersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('odometer_list_title'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _filteredRecords.isEmpty
            ? _buildEmptyState()
            : Container(
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
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                tr('odometer_column_vehicle'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                tr('odometer_column_date'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                tr('odometer_column_value'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: _isSmallScreen ? 50 : 100,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = _filteredRecords[index];
                          // Get vehicle plate from map, or show placeholder if not found
                          final vehiclePlate = record.vehicleId.isEmpty 
                              ? tr('odometer_no_vehicle') 
                              : _vehiclePlates[record.vehicleId] ?? record.vehicleId;
                              
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _editOdometerRecord(record),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        vehiclePlate,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(_formatDate(record.date)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('${record.value} ${tr('odometer_unit_km')}'),
                                    ),
                                    SizedBox(
                                      width: _isSmallScreen ? 50 : 100,
                                      child: _isSmallScreen
                                          ? PopupMenuButton(
                                              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text(tr('odometer_action_edit')),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text(tr('odometer_action_delete')),
                                                ),
                                              ],
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _editOdometerRecord(record);
                                                } else if (value == 'delete') {
                                                  _deleteOdometerRecord(record);
                                                }
                                              },
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.edit_outlined, color: Colors.blue[600], size: 20),
                                                  tooltip: tr('odometer_action_edit'),
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                  onPressed: () => _editOdometerRecord(record),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete_outline, color: Colors.red[600], size: 20),
                                                  tooltip: tr('odometer_action_delete'),
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                  onPressed: () => _deleteOdometerRecord(record),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_searchController.text.isEmpty && _totalPages > 1)
                        _isSmallScreen
                            ? _buildSimplifiedPagination()
                            : _isMediumScreen
                                ? _buildMediumPaginationControls()
                                : _buildPaginationControls(),
                    ],
                  ),
                ),
              ),
      ],
    );
  }
  
  Widget _buildSimplifiedPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? _previousPage : null,
            tooltip: tr('odometer_pagination_previous'),
            splashRadius: 20,
            color: _currentPage > 1 ? Colors.blue : Colors.grey,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tr('odometer_pagination_page_of_total', namedArgs: {
                'current': _currentPage.toString(),
                'total': _totalPages.toString()
              }),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages ? _nextPage : null,
            tooltip: tr('odometer_pagination_next'),
            splashRadius: 20,
            color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildMediumPaginationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tr('odometer_pagination_total_records', namedArgs: {'count': _totalRecords.toString()}),
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? _previousPage : null,
                tooltip: tr('odometer_pagination_previous'),
                splashRadius: 20,
                color: _currentPage > 1 ? Colors.blue : Colors.grey,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton<int>(
                  value: _currentPage,
                  underline: const SizedBox(),
                  items: List.generate(_totalPages, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text('${index + 1}'),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      _changePage(value);
                    }
                  },
                ),
              ),
              Text(
                tr('odometer_pagination_of_total', namedArgs: {'total': _totalPages.toString()}),
                style: const TextStyle(color: Colors.grey)
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages ? _nextPage : null,
                tooltip: tr('odometer_pagination_next'),
                splashRadius: 20,
                color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tr('odometer_pagination_total_records', namedArgs: {'count': _totalRecords.toString()}),
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage > 1 ? () => _changePage(1) : null,
                tooltip: tr('odometer_pagination_first'),
                splashRadius: 20,
                color: _currentPage > 1 ? Colors.blue : Colors.grey,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? _previousPage : null,
                tooltip: tr('odometer_pagination_previous'),
                splashRadius: 20,
                color: _currentPage > 1 ? Colors.blue : Colors.grey,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton<int>(
                  value: _currentPage,
                  underline: const SizedBox(),
                  items: List.generate(_totalPages, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text('${index + 1}'),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      _changePage(value);
                    }
                  },
                ),
              ),
              Text(
                tr('odometer_pagination_of_total', namedArgs: {'total': _totalPages.toString()}),
                style: const TextStyle(color: Colors.grey)
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages ? _nextPage : null,
                tooltip: tr('odometer_pagination_next'),
                splashRadius: 20,
                color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < _totalPages ? () => _changePage(_totalPages) : null,
                tooltip: tr('odometer_pagination_last'),
                splashRadius: 20,
                color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 16),
              Text(
                tr('odometer_pagination_per_page'),
                style: TextStyle(color: Colors.grey[700])
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton<int>(
                  value: _pageSize,
                  underline: const SizedBox(),
                  items: [5, 10, 15, 20].map((size) {
                    return DropdownMenuItem<int>(
                      value: size,
                      child: Text('$size'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _pageSize = value;
                        _totalPages = (_totalRecords / _pageSize).ceil();
                        if (_totalPages == 0) _totalPages = 1;
                        _currentPage = 1;
                      });
                      _updateDisplayedRecords();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          padding: const EdgeInsets.all(32),
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
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.speed_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                tr('odometer_empty_state_title'),
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Text(
                tr('odometer_empty_state_message'),
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(tr('odometer_button_add_new')),
                onPressed: _addNewOdometerRecord,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _editOdometerRecord(OdometerRecord record) {
    OdometerManagement.addNewOdometer(
      context, 
      () {
        _loadOdometerData();
      },
      editRecord: record,
      allOdometerRecords: _allRecords, // <-- ekle
      // Düzenlemede de aynı plakalı başka kayıt varsa (ve bu kayıt değilse) silinsin
      onBeforeAdd: (OdometerRecord newRecord) async {
        final User? currentUser = _auth.currentUser;
        if (currentUser == null) return;
        final sameVehicleRecords = _allRecords.where((r) => r.vehicleId == newRecord.vehicleId && r.id != record.id).toList();
        for (final old in sameVehicleRecords) {
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('odometers')
              .doc(old.id)
              .delete()
              .catchError((_) {});
          svc.remove(old.id);
        }
      },
    );
  }

  void _deleteOdometerRecord(OdometerRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('odometer_delete_dialog_title')),
        content: Text(tr('odometer_delete_dialog_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('odometer_button_cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete from Firestore
              final User? currentUser = _auth.currentUser;
              if (currentUser != null) {
                _firestore
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('odometers')
                    .doc(record.id)
                    .delete()
                    .then((_) {
                      // Also delete from local service for backward compatibility
                      svc.remove(record.id);
                      _loadOdometerData();
                      Navigator.pop(context);
                      InfoCard.showInfoCard(
                        context,
                        tr('odometer_delete_success'),
                        Colors.red,
                        icon: Icons.delete_outline,
                      );
                    })
                    .catchError((error) {
                      Navigator.pop(context);
                      InfoCard.showInfoCard(
                        context,
                        tr('odometer_error_message', namedArgs: {'error': error.toString()}),
                        Colors.red,
                        icon: Icons.error_outline,
                      );
                    });
              } else {
                // Fallback to local service if no user is authenticated
                svc.remove(record.id);
                _loadOdometerData();
                Navigator.pop(context);
                InfoCard.showInfoCard(
                  context,
                  tr('odometer_delete_success'),
                  Colors.red,
                  icon: Icons.delete_outline,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white, // Added foregroundColor to make text white
            ),
            child: Text(tr('odometer_button_delete')),
          ),
        ],
      ),
    );
  }

  void _addNewOdometerRecord() {
    OdometerManagement.addNewOdometer(
      context, 
      () {
        _loadOdometerData();
      },
      allOdometerRecords: _allRecords,
      // Yeni: Aynı plakalı kayıt varsa silinsin
      onBeforeAdd: (OdometerRecord newRecord) async {
        final User? currentUser = _auth.currentUser;
        if (currentUser == null) return;
        // Aynı plakalı eski kayıtları bul
        final sameVehicleRecords = _allRecords.where((r) => r.vehicleId == newRecord.vehicleId).toList();
        for (final old in sameVehicleRecords) {
          // Firestore'dan sil
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('odometers')
              .doc(old.id)
              .delete()
              .catchError((_) {});
          // Local servisten sil
          svc.remove(old.id);
        }
      },
    );
  }
}