import '../core/enums.dart';
class ServiceEntry {
 String id, vehicleId, serviceType, supplier, driver;
 DateTime date;
 double cost, odometer;
 ServiceStage stage;
 ServiceEntry({
   required this.id,
   required this.vehicleId,
   this.serviceType = '',
   this.supplier = '',
   this.driver = '',
   required this.date,
   this.cost = 0,
   this.odometer = 0,
   this.stage = ServiceStage.newService,
 });
}