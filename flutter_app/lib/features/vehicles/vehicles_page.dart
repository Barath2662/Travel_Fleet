import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';

class VehiclesPage extends ConsumerStatefulWidget {
  const VehiclesPage({super.key});

  @override
  ConsumerState<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends ConsumerState<VehiclesPage> {
  static const _categories = ['sedan', 'suv', 'mvp', 'van', 'hatchback', 'luxury', 'mini_bus', 'other'];

  final _number = TextEditingController();
  final _seats = TextEditingController(text: '4');
  final _nextServiceKm = TextEditingController();
  String _category = 'sedan';
  DateTime? _fcDate;
  DateTime? _insuranceDate;
  DateTime? _pucDate;
  DateTime? _permitDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final app = ref.read(appStateProvider.notifier);
      await app.fetchVehicles();
      await app.fetchVehicleBataRates();
    });
  }

  @override
  void dispose() {
    _number.dispose();
    _seats.dispose();
    _nextServiceKm.dispose();
    super.dispose();
  }

  Future<void> _createVehicle() async {
    if (_number.text.trim().isEmpty || _nextServiceKm.text.trim().isEmpty) {
      _show('Vehicle number and next service KM are required');
      return;
    }

    if (_fcDate == null || _insuranceDate == null || _pucDate == null || _permitDate == null) {
      _show('Please select FC, insurance, PUC, and permit dates');
      return;
    }

    await ref.read(appStateProvider.notifier).createVehicle({
      'number': _number.text.trim(),
      'category': _category,
      'seats': int.tryParse(_seats.text.trim()) ?? 4,
      'fcDate': _fcDate!.toIso8601String(),
      'insuranceDate': _insuranceDate!.toIso8601String(),
      'pucDate': _pucDate!.toIso8601String(),
      'permitDate': _permitDate!.toIso8601String(),
      'nextServiceKm': int.tryParse(_nextServiceKm.text) ?? 0,
      'currentKm': 0,
    });

    _number.clear();
    _seats.text = '4';
    _nextServiceKm.clear();
    setState(() {
      _category = 'sedan';
      _fcDate = null;
      _insuranceDate = null;
      _pucDate = null;
      _permitDate = null;
    });
  }

  Future<void> _setCategoryBata(String category, double current) async {
    final controller = TextEditingController(text: current > 0 ? current.toStringAsFixed(0) : '');
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Bata • $category'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed == null || parsed < 0) {
                _show('Enter valid amount');
                return;
              }
              Navigator.pop(context, parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (amount == null) return;
    await ref.read(appStateProvider.notifier).setVehicleBataRate(category: category, amount: amount);
    _show('Bata updated for $category');
  }

  Future<void> _renewVehicleDates(dynamic v) async {
    DateTime? fc = v.fcDate;
    DateTime? insurance = v.insuranceDate;
    DateTime? puc = v.pucDate;
    DateTime? permit = v.permitDate;
    final nextServiceController = TextEditingController(text: v.nextServiceKm.toString());

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDateDialog(String key) async {
              final now = DateTime.now();
              DateTime initial;
              if (key == 'fc') {
                initial = fc ?? now;
              } else if (key == 'insurance') {
                initial = insurance ?? now;
              } else {
                initial = puc ?? now;
              }

              final selected = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 10),
              );
              if (selected == null) return;
              setDialogState(() {
                if (key == 'fc') {
                  fc = selected;
                } else if (key == 'insurance') {
                  insurance = selected;
                } else if (key == 'puc') {
                  puc = selected;
                } else {
                  permit = selected;
                }
              });
            }

            return AlertDialog(
              title: Text('Update Renewal • ${v.number}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DateField(
                      label: 'FC Date',
                      value: _fmt(fc),
                      onTap: () => pickDateDialog('fc'),
                    ),
                    _DateField(
                      label: 'Insurance Date',
                      value: _fmt(insurance),
                      onTap: () => pickDateDialog('insurance'),
                    ),
                    _DateField(
                      label: 'PUC Date',
                      value: _fmt(puc),
                      onTap: () => pickDateDialog('puc'),
                    ),
                    _DateField(
                      label: 'Permit Date',
                      value: _fmt(permit),
                      onTap: () => pickDateDialog('permit'),
                    ),
                    TextField(
                      controller: nextServiceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Next Service KM'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    if (fc == null || insurance == null || puc == null || permit == null) {
                      _show('All renewal dates are required');
                      return;
                    }
                    await ref.read(appStateProvider.notifier).updateVehicle(v.id, {
                      'number': v.number,
                      'category': v.category,
                      'seats': v.seats,
                      'currentKm': v.currentKm,
                      'nextServiceKm': int.tryParse(nextServiceController.text.trim()) ?? v.nextServiceKm,
                      'fcDate': fc!.toIso8601String(),
                      'insuranceDate': insurance!.toIso8601String(),
                      'pucDate': puc!.toIso8601String(),
                      'permitDate': permit!.toIso8601String(),
                    });
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == true) {
      _show('Vehicle renewal details updated');
    }
  }

  Future<void> _pickDate(ValueSetter<DateTime?> setter, {DateTime? initialDate}) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
    );
    if (selected != null) {
      setState(() => setter(selected));
    }
  }

  String _fmt(DateTime? date) => date == null ? 'Select date' : DateFormat('dd MMM yyyy').format(date);

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final role = ref.watch(authProvider).role;
    final isWide = MediaQuery.of(context).size.width > 760;

    return RefreshIndicator(
      onRefresh: () async {
        final app = ref.read(appStateProvider.notifier);
        await app.fetchVehicles();
        await app.fetchVehicleBataRates();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Vehicle', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (isWide)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _number,
                            decoration: const InputDecoration(labelText: 'Vehicle Number'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: _categories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase())))
                                .toList(),
                            onChanged: (value) => setState(() => _category = value ?? 'sedan'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _seats,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'No. of Seats'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _nextServiceKm,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Next Service KM'),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    TextField(
                      controller: _number,
                      decoration: const InputDecoration(labelText: 'Vehicle Number'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                      onChanged: (value) => setState(() => _category = value ?? 'sedan'),
                    ),
                    TextField(
                      controller: _seats,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'No. of Seats'),
                    ),
                    TextField(
                      controller: _nextServiceKm,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Next Service KM'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (isWide)
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'FC Date',
                            value: _fmt(_fcDate),
                            onTap: () => _pickDate((d) => _fcDate = d, initialDate: _fcDate),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'Insurance Date',
                            value: _fmt(_insuranceDate),
                            onTap: () => _pickDate((d) => _insuranceDate = d, initialDate: _insuranceDate),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'PUC Date',
                            value: _fmt(_pucDate),
                            onTap: () => _pickDate((d) => _pucDate = d, initialDate: _pucDate),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'Permit Date',
                            value: _fmt(_permitDate),
                            onTap: () => _pickDate((d) => _permitDate = d, initialDate: _permitDate),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _DateField(
                      label: 'FC Date',
                      value: _fmt(_fcDate),
                      onTap: () => _pickDate((d) => _fcDate = d, initialDate: _fcDate),
                    ),
                    _DateField(
                      label: 'Insurance Date',
                      value: _fmt(_insuranceDate),
                      onTap: () => _pickDate((d) => _insuranceDate = d, initialDate: _insuranceDate),
                    ),
                    _DateField(
                      label: 'PUC Date',
                      value: _fmt(_pucDate),
                      onTap: () => _pickDate((d) => _pucDate = d, initialDate: _pucDate),
                    ),
                    _DateField(
                      label: 'Permit Date',
                      value: _fmt(_permitDate),
                      onTap: () => _pickDate((d) => _permitDate = d, initialDate: _permitDate),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: (role == 'owner' || role == 'employee') ? _createVehicle : null,
                    child: const Text('Save Vehicle'),
                  ),
                ],
              ),
            ),
          ),
          if (role == 'owner' || role == 'employee')
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Driver Bata by Vehicle Category', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    ..._categories.map(
                      (c) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.toUpperCase()),
                        subtitle: Text('Current: ${(state.vehicleBataRates[c] ?? 0).toStringAsFixed(0)}'),
                        trailing: OutlinedButton(
                          onPressed: () => _setCategoryBata(c, state.vehicleBataRates[c] ?? 0),
                          child: const Text('Set Bata'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (state.loading) const LinearProgressIndicator(),
          ...state.vehicles.map(
            (v) => Card(
              child: ListTile(
                title: Text(v.number),
                subtitle: Text(
                  'Category: ${v.category.toUpperCase()} | Seats: ${v.seats}\n'
                  'Current KM: ${v.currentKm} | Next Service: ${v.nextServiceKm}\n'
                  'FC: ${_fmt(v.fcDate)} | Insurance: ${_fmt(v.insuranceDate)} | PUC: ${_fmt(v.pucDate)} | Permit: ${_fmt(v.permitDate)}',
                ),
                isThreeLine: true,
                trailing: (role == 'owner' || role == 'employee')
                    ? OutlinedButton(
                        onPressed: () => _renewVehicleDates(v),
                        child: const Text('Renew'),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          child: Text(value),
        ),
      ),
    );
  }
}
