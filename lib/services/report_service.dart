import '../services/odometer_service.dart';

class ReportService {
 final _odom = OdometerService();
 /// Aylık toplam kilometre artışı
 Map<String, double> mileageTrend() {
   final m = <String, double>{};
   for (var r in _odom.getAll()) {
     final key = '${r.date.year}-${r.date.month}';
     m[key] = (m[key] ?? 0) + r.value;
   }
   return m;
 }
}