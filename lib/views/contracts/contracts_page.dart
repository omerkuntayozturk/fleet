import 'package:fleet/views/contracts/add_contracts.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../services/contract_service.dart';
import '../../services/firestore_service.dart';
import '../../models/contract.dart';
import 'import_contracts.dart'; // Add this import

class ContractsPage extends StatefulWidget {
  const ContractsPage({super.key});
  @override
  State<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends State<ContractsPage> with SingleTickerProviderStateMixin {
  final svc = ContractService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  List<bool> _isStatsHovering = []; // List for stats cards hovering state
  bool _isLoading = false;
  
  // Add variables for responsive design
  late bool _isSmallScreen;
  late bool _isMediumScreen;
  
  // Pagination variables
  int _currentPage = 1;
  int _pageSize = 5; // Show 5 contracts per page
  int _totalPages = 1;
  int _totalContracts = 0;
  List<Contract> _allContracts = [];
  List<Contract> _displayedContracts = [];
  List<Contract> _filteredContracts = [];
  Map<String, String> _vehiclePlates = {}; // vehicleId -> plate

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    // Initialize hovering states for stats cards
    _isStatsHovering = List.generate(4, (_) => false);
    
    // Add search listener
    _searchController.addListener(() {
      _filterContracts(_searchController.text);
    });
    
    // Load all data (contracts and vehicles)
    _loadAllData();
  }
  
  // Set screen size breakpoints based on device
  void _setScreenSizeBreakpoints(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _isSmallScreen = screenWidth < 650;
    _isMediumScreen = screenWidth >= 650 && screenWidth < 1024;
  }
  
  // Firestore'dan sözleşmeleri çek
  Future<List<Contract>> _fetchContractsFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    try {
      return await _firestoreService.fetchContracts(userId: user.uid);
    } catch (e) {
      print('Firestore sözleşme çekme hatası: $e');
      return [];
    }
  }

  void _loadContractsData() async {
    setState(() {
      _isLoading = true;
    });

    // Firestore'dan verileri çek
    final items = await _fetchContractsFromFirestore();

    setState(() {
      _allContracts = items;
      _totalContracts = items.length;
      _totalPages = (_totalContracts / _pageSize).ceil();
      if (_totalPages == 0) {
        _totalPages = 1; // At least one page even if empty
      }
      _isLoading = false;
    });

    _updateDisplayedContracts();
  }
  
  // Update displayed contracts based on current page
  void _updateDisplayedContracts() {
    setState(() {
      int startIndex = (_currentPage - 1) * _pageSize;
      int endIndex = startIndex + _pageSize;
      
      if (endIndex > _allContracts.length) {
        endIndex = _allContracts.length;
      }
      
      if (startIndex >= _allContracts.length) {
        _displayedContracts = [];
      } else {
        _displayedContracts = _allContracts.sublist(startIndex, endIndex);
      }
      _filteredContracts = _displayedContracts;
    });
  }
  
  // Filter contracts based on search text
  void _filterContracts(String query) {
    setState(() {
      if (query.isEmpty) {
        // Reset to current page view
        _filteredContracts = _displayedContracts;
      } else {
        final lowercaseQuery = query.toLowerCase();
        // When filtering, we search through all contracts, not just current page
        _filteredContracts = _allContracts.where((contract) => 
          contract.reference.toLowerCase().contains(lowercaseQuery) ||
          contract.vehicleId.toLowerCase().contains(lowercaseQuery)
        ).toList();
      }
    });
  }
  
  // Change page and update displayed contracts
  void _changePage(int page) {
    setState(() {
      _currentPage = page;
      // Clear search when changing pages
      _searchController.clear();
    });
    _updateDisplayedContracts();
  }

  // Go to previous page
  void _previousPage() {
    if (_currentPage > 1) {
      _changePage(_currentPage - 1);
    }
  }

  // Go to next page
  void _nextPage() {
    if (_currentPage < _totalPages) {
      _changePage(_currentPage + 1);
    }
  }

  // Method to handle contract import
  void _importContracts(BuildContext context) {
    // Use the ContractImportExport class for importing
    ContractImportExport.importContracts(context, () {
      // This is the refresh callback - reload data after import
      _loadContractsData();
    });
  }

  // Method to handle contract export
  void _exportContracts(BuildContext context) {
    // Use the ContractImportExport class for exporting
    ContractImportExport.exportContracts(context, _allContracts.cast<Map<String, dynamic>>());
  }

  // Tüm verileri yükle (araçlar ve sözleşmeler)
  void _loadAllData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadVehicles();
    _loadContractsData();
    setState(() {
      _isLoading = false;
    });
  }

  // Araçları Firestore'dan çek ve Map'e ata
  Future<void> _loadVehicles() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final vehicles = await _firestoreService.fetchVehiclesWithDetails(userId: user.uid);
      setState(() {
        _vehiclePlates = {
          for (var v in vehicles) v.id: v.plate
        };
      });
    } catch (e) {
      print('Araçlar çekilemedi: $e');
      setState(() {
        _vehiclePlates = {};
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen size for responsive design
    _setScreenSizeBreakpoints(context);
    
    return Scaffold(
      appBar: const TopBar(),
      drawer: const SideMenu(currentPage: 'contracts'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(_isSmallScreen ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section with title and search
                    _buildHeaderSection(context),
                    
                    SizedBox(height: _isSmallScreen ? 24 : 32),
                    
                    // Stats section
                    _buildStatsSection(context, _allContracts),
                    
                    SizedBox(height: _isSmallScreen ? 32 : 40),
                    
                    // Contracts list section
                    _buildContractsSection(context),
                  ],
                ),
              ),
            ),
      // Update FAB to only be visible on small screens
      floatingActionButton: _isSmallScreen ? _buildModernFAB(context) : null,
    );
  }

  // Modern floating action button for mobile view
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
          onTap: _addNewContract,
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
      // Stacked layout for small screens
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and subtitle
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            )),
            child: Text(
              'Sözleşmeler',
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
              'Araç sözleşmelerini görüntüleyin ve yönetin',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Full width search field
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
                hintText: 'Sözleşme ara...',
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
                      'Sözleşmeler',
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
                      'Araç sözleşmelerini görüntüleyin ve yönetin',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Yeni Sözleşme'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _addNewContract,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Search box
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
                      hintText: 'Sözleşme ara...',
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
              // Export button
              OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Dışa Aktar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => _exportContracts(context),
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
                  'Sözleşmeler',
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
                  'Araç sözleşmelerini görüntüleyin ve yönetin',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Export contracts button
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Dışa Aktar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => _exportContracts(context),
              ),
              const SizedBox(width: 16),
              // Add new contract button
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Yeni Sözleşme'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _addNewContract,
              ),
              const SizedBox(width: 16),
              // Search box
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
                      hintText: 'Sözleşme ara...',
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

  Widget _buildStatsSection(BuildContext context, List<Contract> items) {
    // Calculate contract statistics
    final totalContracts = items.length;
    final activeContracts = items.where((c) => 
      c.endDate.isAfter(DateTime.now())
    ).length;
    final expiredContracts = totalContracts - activeContracts;
    final expiringContracts = items.where((c) => 
      c.endDate.isAfter(DateTime.now()) && 
      c.endDate.isBefore(DateTime.now().add(const Duration(days: 30)))
    ).length;
    
    // Prepare cards data
    final List<Map<String, dynamic>> cards = [
      {
        'icon': Icons.article,
        'title': 'Toplam Sözleşme',
        'value': '$totalContracts',
        'color': Colors.purple,
        'trend': '+3%',
        'isUp': true,
      },
      {
        'icon': Icons.access_time,
        'title': 'Yakında Bitecek',
        'value': '$expiringContracts',
        'color': Colors.orange,
        'trend': expiringContracts > 0 ? '+${expiringContracts}' : '0',
        'isUp': expiringContracts > 0,
      },
      {
        'icon': Icons.check_circle,
        'title': 'Aktif Sözleşmeler',
        'value': '$activeContracts',
        'color': Colors.blue,
        'trend': activeContracts > 0 ? '+${activeContracts}' : '0',
        'isUp': activeContracts > 0,
      },
      {
        'icon': Icons.history,
        'title': 'Sona Eren',
        'value': '$expiredContracts',
        'color': Colors.green,
        'trend': expiredContracts > 0 ? '+${expiredContracts}' : '0',
        'isUp': expiredContracts > 0,
      },
    ];

    // For smaller screens, stack the stat cards vertically or in a 2x2 grid
    if (_isSmallScreen) {
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
              'Sözleşme İstatistikleri',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // First row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    cards[0]['icon'],
                    cards[0]['title'],
                    cards[0]['value'],
                    cards[0]['color'],
                    cards[0]['trend'],
                    cards[0]['isUp'],
                    0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    cards[1]['icon'],
                    cards[1]['title'],
                    cards[1]['value'],
                    cards[1]['color'],
                    cards[1]['trend'],
                    cards[1]['isUp'],
                    1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Second row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    cards[2]['icon'],
                    cards[2]['title'],
                    cards[2]['value'],
                    cards[2]['color'],
                    cards[2]['trend'],
                    cards[2]['isUp'],
                    2,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    cards[3]['icon'],
                    cards[3]['title'],
                    cards[3]['value'],
                    cards[3]['color'],
                    cards[3]['trend'],
                    cards[3]['isUp'],
                    3,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_isMediumScreen) {
      // For medium screens, use a 2x2 grid
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
              'Sözleşme İstatistikleri',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // First row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    cards[0]['icon'],
                    cards[0]['title'],
                    cards[0]['value'],
                    cards[0]['color'],
                    cards[0]['trend'],
                    cards[0]['isUp'],
                    0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    cards[1]['icon'],
                    cards[1]['title'],
                    cards[1]['value'],
                    cards[1]['color'],
                    cards[1]['trend'],
                    cards[1]['isUp'],
                    1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Second row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    cards[2]['icon'],
                    cards[2]['title'],
                    cards[2]['value'],
                    cards[2]['color'],
                    cards[2]['trend'],
                    cards[2]['isUp'],
                    2,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    cards[3]['icon'],
                    cards[3]['title'],
                    cards[3]['value'],
                    cards[3]['color'],
                    cards[3]['trend'],
                    cards[3]['isUp'],
                    3,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Original row layout for large screens
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
              'Sözleşme İstatistikleri',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    cards[0]['icon'],
                    cards[0]['title'],
                    cards[0]['value'],
                    cards[0]['color'],
                    cards[0]['trend'],
                    cards[0]['isUp'],
                    0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    cards[1]['icon'],
                    cards[1]['title'],
                    cards[1]['value'],
                    cards[1]['color'],
                    cards[1]['trend'],
                    cards[1]['isUp'],
                    1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    cards[2]['icon'],
                    cards[2]['title'],
                    cards[2]['value'],
                    cards[2]['color'],
                    cards[2]['trend'],
                    cards[2]['isUp'],
                    2,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    cards[3]['icon'],
                    cards[3]['title'],
                    cards[3]['value'],
                    cards[3]['color'],
                    cards[3]['trend'],
                    cards[3]['isUp'],
                    3,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
  
  // New responsive stat card builder
  Widget _buildStatCard(
    BuildContext context, 
    IconData icon, 
    String title, 
    String value, 
    Color color,
    String trend,
    bool isUp,
    int index,
  ) {
    // More compact stat card for small screens
    if (_isSmallScreen) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      isUp ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isUp ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: TextStyle(
                        color: isUp ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
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
      // Hover effects for larger screens
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
                color: color.withOpacity(_isStatsHovering[index] ? 0.3 : 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: _isStatsHovering[index] ? color : Colors.grey[200]!,
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
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isUp ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: TextStyle(
                          color: isUp ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
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

  Widget _buildContractsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Remove the row with filter and refresh buttons
        Text(
          'Sözleşme Listesi',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        
        // Rest of the contracts section
        _filteredContracts.isEmpty
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
                            // Referans sütunu kaldırıldı
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Çalışan Adı',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Araç Plaka',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Başlangıç Tarihi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Bitiş Tarihi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Durum',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: _isSmallScreen ? 50 : 100,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Contract list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredContracts.length,
                        itemBuilder: (context, index) {
                          final contract = _filteredContracts[index];
                          final now = DateTime.now();
                          
                          // Determine contract status
                          String status;
                          Color statusColor;
                          
                          if (contract.endDate.isBefore(now)) {
                            status = 'Sona Erdi';
                            statusColor = Colors.red;
                          } else if (contract.endDate.difference(now).inDays <= 30) {
                            status = 'Yakında Bitecek';
                            statusColor = Colors.orange;
                          } else {
                            status = 'Aktif';
                            statusColor = Colors.green;
                          }
                          
                          // Araç plakasını bul
                          String plate = '';
                          if (contract.vehicleId.isNotEmpty) {
                            plate = _vehiclePlates[contract.vehicleId] ?? '(Plaka yok)';
                          } else {
                            plate = '(Araç yok)';
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _editContract(contract),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Row(
                                  children: [
                                    // Referans sütunu kaldırıldı
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        contract.employeeName.isEmpty ? '(Çalışan yok)' : contract.employeeName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        plate,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(_formatDate(contract.startDate)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(_formatDate(contract.endDate)),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: _isSmallScreen ? 50 : 100,
                                      child: _isSmallScreen 
                                          ? PopupMenuButton(
                                              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Düzenle'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Sil'),
                                                ),
                                                // const PopupMenuItem(
                                                //   value: 'renew',
                                                //   child: Text('Yenile'),
                                                // ),
                                              ],
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _editContract(contract);
                                                } else if (value == 'delete') {
                                                  _deleteContract(contract);
                                                }
                                                // else if (value == 'renew') {
                                                //   _renewContract(contract);
                                                // }
                                              },
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                // Edit button
                                                IconButton(
                                                  icon: Icon(Icons.edit_outlined, color: Colors.blue[600], size: 20),
                                                  tooltip: 'Düzenle',
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                  onPressed: () => _editContract(contract),
                                                ),
                                                // Delete button
                                                IconButton(
                                                  icon: Icon(Icons.delete_outline, color: Colors.red[600], size: 20),
                                                  tooltip: 'Sil',
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                  onPressed: () => _deleteContract(contract),
                                                ),
                                                // Yenile butonu kaldırıldı
                                                // IconButton(
                                                //   icon: Icon(Icons.autorenew, color: Colors.green[600], size: 20),
                                                //   tooltip: 'Yenile',
                                                //   constraints: const BoxConstraints(),
                                                //   padding: const EdgeInsets.all(8),
                                                //   onPressed: () => _renewContract(contract),
                                                // ),
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
                      
                      // Add pagination controls
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
  
  // Simplified pagination for small screens
  Widget _buildSimplifiedPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous page button
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? _previousPage : null,
            tooltip: 'Önceki Sayfa',
            splashRadius: 20,
            color: _currentPage > 1 ? Colors.blue : Colors.grey,
          ),
          
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_currentPage / $_totalPages',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Next page button
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages ? _nextPage : null,
            tooltip: 'Sonraki Sayfa',
            splashRadius: 20,
            color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
          ),
        ],
      ),
    );
  }
  
  // Medium screen pagination controls
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
          // Records info
          Text(
            'Toplam $_totalContracts sözleşme',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Pagination
          Row(
            children: [
              // Previous page button
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? _previousPage : null,
                tooltip: 'Önceki Sayfa',
                splashRadius: 20,
                color: _currentPage > 1 ? Colors.blue : Colors.grey,
              ),
              
              // Page selector dropdown
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
              
              Text(' / $_totalPages',
                  style: const TextStyle(color: Colors.grey)),
              
              // Next page button
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages ? _nextPage : null,
                tooltip: 'Sonraki Sayfa',
                splashRadius: 20,
                color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Full pagination controls for large screens
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
          // Records info
          Text(
            'Toplam $_totalContracts sözleşme',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Pagination
          Row(
            children: [
              // First page button
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage > 1 ? () => _changePage(1) : null,
                tooltip: 'İlk Sayfa',
                splashRadius: 20,
                color: _currentPage > 1 ? Colors.blue : Colors.grey,
              ),
              
              // Previous page button
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? _previousPage : null,
                tooltip: 'Önceki Sayfa',
                splashRadius: 20,
                color: _currentPage > 1 ? Colors.blue : Colors.grey,
              ),
              
              // Page selector dropdown
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
              
              Text(' / $_totalPages',
                  style: const TextStyle(color: Colors.grey)),
              
              // Next page button
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages ? _nextPage : null,
                tooltip: 'Sonraki Sayfa',
                splashRadius: 20,
                color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
              ),
              
              // Last page button
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < _totalPages ? () => _changePage(_totalPages) : null,
                tooltip: 'Son Sayfa',
                splashRadius: 20,
                color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
              ),
              
              // Page size selector
              const SizedBox(width: 16),
              Text('Sayfa Başına:', style: TextStyle(color: Colors.grey[700])),
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
                        _totalPages = (_totalContracts / _pageSize).ceil();
                        if (_totalPages == 0) {
                          _totalPages = 1;
                        }
                        _currentPage = 1; // Reset to first page
                      });
                      _updateDisplayedContracts();
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
              Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Henüz sözleşme eklenmemiş',
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Text(
                'Yeni bir sözleşme eklemek için sağ alttaki + butonuna tıklayın',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Yeni Sözleşme Ekle'),
                onPressed: _addNewContract,
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

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sözleşmeleri Filtrele'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Durum',
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tümü')),
                  DropdownMenuItem(value: 'active', child: Text('Aktif')),
                  DropdownMenuItem(value: 'expiring', child: Text('Yakında Bitecek')),
                  DropdownMenuItem(value: 'expired', child: Text('Sona Eren')),
                ],
                onChanged: (value) {
                  // Handle filter selection
                },
                value: 'all',
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Araç ID',
                  hintText: 'Araç ID\'sine göre filtrele',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Apply filters
              Navigator.pop(context);
            },
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }

  void _editContract(Contract contract) {
    // Format dates in DD.MM.YYYY format for the form
    String formattedStartDate = '${contract.startDate.day.toString().padLeft(2, '0')}.${contract.startDate.month.toString().padLeft(2, '0')}.${contract.startDate.year}';
    String formattedEndDate = '${contract.endDate.day.toString().padLeft(2, '0')}.${contract.endDate.month.toString().padLeft(2, '0')}.${contract.endDate.year}';
    
    // ContractManagement.editContract fonksiyonunu çağır
    ContractManagement.editContract(
      context,
      {
        'id': contract.id,
        'employeeId': contract.employeeId,
        'employeeName': contract.employeeName,
        'vehicleId': contract.vehicleId,
        'vehiclePlate': contract.vehiclePlate,
        // In the Contract model, 'reference' contains the contract type
        // Make sure we pass this value as both 'type' and 'reference'
        'type': contract.reference,
        'reference': contract.reference,
        'startDate': formattedStartDate,
        'endDate': formattedEndDate,
        'createdAt': contract.createdAt,
        'status': contract.status.toString(),
      },
      _loadContractsData,
    );
  }

  void _deleteContract(Contract contract) async {
    final user = _auth.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sözleşmeyi Sil'),
        content: Text('${contract.employeeName.isEmpty ? "Bu sözleşmeyi" : contract.employeeName} silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await _firestoreService.deleteContract(contract.id, user.uid);
                _loadContractsData(); // Reload data after deletion
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sözleşme silindi'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hata: Sözleşme silinemedi - ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white, // <-- Text color white
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _renewContract(Contract contract) {
    final newEndDate = contract.endDate.add(const Duration(days: 365));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sözleşmeyi Yenile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mevcut bitiş tarihi: ${_formatDate(contract.endDate)}'),
            const SizedBox(height: 16),
            Text('Yeni bitiş tarihi: ${_formatDate(newEndDate)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                // Renew contract logic
                final updatedContract = Contract(
                  id: contract.id,
                  employeeId: contract.employeeId, // eklendi
                  employeeName: contract.employeeName, // eklendi
                  vehicleId: contract.vehicleId,
                  reference: contract.reference,
                  startDate: contract.startDate,
                  endDate: newEndDate,
                );
                svc.update(updatedContract);
                _loadContractsData(); // Reload data after renewal
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sözleşme yenilendi'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hata: Sözleşme yenilenemedi - ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Yenile'),
          ),
        ],
      ),
    );
  }

  void _addNewContract() {
    // Use the ContractManagement class to handle adding a new contract
    ContractManagement.addNewContract(context, () {
      // Refresh callback - reload data after adding a new contract
      _loadContractsData();
    });
  }
}