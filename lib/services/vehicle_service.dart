import '../models/vehicle.dart';
class VehicleService {
 final List<Vehicle> _list = [];
 List<Vehicle> getAll() => List.unmodifiable(_list);
 void add(Vehicle v) => _list.add(v);
 void update(Vehicle v) {
   final i = _list.indexWhere((x) => x.id == v.id);
   if (i >= 0) _list[i] = v;
 }
}