import 'package:flutter/material.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';

// ModelItem class moved from models_page.dart
class ModelItem {
  String id, name, manufacturer, category;
  ModelItem({required this.id, this.name = '', this.manufacturer = '', this.category = ''});
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class SettingsCategory {
  final IconData icon;
  final String title;
  final bool isEnabled;

  SettingsCategory({required this.icon, required this.title, this.isEnabled = true});
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  List<bool> _isStatsHovering = []; // List for stats cards hovering state
  int _selectedTabIndex = 0;
  
  // Added variables for models functionality
  final List<ModelItem> _modelsList = [];
  bool _isModelsLoading = false;
  List<bool> _isModelRowHovering = [];
  
  // Add settings categories list
  late List<SettingsCategory> _settingsCategories;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    // Initialize hovering states for stats cards
    _isStatsHovering = List.generate(4, (_) => false);
    
    // Initialize models data
    _generateSampleModelData();
    _isModelRowHovering = List.generate(_modelsList.length, (_) => false);
    
    // Initialize settings categories
    _initSettingsCategories();
  }
  
  void _initSettingsCategories() {
    _settingsCategories = [
      SettingsCategory(icon: Icons.category, title: 'Araç Tanımı Ekleme'),
      SettingsCategory(icon: Icons.admin_panel_settings, title: 'Roller ve Yetkiler'),
      SettingsCategory(icon: Icons.notifications, title: 'Bildirim Ayarları'),
      SettingsCategory(icon: Icons.backup, title: 'Kullanıcı Ekleme'),
      SettingsCategory(icon: Icons.language, title: 'Dil Ayarları', isEnabled: false),
      SettingsCategory(icon: Icons.color_lens, title: 'Tema Ayarları', isEnabled: false),
    ];
  }

  // Generate sample model data (moved from ModelsPage)
  void _generateSampleModelData() {
    _modelsList.addAll([
      ModelItem(id: '1', name: 'BMW X5', manufacturer: 'BMW', category: 'SUV'),
      ModelItem(id: '2', name: 'Mercedes C200', manufacturer: 'Mercedes', category: 'Sedan'),
      ModelItem(id: '3', name: 'Audi A4', manufacturer: 'Audi', category: 'Sedan'),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      drawer: const SideMenu(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with title and search
              _buildHeaderSection(context),
              
              const SizedBox(height: 32),
              
              // Stats section
              _buildStatsSection(context),
              
              const SizedBox(height: 40),
              
              // Tab navigation
              _buildTabSection(context),
              
              const SizedBox(height: 24),
              
              // Tab content
              _buildTabContent(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Save settings
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ayarlar kaydedildi')),
          );
        },
        tooltip: 'Değişiklikleri Kaydet',
        child: const Icon(Icons.save),
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
                    'Sistem Ayarları',
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
                    'Uygulama tercihlerini ve kullanıcı yetkilerini yönetin',
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
                    hintText: 'Ayar ara...',
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

  Widget _buildStatsSection(BuildContext context) {
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
                'Sistem İstatistikleri',
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
                    'icon': Icons.verified_user,
                    'title': 'Kullanıcı Rolleri',
                    'value': '5',
                    'color': Colors.purple,
                    'trend': '+1',
                    'isUp': true,
                  },
                  {
                    'icon': Icons.settings_applications,
                    'title': 'Aktif Ayarlar',
                    'value': '24',
                    'color': Colors.blue,
                    'trend': '+3',
                    'isUp': true,
                  },
                  {
                    'icon': Icons.update,
                    'title': 'Son Güncelleme',
                    'value': '2 saat önce',
                    'color': Colors.orange,
                    'trend': '',
                    'isUp': true,
                    'noTrend': true,
                  },
                  {
                    'icon': Icons.cloud_done,
                    'title': 'Sistem Durumu',
                    'value': 'Aktif',
                    'color': Colors.green,
                    'trend': '99.9%',
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
                              if (!(cards[index]['noTrend'] ?? false))
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
  
  Widget _buildTabSection(BuildContext context) {
    // Get only enabled categories
    final enabledCategories = _settingsCategories.where((cat) => cat.isEnabled).toList();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // For smaller screens, show a button that opens a dialog
        final bool useDialog = constraints.maxWidth < 768;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ayar Kategorileri',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (useDialog)
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'Kategorileri Yönet',
                    onPressed: () => _showCategoryDialog(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            useDialog
                ? _buildCategoryCard(context, enabledCategories[_selectedTabIndex])
                : _buildCategoryTabs(context, enabledCategories),
          ],
        );
      },
    );
  }
  
  Widget _buildCategoryCard(BuildContext context, SettingsCategory category) {
    return GestureDetector(
      onTap: () {
        // Show appropriate dialog based on category
        _showCategoryPopupDialog(context, category.title);
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                category.icon,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                category.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryTabs(BuildContext context, List<SettingsCategory> categories) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: List.generate(
          categories.length,
          (index) => Expanded(
            child: InkWell(
              onTap: () {
                // Show appropriate dialog based on category
                _showCategoryPopupDialog(context, categories[index].title);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == index
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      categories[index].icon,
                      color: _selectedTabIndex == index ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      categories[index].title,
                      style: TextStyle(
                        color: _selectedTabIndex == index ? Colors.white : Colors.grey[600],
                        fontWeight: _selectedTabIndex == index ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _showCategoryDialog(BuildContext context) async {
    final List<bool> selectedCategories = 
        _settingsCategories.map((cat) => cat.isEnabled).toList();
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Ayar Kategorilerini Yönet'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Görüntülemek istediğiniz kategorileri seçin'),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _settingsCategories.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(
                            _settingsCategories[index].icon,
                            color: selectedCategories[index] ? Theme.of(context).primaryColor : Colors.grey,
                          ),
                          title: Text(_settingsCategories[index].title),
                          trailing: Switch(
                            value: selectedCategories[index],
                            onChanged: (value) {
                              setState(() {
                                selectedCategories[index] = value;
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              selectedCategories[index] = !selectedCategories[index];
                            });
                          },
                        );
                      },
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
                  // Ensure at least one category is selected
                  if (selectedCategories.contains(true)) {
                    // Update categories
                    for (int i = 0; i < _settingsCategories.length; i++) {
                      _settingsCategories[i] = SettingsCategory(
                        icon: _settingsCategories[i].icon,
                        title: _settingsCategories[i].title,
                        isEnabled: selectedCategories[i],
                      );
                    }
                    
                    // Update selected tab if needed
                    if (!_settingsCategories[_selectedTabIndex].isEnabled) {
                      _selectedTabIndex = _settingsCategories.indexWhere((cat) => cat.isEnabled);
                    }
                    
                    this.setState(() {});
                    Navigator.pop(context);
                  } else {
                    // Show error if no category is selected
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('En az bir kategori seçmelisiniz'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildTabContent(BuildContext context) {
    // Just show a message prompting to click on the tabs
    return Container(
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Ayarları görüntülemek için yukarıdaki kategorilerden birini seçin',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showCategoryDialog(context),
              child: const Text('Kategorileri Yönet'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Methods for models functionality moved from ModelsPage
  
  Widget _buildModelsTab(BuildContext context) {
    return Container(
      key: const ValueKey('models'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModelsHeaderSection(context),
          const SizedBox(height: 24),
          _buildModelsSearchAndFilters(context),
          const SizedBox(height: 24),
          _buildModelsStatCards(context),
          const SizedBox(height: 24),
          Container(
            height: 500,
            child: _isModelsLoading
                ? _buildModelsLoadingState()
                : _modelsList.isEmpty
                    ? _buildModelsEmptyState()
                    : _buildModelsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildModelsHeaderSection(BuildContext context) {
    return Row(
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
            'Araç Modelleri',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ),
        FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
            ),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Yenile'),
                onPressed: () {
                  setState(() {
                    _isModelsLoading = true;
                  });
                  
                  // Simulate loading
                  Future.delayed(const Duration(seconds: 1), () {
                    setState(() {
                      _isModelsLoading = false;
                    });
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Yeni Model'),
                onPressed: _addNewModel,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModelsSearchAndFilters(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Model, üretici veya kategori ara...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                // Implement search functionality
              },
            ),
          ),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            child: Chip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Filtrele'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
              backgroundColor: Colors.grey[100],
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Tümü'),
              ),
              const PopupMenuItem(
                value: 'sedan',
                child: Text('Sedan'),
              ),
              const PopupMenuItem(
                value: 'suv',
                child: Text('SUV'),
              ),
              const PopupMenuItem(
                value: 'hatchback',
                child: Text('Hatchback'),
              ),
            ],
            onSelected: (value) {
              // Handle filter selection
            },
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            child: Chip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Sırala'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
              backgroundColor: Colors.grey[100],
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name_asc',
                child: Text('İsim (A-Z)'),
              ),
              const PopupMenuItem(
                value: 'name_desc',
                child: Text('İsim (Z-A)'),
              ),
              const PopupMenuItem(
                value: 'manufacturer',
                child: Text('Üretici'),
              ),
              const PopupMenuItem(
                value: 'category',
                child: Text('Kategori'),
              ),
            ],
            onSelected: (value) {
              // Handle sort selection
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModelsStatCards(BuildContext context) {
    final stats = [
      {'title': 'Toplam Model', 'value': _modelsList.length.toString(), 'icon': Icons.category, 'color': Colors.blue},
      {'title': 'Üreticiler', 'value': '3', 'icon': Icons.business, 'color': Colors.green},
      {'title': 'Kategoriler', 'value': '2', 'icon': Icons.class_, 'color': Colors.orange},
    ];

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
        ),
      ),
      // Remove fixed height constraint to allow content to size naturally
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        // Padding instead of fixed height
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16.0, // Horizontal space between cards
            runSpacing: 16.0, // Vertical space between rows
            children: stats.map((stat) {
              return Container(
                width: 180,
                // Use min height constraint instead of fixed height
                constraints: const BoxConstraints(minHeight: 90),
                padding: const EdgeInsets.all(12), // Reduced padding
                decoration: BoxDecoration(
                  color: stat['color'] as Color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (stat['color'] as Color).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min, // Take minimum space
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          stat['icon'] as IconData,
                          color: Colors.white,
                          size: 22, // Smaller icon
                        ),
                        const SizedBox(height: 6), // Reduced spacing
                        Text(
                          stat['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 13, // Smaller font
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2), // Minimal spacing
                        Text(
                          stat['value'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22, // Smaller font
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildModelsTable() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      )),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              headingRowHeight: 48,
              dataRowHeight: 60,
              headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
              columns: const [
                DataColumn(
                  label: Text(
                    'Ad',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Üretici',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Kategori',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'İşlemler',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: List.generate(
                _modelsList.length,
                (index) {
                  final model = _modelsList[index];
                  
                  // Ensure the hovering list is up to date with data list
                  if (_isModelRowHovering.length != _modelsList.length) {
                    _isModelRowHovering = List.generate(_modelsList.length, (_) => false);
                  }
                  
                  return DataRow(
                    color: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        if (_isModelRowHovering[index]) {
                          return Colors.grey[100];
                        }
                        return null; // Use default value
                      },
                    ),
                    cells: [
                      DataCell(
                        TextFormField(
                          initialValue: model.name,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'Ad girin',
                          ),
                          onChanged: (v) => model.name = v,
                        ),
                        onTap: () {
                          setState(() {
                            _isModelRowHovering[index] = true;
                          });
                        },
                      ),
                      DataCell(
                        TextFormField(
                          initialValue: model.manufacturer,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'Üretici girin',
                          ),
                          onChanged: (v) => model.manufacturer = v,
                        ),
                        onTap: () {
                          setState(() {
                            _isModelRowHovering[index] = true;
                          });
                        },
                      ),
                      DataCell(
                        TextFormField(
                          initialValue: model.category,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'Kategori girin',
                          ),
                          onChanged: (v) => model.category = v,
                        ),
                        onTap: () {
                          setState(() {
                            _isModelRowHovering[index] = true;
                          });
                        },
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.save, color: Colors.green),
                              tooltip: 'Kaydet',
                              onPressed: () => _saveModel(model),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Sil',
                              onPressed: () => _deleteModel(model),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _isModelRowHovering[index] = true;
                          });
                        },
                      ),
                    ],
                    onSelectChanged: (selected) {
                      if (selected != null) {
                        setState(() {
                          _isModelRowHovering[index] = selected;
                        });
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelsEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _controller,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Henüz model eklenmemiş',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(
              'Yeni bir model eklemek için "Yeni Model" butonuna tıklayın',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Yeni Model Ekle'),
              onPressed: _addNewModel,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelsLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Veriler yükleniyor...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _addNewModel() {
    // Instead of directly adding a model, show a dialog first
    _showAddModelDialog(context);
  }

  // New method to show the add model dialog
  Future<void> _showAddModelDialog(BuildContext context) async {
    // Create temporary values for the new model
    String name = '';
    String manufacturer = '';
    String category = '';
    
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 500,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Yeni Model Ekle',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Model name field
                      Text(
                        'Model Adı',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (value) => name = value,
                        decoration: InputDecoration(
                          hintText: 'Model adını girin',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Manufacturer field
                      Text(
                        'Üretici',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (value) => manufacturer = value,
                        decoration: InputDecoration(
                          hintText: 'Üretici adını girin',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Category field
                      Text(
                        'Kategori',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: category.isEmpty ? null : category,
                        decoration: InputDecoration(
                          hintText: 'Kategori seçin',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Sedan', child: Text('Sedan')),
                          DropdownMenuItem(value: 'SUV', child: Text('SUV')),
                          DropdownMenuItem(value: 'Hatchback', child: Text('Hatchback')),
                          DropdownMenuItem(value: 'Coupe', child: Text('Coupe')),
                          DropdownMenuItem(value: 'Convertible', child: Text('Convertible')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            category = value;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Footer with action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Ekle'),
                      onPressed: () {
                        // Create and add new model with the entered details
                        setState(() {
                          final newModel = ModelItem(
                            id: DateTime.now().toIso8601String(),
                            name: name,
                            manufacturer: manufacturer,
                            category: category,
                          );
                          _modelsList.add(newModel);
                          _isModelRowHovering.add(false);
                        });
                        
                        // Show success message and close dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Model başarıyla eklendi'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveModel(ModelItem model) {
    // Implement your save logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Model kaydedildi'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteModel(ModelItem model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modeli Sil'),
        content: Text('${model.name.isEmpty ? "Bu modeli" : model.name} silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final index = _modelsList.indexOf(model);
              setState(() {
                _modelsList.remove(model);
                // Remove the corresponding hovering state
                if (index < _isModelRowHovering.length) {
                  _isModelRowHovering.removeAt(index);
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Model silindi'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
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
  
  // New method to show models in a dialog
  Future<void> _showModelsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(  // Added Center widget here
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: 900,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Center cross axis
              children: [
                // Header section - fixed height
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Araç Modelleri',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // Content section - takes remaining space with scrolling
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // Center content
                        children: [
                          // Models header with actions
                          _buildModelsDialogHeaderSection(context),
                          const SizedBox(height: 24),
                          
                          // Search and filters
                          _buildModelsSearchAndFilters(context),
                          const SizedBox(height: 24),
                          
                          // Stats cards
                          _buildModelsStatCards(context),
                          const SizedBox(height: 24),
                          
                          // Models table or empty/loading state
                          SizedBox(
                            height: 400,
                            child: _isModelsLoading
                                ? _buildModelsLoadingState()
                                : _modelsList.isEmpty
                                    ? _buildModelsEmptyState()
                                    : _buildModernModelsList(context), // Use modern design instead
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Footer section - fixed height
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center buttons
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Save changes and close dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Değişiklikler kaydedildi'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Modify the models header section to fit in dialog
  Widget _buildModelsDialogHeaderSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Model Yönetimi',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Yenile'),
              onPressed: () {
                setState(() {
                  _isModelsLoading = true;
                });
                
                // Simulate loading
                Future.delayed(const Duration(seconds: 1), () {
                  setState(() {
                    _isModelsLoading = false;
                  });
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Yeni Model'),
              onPressed: _addNewModel,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // New method for modern model list display (replacing DataTable)
  Widget _buildModernModelsList(BuildContext context) {
    // Column header section
    Widget header = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Ad',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Üretici',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Kategori',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'İşlemler',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        header,
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: _modelsList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final model = _modelsList[index];
              
              // Ensure the hovering list is up to date with data list
              if (_isModelRowHovering.length != _modelsList.length) {
                _isModelRowHovering = List.generate(_modelsList.length, (_) => false);
              }
              
              return MouseRegion(
                onEnter: (_) => setState(() => _isModelRowHovering[index] = true),
                onExit: (_) => setState(() => _isModelRowHovering[index] = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _isModelRowHovering[index] ? Colors.grey[50] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isModelRowHovering[index] 
                          ? Theme.of(context).primaryColor.withOpacity(0.5) 
                          : Colors.grey[200]!,
                    ),
                    boxShadow: _isModelRowHovering[index] 
                        ? [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ] 
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: model.name,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'Ad girin',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          onChanged: (v) => model.name = v,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: model.manufacturer,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'Üretici girin',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) => model.manufacturer = v,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: model.category,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'Kategori girin',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) => model.category = v,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _saveModel(model),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.save_rounded,
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _deleteModel(model),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.delete_rounded,
                                    color: Colors.red[600],
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // New helper method to determine which dialog to show
  void _showCategoryPopupDialog(BuildContext context, String categoryTitle) {
    switch (categoryTitle) {
      case 'Modeller':
        _showModelsDialog(context);
        break;
      case 'Roller ve Yetkiler':
        _showRolesDialog(context);
        break;
      case 'Bildirim Ayarları':
        _showNotificationsDialog(context);
        break;
      case 'Kullanıcı Ekleme':
        _showBackupDialog(context);
        break;
      default:
        // For other categories, show the category selection dialog
        _showCategoryDialog(context);
    }
  }

  // New method for Roles and Permissions dialog
  Future<void> _showRolesDialog(BuildContext context) async {
    // Sample roles data
    final List<Map<String, dynamic>> roles = [
      {
        'name': 'Yönetici',
        'description': 'Tüm sistem özelliklerine erişebilir',
        'users': 2,
        'permissions': {
          'Araçları Yönet': true,
          'Kullanıcıları Yönet': true,
          'Ayarları Değiştir': true,
          'Raporları Görüntüle': true,
          'Modelleri Düzenle': true,
        }
      },
      {
        'name': 'Müdür',
        'description': 'Çoğu sistem özelliğine erişebilir',
        'users': 5,
        'permissions': {
          'Araçları Yönet': true,
          'Kullanıcıları Yönet': false,
          'Ayarları Değiştir': false,
          'Raporları Görüntüle': true,
          'Modelleri Düzenle': true,
        }
      },
      {
        'name': 'Operatör',
        'description': 'Sınırlı sistem özelliklerine erişebilir',
        'users': 12,
        'permissions': {
          'Araçları Yönet': true,
          'Kullanıcıları Yönet': false,
          'Ayarları Değiştir': false,
          'Raporları Görüntüle': true,
          'Modelleri Düzenle': false,
        }
      },
      {
        'name': 'Misafir',
        'description': 'Sadece görüntüleme yetkilerine sahiptir',
        'users': 8,
        'permissions': {
          'Araçları Yönet': false,
          'Kullanıcıları Yönet': false,
          'Ayarları Değiştir': false,
          'Raporları Görüntüle': true,
          'Modelleri Düzenle': false,
        }
      },
    ];

    // Selected role for permissions editing
    int selectedRoleIndex = 0;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: 900,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Roller ve Yetkiler',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    
                    // Content section
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side - Roles list
                          Container(
                            width: 300,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Roller',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle),
                                        tooltip: 'Yeni Rol Ekle',
                                        color: Colors.green,
                                        onPressed: () {
                                          // Add new role logic
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Yeni rol ekleme özelliği yapım aşamasında'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                
                                // Roles list
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: roles.length,
                                    itemBuilder: (context, index) {
                                      final role = roles[index];
                                      return ListTile(
                                        selected: selectedRoleIndex == index,
                                        selectedColor: Theme.of(context).primaryColor,
                                        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                        title: Text(
                                          role['name'] as String,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          '${role["users"]} kullanıcı',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: selectedRoleIndex == index
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey[200],
                                          foregroundColor: selectedRoleIndex == index
                                              ? Colors.white
                                              : Colors.grey[800],
                                          child: Text(
                                            (role['name'] as String)[0],
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            selectedRoleIndex = index;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Right side - Permissions
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Role details header
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        radius: 24,
                                        child: Text(
                                          (roles[selectedRoleIndex]['name'] as String)[0],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            roles[selectedRoleIndex]['name'] as String,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            roles[selectedRoleIndex]['description'] as String,
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Permissions section
                                  Text(
                                    'Yetkiler',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Permissions list
                                  Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Colors.grey[200]!),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: (roles[selectedRoleIndex]['permissions'] as Map).length,
                                      separatorBuilder: (context, index) => Divider(color: Colors.grey[200]),
                                      itemBuilder: (context, index) {
                                        final permission = (roles[selectedRoleIndex]['permissions'] as Map).entries.elementAt(index);
                                        return SwitchListTile(
                                          title: Text(
                                            permission.key,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          value: permission.value as bool,
                                          activeColor: Theme.of(context).primaryColor,
                                          onChanged: (value) {
                                            setState(() {
                                              (roles[selectedRoleIndex]['permissions'] as Map)[permission.key] = value;
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Kullanıcılar section
                                  Text(
                                    'Bu Roldeki Kullanıcılar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Users count and view button
                                  Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Colors.grey[200]!),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${roles[selectedRoleIndex]["users"]} kullanıcı bu role sahip',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            icon: const Icon(Icons.people),
                                            label: const Text('Kullanıcıları Görüntüle'),
                                            onPressed: () {
                                              // View users with this role
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Kullanıcı yönetimi yapım aşamasında'),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Footer section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            label: const Text('Rolü Sil', style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              // Delete role logic
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rol silme özelliği yapım aşamasında'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('İptal'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // Save changes logic
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Değişiklikler kaydedildi'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Kaydet'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // New method for Notifications dialog
  Future<void> _showNotificationsDialog(BuildContext context) async {
    // Notification settings data
    Map<String, bool> emailNotifications = {
      'Yeni araç eklendi': true,
      'Araç bakım zamanı': true,
      'Günlük rapor özeti': false,
      'Sistem güncellemeleri': true,
      'Güvenlik uyarıları': true,
    };
    
    Map<String, bool> appNotifications = {
      'Yeni araç eklendi': true,
      'Araç bakım zamanı': true,
      'Günlük rapor özeti': true,
      'Sistem güncellemeleri': false,
      'Güvenlik uyarıları': true,
    };
    
    Map<String, bool> smsNotifications = {
      'Yeni araç eklendi': false,
      'Araç bakım zamanı': true,
      'Günlük rapor özeti': false,
      'Sistem güncellemeleri': false,
      'Güvenlik uyarıları': true,
    };
    
    // Selected notification channel
    String selectedChannel = 'Email';
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: 900,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bildirim Ayarları',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    
                    // Content section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Global notification toggle
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.notifications_active,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Tüm Bildirimleri Etkinleştir',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Bu ayarı kapatırsanız, tüm bildirimler devre dışı kalır',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: true,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) {
                                      // Toggle all notifications
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            value
                                                ? 'Tüm bildirimler etkinleştirildi'
                                                : 'Tüm bildirimler devre dışı bırakıldı'
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      // setState(() {
                                      //   // Update all notification settings
                                      // });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Notification channels selection
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => selectedChannel = 'Email'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: selectedChannel == 'Email'
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[100],
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          bottomLeft: Radius.circular(8),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.email,
                                            color: selectedChannel == 'Email'
                                                ? Colors.white
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Email',
                                            style: TextStyle(
                                              color: selectedChannel == 'Email'
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                              fontWeight: selectedChannel == 'Email'
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => selectedChannel = 'Uygulama'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      color: selectedChannel == 'Uygulama'
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[100],
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.app_settings_alt,
                                            color: selectedChannel == 'Uygulama'
                                                ? Colors.white
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Uygulama',
                                            style: TextStyle(
                                              color: selectedChannel == 'Uygulama'
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                              fontWeight: selectedChannel == 'Uygulama'
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => selectedChannel = 'SMS'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: selectedChannel == 'SMS'
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[100],
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.sms,
                                            color: selectedChannel == 'SMS'
                                                ? Colors.white
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'SMS',
                                            style: TextStyle(
                                              color: selectedChannel == 'SMS'
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                              fontWeight: selectedChannel == 'SMS'
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Channel notification settings
                            Expanded(
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '$selectedChannel Bildirimleri',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                          TextButton.icon(
                                            icon: const Icon(Icons.notifications_off),
                                            label: const Text('Tümünü Kapat'),
                                            onPressed: () {
                                              // Disable all notifications for this channel
                                              Map<String, bool>? notifications;
                                              
                                              if (selectedChannel == 'Email') {
                                                notifications = emailNotifications;
                                              } else if (selectedChannel == 'Uygulama') {
                                                notifications = appNotifications;
                                              } else if (selectedChannel == 'SMS') {
                                                notifications = smsNotifications;
                                              }
                                              
                                              if (notifications != null) {
                                                setState(() {
                                                  for (var key in notifications!.keys) {
                                                    notifications[key] = false;
                                                  }
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const Divider(height: 1),
                                    
                                    Expanded(
                                      child: ListView.separated(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        itemCount: 5, // Using fixed count to match our maps
                                        separatorBuilder: (context, index) => Divider(color: Colors.grey[200]),
                                        itemBuilder: (context, index) {
                                          // Get the appropriate notifications map
                                          Map<String, bool>? notifications;
                                          if (selectedChannel == 'Email') {
                                            notifications = emailNotifications;
                                          } else if (selectedChannel == 'Uygulama') {
                                            notifications = appNotifications;
                                          } else if (selectedChannel == 'SMS') {
                                            notifications = smsNotifications;
                                          }
                                          
                                          if (notifications == null) return const SizedBox.shrink();
                                          
                                          final entry = notifications.entries.elementAt(index);
                                          final notificationType = entry.key;
                                          final isEnabled = entry.value;
                                          
                                          return SwitchListTile(
                                            title: Text(
                                              notificationType,
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            subtitle: Text(
                                              '$selectedChannel bildirimleri ${isEnabled ? 'açık' : 'kapalı'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            value: isEnabled,
                                            activeColor: Theme.of(context).primaryColor,
                                            onChanged: (value) {
                                              setState(() {
                                                notifications![notificationType] = value;
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Footer section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('İptal'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Save notification settings
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bildirim ayarları kaydedildi'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Navigator.of(context).pop();
                            },
                            child: const Text('Kaydet'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // New method for User Management dialog (replacing Backup and Recovery)
  Future<void> _showBackupDialog(BuildContext context) async {
    // Sample user data
    final List<Map<String, dynamic>> users = [
      {
        'id': '1',
        'username': 'admin',
        'fullName': 'Admin Kullanıcı',
        'email': 'admin@example.com',
        'role': 'Yönetici',
        'status': 'Aktif',
        'lastLogin': '12 Oca 2023 08:30',
      },
      {
        'id': '2',
        'username': 'manager1',
        'fullName': 'Ahmet Yılmaz',
        'email': 'ahmet@example.com',
        'role': 'Müdür',
        'status': 'Aktif',
        'lastLogin': '10 Oca 2023 09:15',
      },
      {
        'id': '3',
        'username': 'operator1',
        'fullName': 'Mehmet Demir',
        'email': 'mehmet@example.com',
        'role': 'Operatör',
        'status': 'Aktif',
        'lastLogin': '11 Oca 2023 10:30',
      },
      {
        'id': '4',
        'username': 'guest1',
        'fullName': 'Ayşe Kaya',
        'email': 'ayse@example.com',
        'role': 'Misafir',
        'status': 'Pasif',
        'lastLogin': '02 Oca 2023 14:45',
      },
    ];
    
    // Form controllers for new user
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController fullNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    
    // Form state variables
    String selectedRole = 'Operatör';
    bool showPassword = false;
    int? selectedUserIndex;
    bool isAddingNewUser = false;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: 900,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kullanıcı Yönetimi',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    
                    // Content section
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side - User list
                          Container(
                            width: 300,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Kullanıcılar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle),
                                        tooltip: 'Yeni Kullanıcı Ekle',
                                        color: Colors.green,
                                        onPressed: () {
                                          setState(() {
                                            // Reset form fields
                                            usernameController.clear();
                                            fullNameController.clear();
                                            emailController.clear();
                                            passwordController.clear();
                                            confirmPasswordController.clear();
                                            selectedRole = 'Operatör';
                                            selectedUserIndex = null;
                                            isAddingNewUser = true;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Kullanıcı ara...',
                                      prefixIcon: const Icon(Icons.search, size: 20),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                                const Divider(height: 1),
                                
                                // Users list
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: users.length,
                                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                                    itemBuilder: (context, index) {
                                      final user = users[index];
                                      final isSelected = selectedUserIndex == index;
                                      final isActive = user['status'] == 'Aktif';
                                      
                                      return ListTile(
                                        selected: isSelected,
                                        selectedColor: Theme.of(context).primaryColor,
                                        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                        title: Text(
                                          user['username'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? null : (isActive ? null : Colors.grey),
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${user["role"]} • ${isActive ? "Aktif" : "Pasif"}',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: isSelected
                                              ? Theme.of(context).primaryColor
                                              : (isActive ? Colors.grey[200] : Colors.grey[100]),
                                          foregroundColor: isSelected
                                              ? Colors.white
                                              : (isActive ? Colors.grey[800] : Colors.grey[400]),
                                          child: Text(
                                            (user['fullName'] as String)[0],
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            selectedUserIndex = index;
                                            isAddingNewUser = false;
                                            
                                            // Pre-fill form fields with selected user data
                                            usernameController.text = user['username'] as String;
                                            fullNameController.text = user['fullName'] as String;
                                            emailController.text = user['email'] as String;
                                            passwordController.clear(); // Don't show password
                                            confirmPasswordController.clear();
                                            selectedRole = user['role'] as String;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Right side - User form
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: selectedUserIndex != null || isAddingNewUser
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Form header
                                        Text(
                                          isAddingNewUser ? 'Yeni Kullanıcı Ekle' : 'Kullanıcı Düzenle',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        
                                        // User form
                                        Expanded(
                                          child: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Username field
                                                Text(
                                                  'Kullanıcı Adı',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextField(
                                                  controller: usernameController,
                                                  decoration: InputDecoration(
                                                    hintText: 'Kullanıcı adını girin',
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                
                                                // Full name field
                                                Text(
                                                  'Ad Soyad',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextField(
                                                  controller: fullNameController,
                                                  decoration: InputDecoration(
                                                    hintText: 'Ad soyadı girin',
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                
                                                // Email field
                                                Text(
                                                  'E-posta',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextField(
                                                  controller: emailController,
                                                  keyboardType: TextInputType.emailAddress,
                                                  decoration: InputDecoration(
                                                    hintText: 'E-posta adresini girin',
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                
                                                // Password field
                                                if (isAddingNewUser) ...[
                                                  Text(
                                                    'Şifre',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextField(
                                                    controller: passwordController,
                                                    obscureText: !showPassword,
                                                    decoration: InputDecoration(
                                                      hintText: 'Şifre girin',
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                                      ),
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                      suffixIcon: IconButton(
                                                        icon: Icon(
                                                          showPassword ? Icons.visibility_off : Icons.visibility,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            showPassword = !showPassword;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  
                                                  // Confirm password field
                                                  Text(
                                                    'Şifre Onayı',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextField(
                                                    controller: confirmPasswordController,
                                                    obscureText: !showPassword,
                                                    decoration: InputDecoration(
                                                      hintText: 'Şifreyi tekrar girin',
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                                      ),
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                ],
                                                
                                                // Change password button (for editing users)
                                                if (!isAddingNewUser)
                                                  OutlinedButton.icon(
                                                    icon: const Icon(Icons.lock_reset),
                                                    label: const Text('Şifre Değiştir'),
                                                    onPressed: () {
                                                      // Show password change dialog
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: const Text('Şifre Değiştir'),
                                                          content: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              TextField(
                                                                obscureText: true,
                                                                decoration: InputDecoration(
                                                                  labelText: 'Yeni Şifre',
                                                                  border: OutlineInputBorder(
                                                                    borderRadius: BorderRadius.circular(8),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(height: 16),
                                                              TextField(
                                                                obscureText: true,
                                                                decoration: InputDecoration(
                                                                  labelText: 'Şifre Onayı',
                                                                  border: OutlineInputBorder(
                                                                    borderRadius: BorderRadius.circular(8),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context),
                                                              child: const Text('İptal'),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () {
                                                                Navigator.pop(context);
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  const SnackBar(
                                                                    content: Text('Şifre başarıyla değiştirildi'),
                                                                    behavior: SnackBarBehavior.floating,
                                                                  ),
                                                                );
                                                              },
                                                              child: const Text('Kaydet'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                if (!isAddingNewUser)
                                                  const SizedBox(height: 16),
                                                
                                                // Role selection
                                                Text(
                                                  'Kullanıcı Rolü',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                DropdownButtonFormField<String>(
                                                  value: selectedRole,
                                                  decoration: InputDecoration(
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  ),
                                                  items: const [
                                                    DropdownMenuItem(value: 'Yönetici', child: Text('Yönetici')),
                                                    DropdownMenuItem(value: 'Müdür', child: Text('Müdür')),
                                                    DropdownMenuItem(value: 'Operatör', child: Text('Operatör')),
                                                    DropdownMenuItem(value: 'Misafir', child: Text('Misafir')),
                                                  ],
                                                  onChanged: (value) {
                                                    if (value != null) {
                                                      setState(() {
                                                        selectedRole = value;
                                                      });
                                                    }
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                                
                                                // Status toggle (for existing users)
                                                if (!isAddingNewUser)
                                                  SwitchListTile(
                                                    title: const Text('Kullanıcı Durumu'),
                                                    subtitle: const Text('Kullanıcının aktif veya pasif olmasını ayarlayın'),
                                                    value: users[selectedUserIndex!]['status'] == 'Aktif',
                                                    activeColor: Theme.of(context).primaryColor,
                                                    contentPadding: EdgeInsets.zero,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      side: BorderSide(color: Colors.grey[300]!),
                                                    ),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        users[selectedUserIndex!]['status'] = value ? 'Aktif' : 'Pasif';
                                                      });
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.person_add, size: 64, color: Colors.grey[300]),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Kullanıcı eklemek veya düzenlemek için\nkullanıcı seçin veya "Yeni Kullanıcı Ekle" düğmesine tıklayın',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.add),
                                            label: const Text('Yeni Kullanıcı Ekle'),
                                            onPressed: () {
                                              setState(() {
                                                usernameController.clear();
                                                fullNameController.clear();
                                                emailController.clear();
                                                passwordController.clear();
                                                confirmPasswordController.clear();
                                                selectedRole = 'Operatör';
                                                selectedUserIndex = null;
                                                isAddingNewUser = true;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Footer section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Delete button (only for existing users)
                          if (selectedUserIndex != null && !isAddingNewUser)
                            TextButton.icon(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              label: const Text('Kullanıcıyı Sil', style: TextStyle(color: Colors.red)),
                              onPressed: () {
                                // Show delete confirmation dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Kullanıcıyı Sil'),
                                    content: Text('${users[selectedUserIndex!]['username']} kullanıcısını silmek istediğinizden emin misiniz?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('İptal'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            users.removeAt(selectedUserIndex!);
                                            selectedUserIndex = null;
                                            isAddingNewUser = false;
                                          });
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Kullanıcı başarıyla silindi'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        child: const Text('Sil'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          else
                            const SizedBox(), // Empty space for alignment
                          
                          // Cancel and Save buttons
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  if (isAddingNewUser || selectedUserIndex != null) {
                                    // Cancel editing and return to selection state
                                    setState(() {
                                      selectedUserIndex = null;
                                      isAddingNewUser = false;
                                    });
                                  } else {
                                    // Close dialog
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: const Text('İptal'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: (isAddingNewUser || selectedUserIndex != null) ? () {
                                  // Validate form
                                  if (usernameController.text.isEmpty || 
                                      fullNameController.text.isEmpty || 
                                      emailController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Lütfen tüm alanları doldurun'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  // Validate password if adding new user
                                  if (isAddingNewUser) {
                                    if (passwordController.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Lütfen bir şifre girin'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    
                                    if (passwordController.text != confirmPasswordController.text) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Şifreler eşleşmiyor'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                  
                                  // Save user data
                                  if (isAddingNewUser) {
                                    setState(() {
                                      users.add({
                                        'id': (users.length + 1).toString(),
                                        'username': usernameController.text,
                                        'fullName': fullNameController.text,
                                        'email': emailController.text,
                                        'role': selectedRole,
                                        'status': 'Aktif',
                                        'lastLogin': 'Henüz giriş yapmadı',
                                      });
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Kullanıcı başarıyla eklendi'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      
                                      // Reset state
                                      selectedUserIndex = null;
                                      isAddingNewUser = false;
                                    });
                                  } else if (selectedUserIndex != null) {
                                    setState(() {
                                      users[selectedUserIndex!]['username'] = usernameController.text;
                                      users[selectedUserIndex!]['fullName'] = fullNameController.text;
                                      users[selectedUserIndex!]['email'] = emailController.text;
                                      users[selectedUserIndex!]['role'] = selectedRole;
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Kullanıcı bilgileri güncellendi'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      
                                      // Reset state
                                      selectedUserIndex = null;
                                      isAddingNewUser = false;
                                    });
                                  }
                                } : null, // Disable button if no user selected/being added
                                child: Text(isAddingNewUser ? 'Ekle' : (selectedUserIndex != null ? 'Kaydet' : 'Kapat')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
    
    // Clean up controllers
    usernameController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }
}