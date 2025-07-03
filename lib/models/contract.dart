enum ContractStatus { ongoing, expired, terminated, renewed }

class Contract {
  String id;
  String employeeId;
  String employeeName;
  String vehicleId; // <-- Eklendi
  String? vehiclePlate; // <-- PLATE eklendi
  String reference;
  DateTime startDate;
  DateTime endDate;
  ContractStatus status;
  DateTime createdAt;

  Contract({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.vehicleId, // <-- Eklendi
    this.vehiclePlate, // <-- PLATE eklendi
    this.reference = '',
    required this.startDate,
    required this.endDate,
    this.status = ContractStatus.ongoing,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  // Calculate duration in days
  int get durationInDays => endDate.difference(startDate).inDays;
  
  // Check if contract is active
  bool get isActive => status == ContractStatus.ongoing && 
                       DateTime.now().isBefore(endDate);
  
  // Get status as display text
  String get statusDisplayText {
    switch (status) {
      case ContractStatus.ongoing:
        return 'Devam Ediyor';
      case ContractStatus.expired:
        return 'Süresi Doldu';
      case ContractStatus.terminated:
        return 'Feshedildi';
      case ContractStatus.renewed:
        return 'Yenilendi';
      default:
        return 'Devam Ediyor';
    }
  }
}