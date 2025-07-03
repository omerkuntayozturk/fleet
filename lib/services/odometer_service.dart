import '../models/odometer_record.dart';

class OdometerService {
  final List<OdometerRecord> _records = [];
  
  List<OdometerRecord> getAll() => List.unmodifiable(_records);
  
  void add(OdometerRecord record) => _records.add(record);
  
  void update(OdometerRecord record) {
    final i = _records.indexWhere((r) => r.id == record.id);
    if (i >= 0) _records[i] = record;
  }
  
  void remove(String id) {
    _records.removeWhere((r) => r.id == id);
  }
  
  OdometerRecord? getById(String id) {
    try {
      return _records.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }
  
  List<OdometerRecord> getByVehicleId(String vehicleId) {
    return _records.where((r) => r.vehicleId == vehicleId).toList();
  }
}