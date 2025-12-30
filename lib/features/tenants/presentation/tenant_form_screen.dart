import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/tenant.dart';
import '../../../data/models/unit.dart';
import '../../../core/utils/validators.dart';
import '../../properties/logic/units_notifier.dart';
import '../logic/tenants_notifier.dart';

class TenantFormScreen extends ConsumerStatefulWidget {
  final Tenant? tenant;
  final String? preselectedUnitId;

  const TenantFormScreen({
    super.key,
    this.tenant,
    this.preselectedUnitId,
  });

  @override
  ConsumerState<TenantFormScreen> createState() => _TenantFormScreenState();
}

class _TenantFormScreenState extends ConsumerState<TenantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _depositController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedUnitId;
  DateTime? _leaseStart;
  DateTime? _leaseEnd;
  LeaseTerm _leaseTerm = LeaseTerm.monthly;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tenant != null) {
      _nameController.text = widget.tenant!.name;
      _phoneController.text = widget.tenant!.phone ?? '';
      _emailController.text = widget.tenant!.email ?? '';
      _depositController.text = widget.tenant!.depositAmount?.toString() ?? '';
      _notesController.text = widget.tenant!.notes ?? '';
      _selectedUnitId = widget.tenant!.unitId;
      _leaseStart = widget.tenant!.leaseStart;
      _leaseEnd = widget.tenant!.leaseEnd;
      _leaseTerm = widget.tenant!.leaseTerm;
    } else if (widget.preselectedUnitId != null) {
      _selectedUnitId = widget.preselectedUnitId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _depositController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(unitsNotifierProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tenant == null ? 'Add Tenant' : 'Edit Tenant'),
      ),
      body: unitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading units: $error')),
        data: (units) {
          final occupiedUnits = widget.tenant != null
              ? units.where((u) => u.status == UnitStatus.occupied && u.id != widget.tenant!.unitId).map((u) => u.id).toSet()
              : units.where((u) => u.status == UnitStatus.occupied).map((u) => u.id).toSet();

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tenant Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: Validators.required,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedUnitId,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.apartment),
                  ),
                  items: units.map((unit) {
                    final isOccupied = occupiedUnits.contains(unit.id);
                    return DropdownMenuItem(
                      value: unit.id,
                      enabled: !isOccupied,
                      child: Text(
                        '${unit.unitName}${isOccupied ? ' (Occupied)' : ''}',
                        style: TextStyle(
                          color: isOccupied ? Colors.grey : null,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUnitId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a unit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !Validators.isValidEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Lease Start Date'),
                  subtitle: Text(
                    _leaseStart != null ? DateFormat('MMM dd, yyyy').format(_leaseStart!) : 'Not set',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, isStartDate: true),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Lease End Date'),
                  subtitle: Text(
                    _leaseEnd != null ? DateFormat('MMM dd, yyyy').format(_leaseEnd!) : 'Not set',
                  ),
                  trailing: const Icon(Icons.event),
                  onTap: () => _selectDate(context, isStartDate: false),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<LeaseTerm>(
                  value: _leaseTerm,
                  decoration: const InputDecoration(
                    labelText: 'Lease Term',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: LeaseTerm.monthly,
                      child: Text('Monthly'),
                    ),
                    DropdownMenuItem(
                      value: LeaseTerm.annually,
                      child: Text('Annually'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _leaseTerm = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _depositController,
                  decoration: const InputDecoration(
                    labelText: 'Deposit Amount (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet),
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return 'Please enter a valid amount';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveTenant,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.tenant == null ? 'Add Tenant' : 'Update Tenant'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final initialDate = isStartDate
        ? (_leaseStart ?? DateTime.now())
        : (_leaseEnd ?? _leaseStart?.add(const Duration(days: 365)) ?? DateTime.now());

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _leaseStart = pickedDate;
          if (_leaseEnd != null && _leaseEnd!.isBefore(_leaseStart!)) {
            _leaseEnd = null;
          }
        } else {
          if (_leaseStart != null && pickedDate.isBefore(_leaseStart!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('End date must be after start date')),
            );
            return;
          }
          _leaseEnd = pickedDate;
        }
      });
    }
  }

  Future<void> _saveTenant() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a unit')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final tenant = Tenant(
        id: widget.tenant?.id ?? const Uuid().v4(),
        unitId: _selectedUnitId!,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        leaseStart: _leaseStart,
        leaseEnd: _leaseEnd,
        leaseTerm: _leaseTerm,
        depositAmount: _depositController.text.trim().isEmpty ? null : double.tryParse(_depositController.text.trim()),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        created: widget.tenant?.created ?? now,
        updated: now,
      );

      if (widget.tenant == null) {
        await ref.read(tenantsNotifierProvider(null).notifier).createTenant(tenant);
      } else {
        await ref.read(tenantsNotifierProvider(null).notifier).updateTenant(tenant);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.tenant == null ? 'Tenant added successfully' : 'Tenant updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
