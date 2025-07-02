import 'package:firebase_auth/firebase_auth.dart';
import '../models/employee.dart';
import 'firestore_service.dart';

class EmployeeService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<Employee> _employees = [];

  // Get all employees (refreshes from Firestore)
  Future<List<Employee>> getAll() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      final employeesData = await _firestoreService.fetchEmployees(
        userId: user.uid,
      );

      // Convert List<Map<String, dynamic>> to List<Employee>
      final employees = employeesData.map<Employee>((e) => Employee.fromJson(e, e['id'] as String)).toList();

      // Update local cache
      _employees.clear();
      _employees.addAll(employees);

      return List.from(_employees);
    } catch (e) {
      print('Error fetching employees: $e');
      // Return whatever we have in memory if there's an error
      return List.from(_employees);
    }
  }

  // Get employee by ID (from local cache)
  Employee? getById(String id) {
    try {
      return _employees.firstWhere((emp) => emp.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add an employee (updates both Firestore and local cache)
  Future<void> add(Employee employee) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    await _firestoreService.addEmployee(employee, user.uid);
    
    // Update local cache
    _employees.add(employee);
  }

  // Update an employee (updates both Firestore and local cache)
  Future<void> update(Employee employee) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    await _firestoreService.updateEmployee(employee, user.uid);
    
    // Update local cache
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index >= 0) {
      _employees[index] = employee;
    }
  }

  // Delete an employee (updates both Firestore and local cache)
  Future<void> delete(String id) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    await _firestoreService.deleteEmployee(id, user.uid);
    
    // Update local cache
    _employees.removeWhere((e) => e.id == id);
  }

  // Search employees by query string
  Future<List<Employee>> search(String query) async {
    if (query.isEmpty) {
      return getAll();
    }
    
    final lowerQuery = query.toLowerCase();
    return _employees.where((emp) => 
      emp.name.toLowerCase().contains(lowerQuery) ||
      (emp.email?.toLowerCase().contains(lowerQuery) ?? false) ||
      emp.position.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Get employees by department
  List<Employee> getByDepartment(String departmentId) {
    return _employees.where((emp) => emp.departmentId == departmentId).toList();
  }

  // Example export method (add or update as needed)
  List<Map<String, dynamic>> getEmployeesForExport() {
    final firestoreService = FirestoreService();
    return _employees.map((emp) => {
      'name': emp.name,
      'email': emp.email,
      'phone': emp.phone,
      'department': emp.departmentId,
      'position': emp.position,
      'status': firestoreService.employmentStatusToTurkish(emp.status),
    }).toList();
  }
}
