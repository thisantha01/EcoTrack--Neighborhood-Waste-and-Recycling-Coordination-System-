import 'package:flutter/material.dart';

class ManagerWasteScreen extends StatelessWidget {
  const ManagerWasteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: const Text('Waste Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryRow(),
          const SizedBox(height: 20),
          const Text('Waste categories', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _wasteTile('Plastic', '42 pending requests', Icons.recycling, const Color(0xFF2E9B72)),
          _wasteTile('Organic', '28 pending requests', Icons.eco_outlined, const Color(0xFFDE9B3C)),
          _wasteTile('Paper & cardboard', '19 pending requests', Icons.description_outlined, const Color(0xFF4D8CC9)),
          _wasteTile('Glass and metal', '11 pending requests', Icons.local_drink_outlined, const Color(0xFFE46B56)),
        ],
      ),
    );
  }

  Widget _summaryRow() {
    return Row(
      children: [
        Expanded(child: _metric('Collected', '1,250 kg', Icons.check_circle_outline, const Color(0xFF2E9B72))),
        const SizedBox(width: 10),
        Expanded(child: _metric('To process', '240 kg', Icons.pending_actions, const Color(0xFFDE9B3C))),
      ],
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

  Widget _wasteTile(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ])),
        Icon(Icons.chevron_right, color: Colors.grey.shade500),
      ]),
    );
  }
}
