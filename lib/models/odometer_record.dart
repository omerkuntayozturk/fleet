class OdometerRecord {
 String id, vehicleId, driver;
 DateTime date;
 double value;
 OdometerRecord({
   required this.id,
   required this.vehicleId,
   this.driver = '',
   required this.date,
   this.value = 0,
 });
}