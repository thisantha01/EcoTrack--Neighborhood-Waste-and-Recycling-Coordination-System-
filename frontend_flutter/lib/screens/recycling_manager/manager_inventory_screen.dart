import 'package:flutter/material.dart';

class ManagerInventoryScreen extends StatelessWidget {
  const ManagerInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: const Text('Recycling Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: _metric('Total stock', '2,480 kg', Icons.inventory_2_outlined, const Color(0xFF0097A7))),
            const SizedBox(width: 10),
            Expanded(child: _metric('Ready to sell', '1,120 kg', Icons.local_shipping_outlined, const Color(0xFF2E9B72))),
          ]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Material inventory', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0097A7)), tooltip: 'Add material'),
          ]),
          const SizedBox(height: 8),
          _inventoryTile('Plastic', '840 kg', 0.78, const Color(0xFF2E9B72)),
          _inventoryTile('Paper', '620 kg', 0.56, const Color(0xFF4D8CC9)),
          _inventoryTile('Glass', '510 kg', 0.42, const Color(0xFFDE9B3C)),
          _inventoryTile('Metal', '390 kg', 0.31, const Color(0xFFE46B56)),
          _inventoryTile('Organic compost', '120 kg', 0.18, const Color(0xFF8066B3)),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ]),
    );
  }

  Widget _inventoryTile(String title, String quantity, double progress, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(quantity, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: progress, minHeight: 8, color: color, backgroundColor: color.withValues(alpha: 0.12)),
        ),
      ]),
    );
  }
}
