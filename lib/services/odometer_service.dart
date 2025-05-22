import '../models/odometer_record.dart';

class OdometerService {
 final List<OdometerRecord> _list = [];
 List<OdometerRecord> getAll() => List.unmodifiable(_list);
 void add(OdometerRecord o) => _list.add(o);
 
 void update(OdometerRecord o) {
   final index = _list.indexWhere((record) => record.id == o.id);
   if (index != -1) {
     _list[index] = o;
   }
 }

 void remove(String id) {
   _list.removeWhere((record) => record.id == id);
 }
}