import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_provider.dart';
import '../models/medicine_inventory.dart';

class MedicineTrackerScreen extends StatelessWidget {
  const MedicineTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final inventory = provider.inventory;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medicine Tracker"),
      ),
      body: inventory.isEmpty
          ? const Center(
              child: Text(
                "No medicines tracked.\nAdd one below!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: inventory.length,
              itemBuilder: (context, index) {
                final item = inventory[index];
                final isLow = item.isLowStock;

                return Card(
                  elevation: 2,
                  color: isLow ? Colors.red.shade50 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isLow ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          "Stock: ${item.currentStock}",
                          style: TextStyle(
                            fontSize: 22,
                            color: isLow ? Colors.red : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isLow ? "Low Stock! Refill soon." : "${item.daysLeft} days left (approx)",
                          style: TextStyle(
                            fontSize: 20,
                            color: isLow ? Colors.red.shade700 : Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                            fontStyle: isLow ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 28),
                          onPressed: () {
                            _showEditStockDialog(context, provider, item);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey, size: 28),
                          onPressed: () {
                             provider.deleteInventoryItem(item.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddMedicineDialog(context, provider);
        },
        label: const Text("Add Medicine"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal.shade400,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddMedicineDialog(BuildContext context, AppProvider provider) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController stockCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Track New Medicine"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Medicine Name",
                hintText: "e.g. Paracetamol",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Current Stock (Total Pills)",
                hintText: "e.g. 30",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && stockCtrl.text.isNotEmpty) {
                final int? stock = int.tryParse(stockCtrl.text);
                if (stock != null) {
                  provider.addInventoryItem(nameCtrl.text, stock);
                  Navigator.pop(context);
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showEditStockDialog(BuildContext context, AppProvider provider, MedicineInventory item) {
    final TextEditingController stockCtrl = TextEditingController(text: item.currentStock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update Stock: ${item.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter the new total quantity."),
            const SizedBox(height: 12),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Total Stock",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (stockCtrl.text.isNotEmpty) {
                final int? stock = int.tryParse(stockCtrl.text);
                if (stock != null) {
                  provider.updateInventoryStock(item.id, stock);
                  Navigator.pop(context);
                }
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}
