import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/property.dart';
import '../../../core/utils/validators.dart';
import '../logic/properties_notifier.dart';

class PropertyFormScreen extends ConsumerStatefulWidget {
  final Property? property;

  const PropertyFormScreen({super.key, this.property});

  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends ConsumerState<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _estimatedValueController;
  late final TextEditingController _notesController;
  DateTime? _purchaseDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.property?.name);
    _addressController = TextEditingController(text: widget.property?.address);
    _purchasePriceController = TextEditingController(
      text: widget.property?.purchasePrice?.toString(),
    );
    _estimatedValueController = TextEditingController(
      text: widget.property?.estimatedValue?.toString(),
    );
    _notesController = TextEditingController(text: widget.property?.notes);
    _purchaseDate = widget.property?.purchaseDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _purchasePriceController.dispose();
    _estimatedValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _purchaseDate = date;
      });
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final property = Property(
        id: widget.property?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        purchaseDate: _purchaseDate,
        purchasePrice: _purchasePriceController.text.isNotEmpty
            ? double.tryParse(_purchasePriceController.text)
            : null,
        estimatedValue: _estimatedValueController.text.isNotEmpty
            ? double.tryParse(_estimatedValueController.text)
            : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        created: widget.property?.created ?? DateTime.now(),
        updated: DateTime.now(),
      );

      if (widget.property == null) {
        await ref.read(propertiesNotifierProvider.notifier).createProperty(property);
      } else {
        await ref.read(propertiesNotifierProvider.notifier).updateProperty(property);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.property == null
                  ? 'Property created successfully'
                  : 'Property updated successfully',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property == null ? 'Add Property' : 'Edit Property'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Property Name',
                hintText: 'e.g., Sunset Apartments',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home_work),
              ),
              validator: (value) => Validators.required(value, fieldName: 'Property name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: '123 Main St, City, State ZIP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) => Validators.required(value, fieldName: 'Address'),
              textInputAction: TextInputAction.next,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              leading: const Icon(Icons.calendar_today),
              title: const Text('Purchase Date'),
              subtitle: _purchaseDate != null
                  ? Text(
                      '${_purchaseDate!.year}-${_purchaseDate!.month.toString().padLeft(2, '0')}-${_purchaseDate!.day.toString().padLeft(2, '0')}',
                    )
                  : const Text('Not set'),
              trailing: _purchaseDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _purchaseDate = null;
                        });
                      },
                    )
                  : null,
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _purchasePriceController,
              decoration: const InputDecoration(
                labelText: 'Purchase Price',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _estimatedValueController,
              decoration: const InputDecoration(
                labelText: 'Estimated Value',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Additional information...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 4,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _saveProperty,
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
                    : Text(widget.property == null ? 'Create Property' : 'Update Property'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
