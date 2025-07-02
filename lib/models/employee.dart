import '../core/enums.dart';

class Employee {
  String id, name, position;
  String? email, phone, imageUrl, positionId;
  EmploymentStatus status;
  String departmentId;
  DateTime? createdAt; // createdAt is nullable

  Employee({
    required this.id,
    required this.name,
    this.email,
    this.status = EmploymentStatus.active,
    required this.departmentId,
    required this.position,
    this.phone,
    this.imageUrl,
    this.positionId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Factory constructor for creating Employee instances from JSON data
  factory Employee.fromJson(Map<String, dynamic> json, String id) {
    return Employee(
      id: id,
      name: json['name'] ?? '',
      email: json['email'],
      status: _parseEmploymentStatus(json['status']),
      departmentId: json['departmentId'] ?? '',
      position: json['position'] ?? '',
      phone: json['phone'],
      imageUrl: json['imageUrl'],
      positionId: json['positionId'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
              ? DateTime.parse(json['createdAt'])
              : DateTime.fromMillisecondsSinceEpoch(json['createdAt']))
          : null,
    );
  }

  // Convert Employee instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'status': status.index,
      'departmentId': departmentId,
      'position': position,
      'phone': phone,
      'imageUrl': imageUrl,
      'positionId': positionId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Helper method to parse employment status
  static EmploymentStatus _parseEmploymentStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'active':
          return EmploymentStatus.active;
        case 'onleave':
          return EmploymentStatus.onLeave;
        case 'terminated':
          return EmploymentStatus.terminated;
        default:
          return EmploymentStatus.active;
      }
    } else if (status is int && status >= 0 && status < EmploymentStatus.values.length) {
      return EmploymentStatus.values[status];
    }
    return EmploymentStatus.active;
  }

  // Add copyWith method
  Employee copyWith({
    String? id,
    String? name,
    String? email,
    EmploymentStatus? status,
    String? departmentId,
    String? position,
    String? phone,
    String? imageUrl,
    String? positionId,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      status: status ?? this.status,
      departmentId: departmentId ?? this.departmentId,
      position: position ?? this.position,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      positionId: positionId ?? this.positionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}