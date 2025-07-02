import 'package:flutter/material.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../services/odometer_service.dart';
import '../../models/odometer_record.dart';
import 'add_odometers.dart';

class OdometersPage extends StatefulWidget {
  const OdometersPage({super.key});
  @override
  State<OdometersPage> createState() => _OdometersPageState();
}

class _OdometersPageState extends State<OdometersPage> with SingleTickerProviderStateMixin {
  final svc = OdometerService();
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

  void _loadOdometerData() {
    setState(() {
      _isLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      final items = svc.getAll();
      setState(() {
        _allRecords = items;
        _totalRecords = items.length;
        _totalPages = (_totalRecords / _pageSize).ceil();
        if (_totalPages == 0) _totalPages = 1;
        _isLoading = false;
      });
      _updateDisplayedRecords();
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('İçe Aktar özelliği henüz eklenmedi.'), backgroundColor: Colors.blue),
    );
  }

  void _exportOdometers(BuildContext context) {
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
      drawer: const SideMenu(currentPage: 'odometers'),
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
              'Kilometre Kayıtları',
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
              'Araçların kilometre bilgilerini takip edin',
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
                hintText: 'Kilometre kaydı ara...',
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
                      'Kilometre Kayıtları',
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
                      'Araçların kilometre bilgilerini takip edin',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Yeni Kayıt'),
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
                      hintText: 'Kilometre kaydı ara...',
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
                icon: const Icon(Icons.upload_file),
                label: const Text('İçe Aktar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => _importOdometers(context),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Dışa Aktar'),
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
                  'Kilometre Kayıtları',
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
                  'Araçların kilometre bilgilerini takip edin',
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
                icon: const Icon(Icons.upload_file),
                label: const Text('İçe Aktar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => _importOdometers(context),
              ),
              const SizedBox(width: 16),
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
                onPressed: () => _exportOdometers(context),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Yeni Kayıt'),
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
                      hintText: 'Kilometre kaydı ara...',
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
        'title': 'Toplam Kayıt',
        'value': '$totalRecords',
        'color': Colors.indigo,
        'trend': '+2%',
        'isUp': true,
      },
      {
        'icon': Icons.timeline,
        'title': 'Ortalama Km',
        'value': '${averageKm.toStringAsFixed(0)} km',
        'color': Colors.orange,
        'trend': '+3%',
        'isUp': true,
      },
      {
        'icon': Icons.trending_up,
        'title': 'En Yüksek Km',
        'value': '$maxKm km',
        'color': Colors.blue,
        'trend': '+5%',
        'isUp': true,
      },
      {
        'icon': Icons.calendar_today,
        'title': 'Son Güncelleme',
        'value': lastUpdate != null ? _formatDate(lastUpdate) : '-',
        'color': Colors.green,
        'trend': 'Bugün',
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
              'Kilometre İstatistikleri',
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
              'Kilometre İstatistikleri',
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
          'Kilometre Listesi',
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
                                'Araç ID',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Tarih',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Kilometre',
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
                                        record.vehicleId.isEmpty ? '(Araç yok)' : record.vehicleId,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(_formatDate(record.date)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('${record.value} km'),
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
                                                  tooltip: 'Düzenle',
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                  onPressed: () => _editOdometerRecord(record),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete_outline, color: Colors.red[600], size: 20),
                                                  tooltip: 'Sil',
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
            'Toplam $_totalRecords kayıt',
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
            'Toplam $_totalRecords kayıt',
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
                'Henüz kilometre kaydı eklenmemiş',
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Text(
                'Yeni bir kilometre kaydı eklemek için sağ alttaki + butonuna tıklayın',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Yeni Kilometre Kaydı Ekle'),
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
        // Callback for when record is updated
        _loadOdometerData();
      },
      editRecord: record,
    );
  }

  void _deleteOdometerRecord(OdometerRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kilometre Kaydını Sil'),
        content: const Text('Bu kilometre kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              svc.remove(record.id);
              _loadOdometerData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kilometre kaydı silindi'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _addNewOdometerRecord() {
    OdometerManagement.addNewOdometer(
      context, 
      () {
        // Callback for when record is added/updated
        _loadOdometerData();
      }
    );
  }
}