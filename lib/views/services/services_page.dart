import 'package:flutter/material.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../services/service_service.dart';
import '../../models/service_entry.dart';
import '../../services/vehicle_service.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});
  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> with SingleTickerProviderStateMixin {
  final svc = ServiceService();
  final vehicleSvc = VehicleService();
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  List<bool> _isStatsHovering = []; // List for stats cards hovering state
  List<bool> _isServiceHovering = []; // List for service cards hovering state
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
    
    // Initialize hovering states for service cards
    final services = svc.getAll();
    _isServiceHovering = List.generate(services.length, (_) => false);
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
    final vehicles = vehicleSvc.getAll();
    
    // Map vehicle IDs to their models for display
    Map<String, String> vehicleModels = {};
    for (var vehicle in vehicles) {
      vehicleModels[vehicle.id] = vehicle.model;
    }
    
    return Scaffold(
      appBar: const TopBar(),
      drawer: const SideMenu(currentPage: 'service'),
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
                    
                    // Services section
                    _buildServicesSection(context, items, vehicleModels),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewServiceEntry,
        tooltip: 'Yeni Servis Kaydı Ekle',
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
                    'Servis Kayıtları',
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
                    'Araç bakım ve servis işlemlerini takip edin',
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
                    hintText: 'Servis kaydı ara...',
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

  Widget _buildStatsSection(BuildContext context, List<ServiceEntry> items) {
    // Calculate service statistics
    double totalCost = 0;
    double averageCost = 0;
    Map<String, int> serviceTypeCount = {};
    String mostCommonService = 'Yok';
    int maxCount = 0;
    
    for (var service in items) {
      totalCost += service.cost;
      
      // Count service types
      final type = service.serviceType.isEmpty ? 'Belirsiz' : service.serviceType;
      serviceTypeCount[type] = (serviceTypeCount[type] ?? 0) + 1;
      
      // Find most common service type
      if (serviceTypeCount[type]! > maxCount) {
        maxCount = serviceTypeCount[type]!;
        mostCommonService = type;
      }
    }
    
    averageCost = items.isEmpty ? 0 : totalCost / items.length;
    
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
                'Servis İstatistikleri',
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
                    'icon': Icons.build,
                    'title': 'Toplam Servis',
                    'value': '${items.length}',
                    'color': Colors.indigo,
                    'trend': '+3%',
                    'isUp': true,
                  },
                  {
                    'icon': Icons.attach_money,
                    'title': 'Toplam Maliyet',
                    'value': '${totalCost.toStringAsFixed(2)} TL',
                    'color': Colors.orange,
                    'trend': '+5%',
                    'isUp': true,
                  },
                  {
                    'icon': Icons.category,
                    'title': 'En Sık Servis',
                    'value': mostCommonService,
                    'color': Colors.blue,
                    'trend': '+2%',
                    'isUp': true,
                  },
                  {
                    'icon': Icons.calculate,
                    'title': 'Ortalama Maliyet',
                    'value': '${averageCost.toStringAsFixed(2)} TL',
                    'color': Colors.green,
                    'trend': '-1%',
                    'isUp': false,
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

  Widget _buildServicesSection(BuildContext context, List<ServiceEntry> items, Map<String, String> vehicleModels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Servis Listesi',
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
                        final service = items[index];
                        
                        // Ensure the hovering list is up to date with data list
                        if (_isServiceHovering.length != items.length) {
                          _isServiceHovering = List.generate(items.length, (_) => false);
                        }
                        
                        final vehicleModel = service.vehicleId.isEmpty 
                            ? '(Araç seçilmedi)' 
                            : vehicleModels[service.vehicleId] ?? 'Bilinmeyen Araç';
                        
                        return MouseRegion(
                          onEnter: (_) => setState(() => _isServiceHovering[index] = true),
                          onExit: (_) => setState(() => _isServiceHovering[index] = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: _isServiceHovering[index]
                                ? (Matrix4.identity()..translate(0, -5, 0))
                                : Matrix4.identity(),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withOpacity(_isServiceHovering[index] ? 0.2 : 0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                              border: Border.all(
                                color: _isServiceHovering[index]
                                    ? Theme.of(context).primaryColor.withOpacity(0.5)
                                    : Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _editServiceEntry(service),
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
                                          Icons.build,
                                          color: Theme.of(context).primaryColor,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        service.serviceType.isEmpty ? '(Tür yok)' : service.serviceType,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Araç: $vehicleModel',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tarih: ${_formatDate(service.date)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Maliyet: ${service.cost} TL',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (_isServiceHovering[index])
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              tooltip: 'Düzenle',
                                              onPressed: () => _editServiceEntry(service),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              tooltip: 'Sil',
                                              onPressed: () => _deleteServiceEntry(service),
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
              Icon(Icons.build_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Henüz servis kaydı eklenmemiş',
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Text(
                'Yeni bir servis kaydı eklemek için sağ alttaki + butonuna tıklayın',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Yeni Servis Kaydı Ekle'),
                onPressed: _addNewServiceEntry,
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
        title: const Text('Servis Kayıtlarını Filtrele'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Servis Türü',
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tümü')),
                  DropdownMenuItem(value: 'maintenance', child: Text('Bakım')),
                  DropdownMenuItem(value: 'repair', child: Text('Onarım')),
                  DropdownMenuItem(value: 'inspection', child: Text('Muayene')),
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

  void _editServiceEntry(ServiceEntry service) {
    // Navigation to edit page would go here
    // For now, just print the service ID
    print('Editing service entry: ${service.id}');
  }

  void _deleteServiceEntry(ServiceEntry service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servis Kaydını Sil'),
        content: Text('Bu servis kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete service entry logic
              svc.remove(service.id);
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Servis kaydı silindi'),
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

  void _addNewServiceEntry() {
    final s = ServiceEntry(
      id: DateTime.now().toIso8601String(),
      vehicleId: '',
      date: DateTime.now(),
    );
    svc.add(s);
    setState(() {
      // Update the hovering states list
      _isServiceHovering.add(false);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yeni servis kaydı eklendi'),
        backgroundColor: Colors.green,
      ),
    );
  }
}