import 'package:flutter/material.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../services/contract_service.dart';
import '../../models/contract.dart';

class ContractsPage extends StatefulWidget {
  const ContractsPage({super.key});
  @override
  State<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends State<ContractsPage> with SingleTickerProviderStateMixin {
  final svc = ContractService();
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  List<bool> _isStatsHovering = []; // List for stats cards hovering state
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
    
    return Scaffold(
      appBar: const TopBar(),
      drawer: const SideMenu(),
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
                    
                    // Contracts list section
                    _buildContractsSection(context, items),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewContract,
        tooltip: 'Yeni Sözleşme Ekle',
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
                'Sözleşme İstatistikleri',
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

  Widget _buildContractsSection(BuildContext context, List<Contract> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sözleşme Listesi',
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
                              flex: 3,
                              child: Text(
                                'Referans',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
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
                              ),
                            ),
                            const SizedBox(width: 50),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Contract list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final contract = items[index];
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
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        contract.reference.isEmpty ? '(Ref yok)' : contract.reference,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        contract.vehicleId.isEmpty ? '(Araç yok)' : contract.vehicleId,
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
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 50,
                                      child: PopupMenuButton(
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
                                          const PopupMenuItem(
                                            value: 'renew',
                                            child: Text('Yenile'),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _editContract(contract);
                                          } else if (value == 'delete') {
                                            _deleteContract(contract);
                                          } else if (value == 'renew') {
                                            _renewContract(contract);
                                          }
                                        },
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
                  ),
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
    // Navigation to edit page would go here
    // For now, just print the contract reference
    print('Editing contract: ${contract.reference}');
  }

  void _deleteContract(Contract contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sözleşmeyi Sil'),
        content: Text('${contract.reference.isEmpty ? "Bu sözleşmeyi" : contract.reference} silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                // Delete contract logic
                svc.remove(contract.id);
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sözleşme silindi'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hata: Sözleşme silinemedi - ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
                  vehicleId: contract.vehicleId,
                  reference: contract.reference,
                  startDate: contract.startDate,
                  endDate: newEndDate,
                );
                svc.update(updatedContract);
                setState(() {});
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
    try {
      final c = Contract(
        id: DateTime.now().toIso8601String(),
        vehicleId: '',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        reference: '',
      );
      svc.add(c);
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeni sözleşme eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: Sözleşme eklenemedi - ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}