class Vehicle {
  final String id;
  final String model;
  final String plate;
  final int? year;  // Add year property as nullable int

  const Vehicle({
    required this.id,
    required this.model, 
    required this.plate,
    this.year,  // Make it optional in the constructor
  });
}