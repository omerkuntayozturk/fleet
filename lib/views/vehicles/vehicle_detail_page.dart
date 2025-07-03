import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../models/vehicle.dart';
import 'add_vehicle.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});
  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> with SingleTickerProviderStateMixin {
  // Vehicle data lists
  List<Vehicle> _allVehicles = [];
  List<Vehicle> _displayedVehicles = [];
  List<Vehicle> _filteredVehicles = [];
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _isStatsHovering = List.generate(4, (_) => false);

    _searchController.addListener(() {
      _filterVehicles(_searchController.text);
    });

    _loadVehicleData();
  }

  void _setScreenSizeBreakpoints(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _isSmallScreen = screenWidth < 650;
    _isMediumScreen = screenWidth >= 650 && screenWidth < 1024;
  }

  void _loadVehicleData() {
    setState(() {
      _isLoading = true;
    });

    // Get current user
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _allVehicles = [];
        _totalRecords = 0;
        _totalPages = 1;
      });
      _updateDisplayedVehicles();
      return;
    }

    // Fetch data from Firestore
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('vehicles')
        .get()
        .then((querySnapshot) {
          if (!mounted) return; // Check if still mounted
          
          final List<Vehicle> fetchedVehicles = [];
          
          for (var doc in querySnapshot.docs) {
            final data = doc.data();
            
            fetchedVehicles.add(Vehicle(
              id: doc.id,
              model: data['model'] ?? '',
              plate: data['plate'] ?? '',
              year: data['year'] != null ? int.tryParse(data['year'].toString()) : null,
            ));
          }
          
          setState(() {
            _allVehicles = fetchedVehicles;
            _totalRecords = fetchedVehicles.length;
            _totalPages = (_totalRecords / _pageSize).ceil();
            if (_totalPages == 0) _totalPages = 1;
            _isLoading = false;
          });
          
          _updateDisplayedVehicles();
        })
        .catchError((error) {
          if (!mounted) return; // Check if still mounted
          
          print('Error loading vehicle data: $error');
          setState(() {
            _isLoading = false;
            _allVehicles = [];
            _totalRecords = 0;
            _totalPages = 1;
          });
          _updateDisplayedVehicles();
        });
  }

  void _updateDisplayedVehicles() {
    setState(() {
      int startIndex = (_currentPage - 1) * _pageSize;
      int endIndex = startIndex + _pageSize;
      if (endIndex > _allVehicles.length) endIndex = _allVehicles.length;
      if (startIndex >= _allVehicles.length) {
        _displayedVehicles = [];
      } else {
        _displayedVehicles = _allVehicles.sublist(startIndex, endIndex);
      }
      _filteredVehicles = _displayedVehicles;
    });
  }

  void _filterVehicles(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVehicles = _displayedVehicles;
      } else {
        final lowercaseQuery = query.toLowerCase();
        _filteredVehicles = _allVehicles.where((vehicle) =>
          vehicle.model.toLowerCase().contains(lowercaseQuery) ||
          vehicle.plate.toLowerCase().contains(lowercaseQuery) ||
          (vehicle.year?.toString().contains(lowercaseQuery) ?? false)
        ).toList();
      }
    });
  }

  void _changePage(int page) {
    setState(() {
      _currentPage = page;
      _searchController.clear();
    });
    _updateDisplayedVehicles();
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

  // Add export method
  void _exportVehicles(BuildContext context) {
    // TODO: Implement export logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dışa Aktar özelliği henüz eklenmedi.'), backgroundColor: Colors.blue),
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
      drawer: const SideMenu(currentPage: 'vehicles'),
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
                    _buildStatsSection(context, _allVehicles),
                    SizedBox(height: _isSmallScreen ? 32 : 40),
                    _buildVehiclesSection(context),
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
          onTap: _addNewVehicle,
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
              'Araçlar',
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
              'Filo araçlarınızı yönetin',
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
                hintText: 'Araç ara...',
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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Dışa Aktar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () => _exportVehicles(context),
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
                      'Araçlar',
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
                      'Filo araçlarınızı yönetin',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Dışa Aktar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => _exportVehicles(context),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Araç'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _addNewVehicle,
                  ),
                ],
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
                      hintText: 'Araç ara...',
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
                  'Araçlar',
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
                  'Filo araçlarınızı yönetin',
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
                label: const Text('Dışa Aktar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => _exportVehicles(context),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Yeni Araç'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _addNewVehicle,
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
                      hintText: 'Araç ara...',
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

  Widget _buildStatsSection(BuildContext context, List<Vehicle> items) {
    int totalVehicles = items.length;
    int oldestYear = 0;
    int newestYear = 0;
    String mostCommonModel = '-';
    
    if (items.isNotEmpty) {
      oldestYear = items.map((v) => v.year ?? 0).reduce((a, b) => a < b ? a : b);
      newestYear = items.map((v) => v.year ?? 0).reduce((a, b) => a > b ? a : b);
      final modelCounts = <String, int>{};
      for (var v in items) {
        modelCounts[v.model] = (modelCounts[v.model] ?? 0) + 1;
      }
      mostCommonModel = modelCounts.entries.isNotEmpty 
          ? modelCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : '-';
    }
    
    final List<Map<String, dynamic>> cards = [
      {
        'icon': Icons.directions_car,
        'title': 'Toplam Araç',
        'value': '$totalVehicles',
        'color': Colors.indigo,
        'trend': '',
        'isUp': true,
      },
      {
        'icon': Icons.calendar_today,
        'title': 'En Eski Yıl',
        'value': oldestYear > 0 ? '$oldestYear' : '-',
        'color': Colors.orange,
        'trend': '',
        'isUp': true,
      },
      {
        'icon': Icons.new_releases,
        'title': 'En Yeni Yıl',
        'value': newestYear > 0 ? '$newestYear' : '-',
        'color': Colors.blue,
        'trend': '',
        'isUp': true,
      },
      {
        'icon': Icons.star,
        'title': 'En Çok Model',
        'value': mostCommonModel,
        'color': Colors.green,
        'trend': '',
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
              'Araç İstatistikleri',
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
              'Araç İstatistikleri',
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
                    if (card['trend'] != '')
                      Icon(card['isUp'] ? Icons.arrow_upward : Icons.arrow_downward,
                          color: card['isUp'] ? Colors.green : Colors.red, size: 12),
                    if (card['trend'] != '')
                      const SizedBox(width: 4),
                    if (card['trend'] != '')
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
                      if (card['trend'] != '')
                        Icon(card['isUp'] ? Icons.arrow_upward : Icons.arrow_downward,
                            color: card['isUp'] ? Colors.green : Colors.red, size: 16),
                      if (card['trend'] != '')
                        const SizedBox(width: 4),
                      if (card['trend'] != '')
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

  Widget _buildVehiclesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Araç Listesi',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _filteredVehicles.isEmpty
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
                                'Model',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Plaka',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Yıl',
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
                        itemCount: _filteredVehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = _filteredVehicles[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _editVehicle(vehicle),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        vehicle.model,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(vehicle.plate),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(vehicle.year?.toString() ?? '-'),
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
                                              ],
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _editVehicle(vehicle);
                                                } else if (value == 'delete') {
                                                  _deleteVehicle(vehicle);
                                                }
                                              },
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.edit_outlined, color: Colors.blue[600], size: 20),
                                                  tooltip: 'Düzenle',
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                  onPressed: () => _editVehicle(vehicle),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete_outline, color: Colors.red[600], size: 20),
                                                  tooltip: 'Sil',
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                  onPressed: () => _deleteVehicle(vehicle),
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
            tooltip: 'Önceki Sayfa',
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
              '$_currentPage / $_totalPages',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
            'Toplam $_totalRecords araç',
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
                tooltip: 'Önceki Sayfa',
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
              Text(' / $_totalPages', style: const TextStyle(color: Colors.grey)),
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
            'Toplam $_totalRecords araç',
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
                tooltip: 'İlk Sayfa',
                splashRadius: 20,
                color: _currentPage > 1 ? Colors.blue : Colors.grey,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? _previousPage : null,
                tooltip: 'Önceki Sayfa',
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
              Text(' / $_totalPages', style: const TextStyle(color: Colors.grey)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages ? _nextPage : null,
                tooltip: 'Sonraki Sayfa',
                splashRadius: 20,
                color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < _totalPages ? () => _changePage(_totalPages) : null,
                tooltip: 'Son Sayfa',
                splashRadius: 20,
                color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
              ),
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
                        _totalPages = (_totalRecords / _pageSize).ceil();
                        if (_totalPages == 0) _totalPages = 1;
                        _currentPage = 1;
                      });
                      _updateDisplayedVehicles();
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
              Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Henüz araç eklenmemiş',
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Text(
                'Yeni bir araç eklemek için sağ alttaki + butonuna tıklayın',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Yeni Araç Ekle'),
                onPressed: _addNewVehicle,
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

  void _editVehicle(Vehicle vehicle) {
    // Keep a reference to the BuildContext before async operations
    final currentContext = context;
    
    VehicleManagement.showEditVehicleDialog(
      currentContext,
      vehicle,
      (updatedVehicle) async {
        // Store a reference to the messenger outside the async operation
        final scaffoldMessenger = ScaffoldMessenger.of(currentContext);
        
        if (!mounted) return; // Check if still mounted
        
        setState(() {
          _isLoading = true;
        });
        
        try {
          // Get current user
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            throw Exception('You must be logged in to update vehicles');
          }
          
          // Update in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('vehicles')
              .doc(updatedVehicle.id)
              .update({
                'model': updatedVehicle.model,
                'plate': updatedVehicle.plate,
                'year': updatedVehicle.year,
                'updatedAt': FieldValue.serverTimestamp(),
              });
          
          // Reload data to ensure we have the latest
          if (mounted) {
            _loadVehicleData();
            
            // Show success message
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Araç bilgisi güncellendi'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          print('Error updating vehicle: $e');
          
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            
            // Show error message
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Araç güncellenirken hata oluştu: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  void _deleteVehicle(Vehicle vehicle) {
    // Keep a reference to the BuildContext before async operations
    final currentContext = context;
    
    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Araç Sil'),
        content: const Text('Bu aracı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Store a reference to the messenger outside the async operation
              final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
              
              // Close dialog first to prevent context issues
              Navigator.pop(dialogContext);
              
              if (!mounted) return; // Check if still mounted
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                // Get current user
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  throw Exception('You must be logged in to delete vehicles');
                }
                
                // Delete from Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('vehicles')
                    .doc(vehicle.id)
                    .delete();
                
                // Reload data to ensure we have the latest
                if (mounted) {
                  _loadVehicleData();
                  
                  // Show success message
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Araç başarıyla silindi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('Error deleting vehicle: $e');
                
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  
                  // Show error message
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Araç silinirken hata oluştu: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _addNewVehicle() {
    // Keep a reference to the BuildContext before async operations
    final currentContext = context;
    
    // Use the VehicleManagement class from add_vehicle.dart
    VehicleManagement.showAddVehicleDialog(
      currentContext,
      (newVehicle) async {
        // Store a reference to the messenger outside the async operation
        final scaffoldMessenger = ScaffoldMessenger.of(currentContext);
        
        if (!mounted) return; // Check if still mounted
        
        setState(() {
          _isLoading = true;
        });
        
        try {
          // Get current user
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            throw Exception('You must be logged in to add vehicles');
          }
          
          // Add to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('vehicles')
              .add({
                'model': newVehicle.model,
                'plate': newVehicle.plate,
                'year': newVehicle.year,
                'createdAt': FieldValue.serverTimestamp(),
              });
          
          // Reload data to ensure we have the latest
          if (mounted) {
            _loadVehicleData();
            
            // Show success message
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Yeni araç eklendi'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          print('Error adding vehicle: $e');
          
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            
            // Show error message
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Araç eklenirken hata oluştu: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }
}

