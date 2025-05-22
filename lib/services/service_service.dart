import '../models/service_entry.dart';
class ServiceService {
 final List<ServiceEntry> _list = [];
 List<ServiceEntry> getAll() => List.unmodifiable(_list);
 void add(ServiceEntry s) => _list.add(s);
 void update(ServiceEntry s) {
   final i = _list.indexWhere((x) => x.id == s.id);
   if (i >= 0) _list[i] = s;
 }
 
 void remove(String id) {
   _list.removeWhere((x) => x.id == id);
 }
}