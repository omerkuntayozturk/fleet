
enum ContractStage { newContract, active, expired }

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

  num? get durationInDays => null;
}