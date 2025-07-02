import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fleet/core/enums.dart';
import 'package:easy_localization/easy_localization.dart'; // easy_localization import
import '../../../widgets/top_bar.dart';
import '../../../widgets/side_menu.dart';
import '../../../services/employee_service.dart';
import '../../../models/employee.dart';
import 'import_list.dart'; // Import for the import/export functionality
import 'add_list.dart'; // Add this import for the add employee functionality
import '../../../info_card.dart'; // Import InfoCard

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});
  @override State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> with SingleTickerProviderStateMixin {
  final EmployeeService _employeeService = EmployeeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();

  // Add variables for responsive design
  late bool _isSmallScreen;
  late bool _isMediumScreen;

  // Add pagination variables
  int _currentPage = 1;
  int _pageSize = 5;
  int _totalPages = 1;
  int _totalEmployees = 0;
  List<Employee> _allEmployees = [];
  List<Employee> _displayedEmployees = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();


    _initializeData();

    _searchController.addListener(() {
      _filterEmployees(_searchController.text);
    });
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = tr('user_session_not_found');
          _isLoading = false;
        });
        return;
      }

      await _loadEmployees();
    } catch (e) {
      setState(() {
        _errorMessage = tr('data_loading_error', args: [e.toString()]);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _employeeService.getAll();
      setState(() {
        _allEmployees = employees;
        _totalEmployees = employees.length;
        _totalPages = (_totalEmployees / _pageSize).ceil();
        if (_totalPages == 0) _totalPages = 1;
        _isLoading = false;
      });
      _updateDisplayedEmployees();
    } catch (e) {
      setState(() {
        _errorMessage = tr('employee_loading_error', args: [e.toString()]);
        _isLoading = false;
      });
    }
  }

  void _setScreenSizeBreakpoints(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _isSmallScreen = screenWidth < 650;
    _isMediumScreen = screenWidth >= 650 && screenWidth < 1024;
  }

  void _updateDisplayedEmployees() {
    setState(() {
      int startIndex = (_currentPage - 1) * _pageSize;
      int endIndex = startIndex + _pageSize;
      if (endIndex > _allEmployees.length) endIndex = _allEmployees.length;
      if (startIndex >= _allEmployees.length) {
        _displayedEmployees = [];
      } else {
        _displayedEmployees = _allEmployees.sublist(startIndex, endIndex);
      }
      _filteredEmployees = _displayedEmployees;
    });
  }

  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _displayedEmployees;
      } else {
        final lowercaseQuery = query.toLowerCase();
        _filteredEmployees = _allEmployees.where((employee) =>
          employee.name.toLowerCase().contains(lowercaseQuery) ||
          (employee.email?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (employee.phone?.toLowerCase().contains(lowercaseQuery) ?? false)
        ).toList();
      }
    });
  }

  void _changePage(int page) {
    setState(() {
      _currentPage = page;
      _searchController.clear();
    });
    _updateDisplayedEmployees();
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

  void _importEmployees(BuildContext context) {
    EmployeeImportExport.importEmployees(context, () {
      _initializeData();
    });
  }

  void _exportEmployees(BuildContext context) {
    EmployeeImportExport.exportEmployees(context, _allEmployees);
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
      drawer: const SideMenu(currentPage: 'list',),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(_isSmallScreen ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with title and search
              _buildHeaderSection(context),
              
              SizedBox(height: _isSmallScreen ? 24 : 32),
              
              // Employees list section
              _buildEmployeesSection(context),
            ],
          ),
        ),
      ),
      floatingActionButton: _isSmallScreen ? _buildModernFAB(context) : null,
    );
  }

  // Modern floating action button for mobile view (same as employee_contracts_page)
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
          onTap: () {
            EmployeeManagement.addNewEmployee(context, _initializeData);
          },
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
              tr('employee_list_title'),
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
              tr('employee_list_subtitle'),
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
                hintText: tr('dashboard_search_placeholder'),
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
          // Import/Export buttons are hidden on small screens
        ],
      );
    } else if (_isMediumScreen) {
      // Medium screens - simplified layout with fewer buttons
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
                      tr('employee_list_title'),
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
                      tr('employee_list_subtitle'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                ],
              ),
              // Add new employee button
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(tr('add_new_employee')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  EmployeeManagement.addNewEmployee(context, _initializeData);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search and import/export buttons
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
                      hintText: tr('dashboard_search_placeholder'),
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
              // Import button
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: Text(tr('import')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => _importEmployees(context),
              ),
              const SizedBox(width: 12),
              // Export button
              OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: Text(tr('export')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => _exportEmployees(context),
              ),
            ],
          ),
        ],
      );
    } else {
      // Large screens - show all buttons and full layout
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
                      tr('employee_list_title'),
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
                      tr('employee_list_subtitle'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Import employees button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: Text(tr('import')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => _importEmployees(context),
                  ),
                  const SizedBox(width: 16),
                  // Export employees button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: Text(tr('export')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => _exportEmployees(context),
                  ),
                  const SizedBox(width: 16),
                  // Add new employee button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(tr('add_new_employee')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      EmployeeManagement.addNewEmployee(context, _initializeData);
                    },
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
                          hintText: tr('dashboard_search_placeholder'),
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
          ),
        ],
      );
    }
  }

  Widget _buildEmployeesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('employee_list_title'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _isLoading 
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[800]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _initializeData,
                            icon: const Icon(Icons.refresh),
                            label: Text(tr('try_again')),
                          ),
                        ],
                      ),
                    ),
                  )
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
                          // Table Header (ad, e-posta, telefon, durum)
                          if (!_isSmallScreen)
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
                                      tr('full_name'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      tr('email'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      tr('phone'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      tr('status'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(width: 100),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),

                          // Employee Rows
                          if (_filteredEmployees.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.person_off,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      tr('employee_not_found'),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (_isSmallScreen)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredEmployees.length,
                              itemBuilder: (context, index) {
                                final employee = _filteredEmployees[index];
                                Color statusColor;
                                String statusText;
                                switch (employee.status) {
                                  case EmploymentStatus.active:
                                    statusText = tr('active');
                                    statusColor = Colors.green;
                                    break;
                                  case EmploymentStatus.onLeave:
                                    statusText = tr('on_leave');
                                    statusColor = Colors.orange;
                                    break;
                                  case EmploymentStatus.terminated:
                                    statusText = tr('terminated');
                                    statusColor = Colors.red;
                                    break;
                                  case EmploymentStatus.resigned:
                                    statusText = tr('resigned');
                                    statusColor = Colors.red[300]!;
                                    break;
                                  default:
                                    statusText = tr('active');
                                    statusColor = Colors.green;
                                    break;
                                }
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[200]!),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey[50],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Colors.grey[200],
                                              backgroundImage: employee.imageUrl != null && employee.imageUrl!.isNotEmpty
                                                  ? NetworkImage(employee.imageUrl!)
                                                  : null,
                                              child: employee.imageUrl == null || employee.imageUrl!.isEmpty
                                                  ? Text(
                                                      employee.name.isNotEmpty
                                                          ? employee.name[0].toUpperCase()
                                                          : '?',
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                employee.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                statusText,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.email, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                employee.email?.isNotEmpty == true
                                                    ? employee.email!
                                                    : tr('dash'),
                                                style: TextStyle(
                                                  color: employee.email?.isNotEmpty == true
                                                      ? Colors.grey[800]
                                                      : Colors.grey[400],
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                employee.phone?.isNotEmpty == true
                                                    ? employee.phone!
                                                    : tr('dash'),
                                                style: TextStyle(
                                                  color: employee.phone?.isNotEmpty == true
                                                      ? Colors.grey[800]
                                                      : Colors.grey[400],
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit_outlined, color: Colors.blue[600], size: 20),
                                              tooltip: tr('edit'),
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.all(8),
                                              onPressed: () => _editEmployee(employee),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline, color: Colors.red[600], size: 20),
                                              tooltip: tr('delete'),
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.all(8),
                                              onPressed: () => _deleteEmployee(employee),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredEmployees.length,
                              itemBuilder: (context, index) {
                                final employee = _filteredEmployees[index];
                                Color statusColor;
                                String statusText;
                                switch (employee.status) {
                                  case EmploymentStatus.active:
                                    statusText = tr('active');
                                    statusColor = Colors.green;
                                    break;
                                  case EmploymentStatus.onLeave:
                                    statusText = tr('on_leave');
                                    statusColor = Colors.orange;
                                    break;
                                  case EmploymentStatus.terminated:
                                    statusText = tr('terminated');
                                    statusColor = Colors.red;
                                    break;
                                  case EmploymentStatus.resigned:
                                    statusText = tr('resigned');
                                    statusColor = Colors.red[300]!;
                                    break;
                                  default:
                                    statusText = tr('active');
                                    statusColor = Colors.green;
                                    break;
                                }
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[200]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {},
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: Colors.grey[200],
                                                  backgroundImage: employee.imageUrl != null && employee.imageUrl!.isNotEmpty
                                                      ? NetworkImage(employee.imageUrl!)
                                                      : null,
                                                  child: employee.imageUrl == null || employee.imageUrl!.isEmpty
                                                      ? Text(
                                                          employee.name.isNotEmpty
                                                              ? employee.name[0].toUpperCase()
                                                              : '?',
                                                          style: const TextStyle(
                                                            color: Colors.grey,
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    employee.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              employee.email?.isNotEmpty == true
                                                  ? employee.email!
                                                  : tr('dash'),
                                              style: TextStyle(
                                                color: employee.email?.isNotEmpty == true
                                                    ? Colors.grey[800]
                                                    : Colors.grey[400],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.phone,
                                                  size: 16,
                                                  color: Colors.grey[400],
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    employee.phone?.isNotEmpty == true 
                                                        ? employee.phone!
                                                        : tr('dash'),
                                                    style: TextStyle(
                                                      color: employee.phone?.isNotEmpty == true
                                                          ? Colors.grey[800]
                                                          : Colors.grey[400],
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                statusText,
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
                                            width: 100,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.edit_outlined, color: Colors.blue[600], size: 20),
                                                  tooltip: tr('edit'),
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                  onPressed: () => _editEmployee(employee),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete_outline, color: Colors.red[600], size: 20),
                                                  tooltip: tr('delete'),
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                  onPressed: () => _deleteEmployee(employee),
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
            tooltip: tr('previous_page'),
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
            tooltip: tr('next_page'),
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
            tr('total_employees_count', args: ['$_totalEmployees']),
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
                tooltip: tr('previous_page'),
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
                tooltip: tr('next_page'),
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
            tr('total_employees_count', args: ['$_totalEmployees']),
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
                tooltip: tr('first_page'),
                splashRadius: 20,
                color: _currentPage > 1 ? Colors.blue : Colors.grey,
              ),
              
              // Previous page button
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? _previousPage : null,
                tooltip: tr('previous_page'),
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
                tooltip: tr('next_page'),
                splashRadius: 20,
                color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
              ),
              
              // Last page button
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < _totalPages ? () => _changePage(_totalPages) : null,
                tooltip: tr('last_page'),
                splashRadius: 20,
                color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
              ),
              
              // Page size selector
              const SizedBox(width: 16),
              Text(tr('per_page'), style: TextStyle(color: Colors.grey[700])),
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
                        _totalPages = (_totalEmployees / _pageSize).ceil();
                        if (_totalPages == 0) {
                          _totalPages = 1;
                        }
                        _currentPage = 1; // Reset to first page
                      });
                      _updateDisplayedEmployees();
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
  
  // Employee actions
  void _editEmployee(Employee employee) {
    EmployeeManagement.addNewEmployee(
      context, 
      () {
        _initializeData();
        if (!mounted) return;
        InfoCard.showInfoCard(
          context,
          tr('employee_updated', args: [employee.name]),
          Colors.green,
          icon: Icons.check_circle,
        );
      },
      editEmployee: employee,
    );
  }

  void _deleteEmployee(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('delete_employee')),
        content: Text(tr('delete_employee_confirm', args: [employee.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });
              try {
                final user = _auth.currentUser;
                if (user != null) {
                  await _employeeService.delete(employee.id);
                  _initializeData();
                  if (!mounted) return;
                  InfoCard.showInfoCard(
                    context,
                    tr('employee_deleted', args: [employee.name]),
                    Colors.red,
                    icon: Icons.delete_forever,
                  );
                }
              } catch (e) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = tr('employee_delete_error', args: [e.toString()]);
                });
                if (!mounted) return;
                InfoCard.showInfoCard(
                  context,
                  tr('error_with_message', args: [e.toString()]),
                  Colors.red,
                  icon: Icons.error,
                );
              }
            },
            child: Text(tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}