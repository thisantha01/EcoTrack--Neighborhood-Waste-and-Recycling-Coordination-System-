import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/driver_provider.dart';
import 'widgets/driver_bottom_navigation_bar.dart';

class RecyclingWeighInScreen extends StatefulWidget {
  const RecyclingWeighInScreen({super.key, this.showBottomNavigationBar = true});
  final bool showBottomNavigationBar;

  @override
  State<RecyclingWeighInScreen> createState() => _RecyclingWeighInScreenState();
}

class _RecyclingWeighInScreenState extends State<RecyclingWeighInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _organic = TextEditingController(text: '0');
  final _plasticPaper = TextEditingController(text: '0');
  final _glassOthers = TextEditingController(text: '0');
  final _notes = TextEditingController();
  String? _routeId;
  bool _saving = false;

  @override
  void dispose() {
    _organic.dispose();
    _plasticPaper.dispose();
    _glassOthers.dispose();
    _notes.dispose();
    super.dispose();
  }

  double get _total =>
      (double.tryParse(_organic.text) ?? 0) +
      (double.tryParse(_plasticPaper.text) ?? 0) +
      (double.tryParse(_glassOthers.text) ?? 0);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<DriverProvider>().submitWeighIn(
            routeId: _routeId,
            weightsKg: {
              'organic': double.parse(_organic.text),
              'plasticPaper': double.parse(_plasticPaper.text),
              'glassOthers': double.parse(_glassOthers.text),
            },
            notes: _notes.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weights saved successfully')),
      );
      _organic.text = _plasticPaper.text = _glassOthers.text = '0';
      _notes.clear();
      setState(() => _routeId = null);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save weights. Check your connection and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routes = context.watch<DriverProvider>().assignedRoutes;
    final total = _total;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      bottomNavigationBar: widget.showBottomNavigationBar
          ? const DriverBottomNavigationBar(selectedIndex: 3)
          : null,
      appBar: AppBar(
        title: const Text('Recycling center weigh-in'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('At the end of your route or day, enter the weights measured at the recycling center.',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 18),
            DropdownButtonFormField<String?>(
              value: _routeId,
              decoration: const InputDecoration(labelText: 'Route (optional)', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('End of day / multiple routes')),
                ...routes.map((route) => DropdownMenuItem<String?>(
                      value: route['_id']?.toString(),
                      child: Text((route['routeName'] ?? route['zone'] ?? 'Assigned route').toString(), overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (value) => setState(() => _routeId = value),
            ),
            const SizedBox(height: 16),
            _weightField('Organic', _organic),
            const SizedBox(height: 12),
            _weightField('Plastic & paper', _plasticPaper),
            const SizedBox(height: 12),
            _weightField('Glass & others', _glassOthers),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total recorded', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${total.toStringAsFixed(2)} kg', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder(), alignLabelWithHint: true),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save weights'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weightField(String label, TextEditingController controller) => TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: '$label (kg)', suffixText: 'kg', border: const OutlineInputBorder()),
        onChanged: (_) => setState(() {}),
        validator: (value) {
          final weight = double.tryParse(value ?? '');
          if (weight == null || !weight.isFinite || weight < 0) return 'Enter a valid weight (0 or greater)';
          return null;
        },
      );
}
