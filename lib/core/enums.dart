enum EmploymentStatus { active, onLeave, resigned, terminated }
enum ContractStatus {
  ongoing,      // Aktif - more than 2 months remaining
  endingSoon,   // Yakında Bitecek (2 Ay) - between 1-2 months remaining
  expiringSoon, // Yakında Bitecek (1 Ay) - less than 1 month remaining
  completed,    // Tamamlandı - manually completed
  terminated,   // Sözleşme Sona Erdi - end date has passed
}