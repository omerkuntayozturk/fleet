class Vehicle {
  final String id;
  String model;
  String plate;
  int? year;  // Add year property as nullable int

  Vehicle({
    required this.id,
    required this.model, 
    required this.plate,
    this.year,  // Make it optional in the constructor
  });
}