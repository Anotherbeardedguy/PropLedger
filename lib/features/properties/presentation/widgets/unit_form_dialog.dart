import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/unit.dart';
import '../../../../core/utils/validators.dart';
import '../../logic/units_notifier.dart';

class UnitFormDialog extends ConsumerStatefulWidget {
  final String propertyId;
  final Unit? unit;

  const UnitFormDialog({
    super.key,
    required this.propertyId,
    this.unit,
  });

  @override
  ConsumerState<UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends ConsumerState<UnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _unitNameController;
  late final TextEditingController _sizeSqmController;
  late final TextEditingController _roomsController;
  late final TextEditingController _rentAmountController;
  late final TextEditingController _notesController;
  late UnitStatus _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _unitNameController = TextEditingController(text: widget.unit?.unitName);
    _sizeSqmController = TextEditingController(
      text: widget.unit?.sizeSqm?.toString(),
    );
    _roomsController = TextEditingController(
      text: widget.unit?.rooms?.toString(),
    );
    _rentAmountController = TextEditingController(
      text: widget.unit?.rentAmount.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget.unit?.notes);
    _status = widget.unit?.status ?? UnitStatus.vacant;
  }

  @override
  void dispose() {
    _unitNameController.dispose();
    _sizeSqmController.dispose();
    _roomsController.dispose();
    _rentAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveUnit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final unit = Unit(
        id: widget.unit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        propertyId: widget.propertyId,
        unitName: _unitNameController.text.trim(),
        sizeSqm: _sizeSqmController.text.isNotEmpty
            ? double.tryParse(_sizeSqmController.text)
            : null,
        rooms: _roomsController.text.isNotEmpty
            ? int.tryParse(_roomsController.text)
            : null,
        rentAmount: double.parse(_rentAmountController.text),
        status: _status,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        created: widget.unit?.created ?? DateTime.now(),
        updated: DateTime.now(),
      );

      if (widget.unit == null) {
        await ref
            .read(unitsNotifierProvider(widget.propertyId).notifier)
            .createUnit(unit);
      } else {
        await ref
            .read(unitsNotifierProvider(widget.propertyId).notifier)
            .updateUnit(unit);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.unit == null
                  ? 'Unit created successfully'
                  : 'Unit updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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

  Future<void> _deleteUnit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unit'),
        content: const Text('Are you sure you want to delete this unit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(unitsNotifierProvider(widget.propertyId).notifier)
            .deleteUnit(widget.unit!.id);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unit deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.unit == null ? 'Add Unit' : 'Edit Unit',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      if (widget.unit != null)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: _deleteUnit,
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _unitNameController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Name/Number',
                      hintText: 'e.g., Unit 101, Apt A',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        Validators.required(value, fieldName: 'Unit name'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sizeSqmController,
                          decoration: const InputDecoration(
                            labelText: 'Size (sqm)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _roomsController,
                          decoration: const InputDecoration(
                            labelText: 'Rooms',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _rentAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Rent Amount',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        Validators.positiveNumber(value, fieldName: 'Rent amount'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UnitStatus>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: UnitStatus.vacant,
                        child: Text('Vacant'),
                      ),
                      DropdownMenuItem(
                        value: UnitStatus.occupied,
                        child: Text('Occupied'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _status = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Additional information...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _saveUnit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.unit == null ? 'Create Unit' : 'Update Unit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
