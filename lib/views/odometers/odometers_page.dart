import 'package:flutter/material.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../services/odometer_service.dart';
import '../../models/odometer_record.dart';

class OdometersPage extends StatefulWidget {
  const OdometersPage({super.key});
  @override
  State<OdometersPage> createState() => _OdometersPageState();
}

class _OdometersPageState extends State<OdometersPage> with SingleTickerProviderStateMixin {
  final svc = OdometerService();
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  List<bool> _isStatsHovering = []; // List for stats cards hovering state
  List<bool> _isRecordHovering = []; // List for odometer cards hovering state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    // Initialize hovering states for stats cards
    _isStatsHovering = List.generate(4, (_) => false);
    
    // Initialize hovering states for odometer records
    _updateHoverStates();
  }

  // Add this new method to update hover states whenever the record list changes
  void _updateHoverStates() {
    final records = svc.getAll();
    _isRecordHovering = List.generate(records.length, (_) => false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = svc.getAll();
    
    // Update hover states if the length changed
    if (_isRecordHovering.length != items.length) {
      _updateHoverStates();
    }
    
    return Scaffold(
      appBar: const TopBar(),
      drawer: const SideMenu(currentPage: 'odometers'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section with title and search
                    _buildHeaderSection(context),
                    
                    const SizedBox(height: 32),
                    
                    // Stats section
                    _buildStatsSection(context, items),
                    
                    const SizedBox(height: 40),
                    
                    // Odometers section
                    _buildOdometersSection(context, items),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewOdometerRecord,
        tooltip: 'Yeni Kilometre Kaydı Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
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
                  onChanged: (value) {
                    // Implement search functionality
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, List<OdometerRecord> items) {
    // Calculate odometer statistics
    int totalRecords = items.length;
    double averageKm = 0;
    int maxKm = 0;
    
    if (items.isNotEmpty) {
      int totalKm = 0;
      for (var record in items) {
        totalKm += record.value as int;
        if (record.value > maxKm) {
          maxKm = record.value as int;
        }
      }
      averageKm = totalKm / totalRecords;
    }
    
    return LayoutBuilder(
      builder: (ctx, constraints) {
        int cols = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
                ? 2
                : 1;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
                ),
              ),
              child: Text(
                'Kilometre İstatistikleri',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.5,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
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
                    'value': items.isNotEmpty ? _formatDate(items.first.date) : '-',
                    'color': Colors.green,
                    'trend': 'Bugün',
                    'isUp': true,
                  },
                ];

                return MouseRegion(
                  onEnter: (_) => setState(() => _isStatsHovering[index] = true),
                  onExit: (_) => setState(() => _isStatsHovering[index] = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: _isStatsHovering[index]
                        ? (Matrix4.identity()..translate(0, -5, 0))
                        : Matrix4.identity(),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cards[index]['color'].withOpacity(_isStatsHovering[index] ? 0.3 : 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: _isStatsHovering[index]
                            ? cards[index]['color']
                            : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
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
                                  color: cards[index]['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  cards[index]['icon'],
                                  color: cards[index]['color'],
                                  size: 24,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    cards[index]['isUp']
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: cards[index]['isUp']
                                        ? Colors.green
                                        : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    cards[index]['trend'],
                                    style: TextStyle(
                                      color: cards[index]['isUp']
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            cards[index]['title'],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cards[index]['value'],
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildOdometersSection(BuildContext context, List<OdometerRecord> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kilometre Listesi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filtrele'),
                  onPressed: () {
                    // Filtreleme seçenekleri
                    _showFilterDialog(context);
                  },
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yenile'),
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    
                    // Simulate loading delay
                    Future.delayed(const Duration(milliseconds: 800), () {
                      setState(() {
                        _isLoading = false;
                      });
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        items.isEmpty
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
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 1200 
                        ? 3 
                        : constraints.maxWidth > 800 
                            ? 2 
                            : 1;
                    
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final record = items[index];
                        
                        // Ensure the hovering list is up to date with data list
                        if (_isRecordHovering.length != items.length) {
                          _isRecordHovering = List.generate(items.length, (_) => false);
                        }
                        
                        final vehicleInfo = record.vehicleId.isEmpty 
                            ? '(Araç seçilmedi)' 
                            : 'Araç ID: ${record.vehicleId}';
                        
                        return MouseRegion(
                          onEnter: (_) => setState(() => _isRecordHovering[index] = true),
                          onExit: (_) => setState(() => _isRecordHovering[index] = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: _isRecordHovering[index]
                                ? (Matrix4.identity()..translate(0, -5, 0))
                                : Matrix4.identity(),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withOpacity(_isRecordHovering[index] ? 0.2 : 0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                              border: Border.all(
                                color: _isRecordHovering[index]
                                    ? Theme.of(context).primaryColor.withOpacity(0.5)
                                    : Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _editOdometerRecord(record),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.speed,
                                          color: Theme.of(context).primaryColor,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '${record.value} km',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        vehicleInfo,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tarih: ${_formatDate(record.date)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (_isRecordHovering[index])
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              tooltip: 'Düzenle',
                                              onPressed: () => _editOdometerRecord(record),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              tooltip: 'Sil',
                                              onPressed: () => _deleteOdometerRecord(record),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
      ],
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

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kilometre Kayıtlarını Filtrele'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Araç',
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tüm Araçlar')),
                  DropdownMenuItem(value: 'car1', child: Text('Araç 1')),
                  DropdownMenuItem(value: 'car2', child: Text('Araç 2')),
                ],
                onChanged: (value) {
                  // Handle filter selection
                },
                value: 'all',
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Minimum Kilometre',
                  hintText: 'Minimum kilometre değeri',
                ),
                keyboardType: TextInputType.number,
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

  void _editOdometerRecord(OdometerRecord record) {
    // Show dialog to edit the record
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kilometre Kaydını Düzenle'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Kilometre',
                  hintText: 'Kilometre değerini girin',
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: record.value.toString()),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    record.value = int.parse(value) as double;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Araç ID',
                  hintText: 'Araç ID\'sini girin',
                ),
                controller: TextEditingController(text: record.vehicleId),
                onChanged: (value) {
                  record.vehicleId = value;
                },
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
              // Save the updated record
              svc.update(record);
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kilometre kaydı güncellendi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
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
              // Delete odometer record
              svc.remove(record.id);
              setState(() {
                _updateHoverStates(); // Update hover states after deletion
              });
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
    final o = OdometerRecord(
      id: DateTime.now().toIso8601String(),
      vehicleId: '',
      date: DateTime.now(),
      value: 0,
    );
    
    // Show dialog to enter new record details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Kilometre Kaydı'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Kilometre',
                  hintText: 'Kilometre değerini girin',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    o.value = int.parse(value) as double;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Araç ID',
                  hintText: 'Araç ID\'sini girin',
                ),
                onChanged: (value) {
                  o.vehicleId = value;
                },
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
              // Add the new record
              svc.add(o);
              setState(() {
                _updateHoverStates(); // Update hover states after adding a record
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Yeni kilometre kaydı eklendi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}