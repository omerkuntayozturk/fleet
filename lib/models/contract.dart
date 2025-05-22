import '../core/enums.dart';
class Contract {
 String id, vehicleId, reference, supplier;
 DateTime startDate, endDate;
 ContractStage stage;
 Contract({
   required this.id,
   required this.vehicleId,
   this.reference = '',
   this.supplier = '',
   required this.startDate,
   required this.endDate,
   this.stage = ContractStage.newContract,
 });
}