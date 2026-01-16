class MedicineInventory {
  final String id;
  final String name;
  final int currentStock;
  final int dosagePerDay;
  final int lowStockThreshold;

  MedicineInventory({
    required this.id,
    required this.name,
    required this.currentStock,
    this.dosagePerDay = 1,
    int? lowStockThreshold,
  }) : lowStockThreshold = lowStockThreshold ?? (dosagePerDay * 4);

  // Computed: Days Left
  int get daysLeft => (currentStock / dosagePerDay).floor();
  
  bool get isLowStock => currentStock <= lowStockThreshold;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currentStock': currentStock,
      'dosagePerDay': dosagePerDay,
      'lowStockThreshold': lowStockThreshold,
    };
  }

  factory MedicineInventory.fromJson(Map<String, dynamic> json) {
    return MedicineInventory(
      id: json['id'],
      name: json['name'],
      currentStock: json['currentStock'] ?? 0,
      dosagePerDay: json['dosagePerDay'] ?? 1,
      lowStockThreshold: json['lowStockThreshold'],
    );
  }

  MedicineInventory copyWith({
    String? id,
    String? name,
    int? currentStock,
    int? dosagePerDay,
    int? lowStockThreshold,
  }) {
    return MedicineInventory(
      id: id ?? this.id,
      name: name ?? this.name,
      currentStock: currentStock ?? this.currentStock,
      dosagePerDay: dosagePerDay ?? this.dosagePerDay,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }
}
