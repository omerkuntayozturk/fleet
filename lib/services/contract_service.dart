import '../models/contract.dart';
class ContractService {
 final List<Contract> _list = [];
 List<Contract> getAll() => List.unmodifiable(_list);
 void add(Contract c) => _list.add(c);
 void update(Contract c) {
   final i = _list.indexWhere((x) => x.id == c.id);
   if (i >= 0) _list[i] = c;
 }
 
 void remove(String id) {
   _list.removeWhere((x) => x.id == id);
 }
}