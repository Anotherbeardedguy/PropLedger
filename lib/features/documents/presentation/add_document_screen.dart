import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/document.dart';
import '../../../data/models/property.dart';
import '../../../data/models/tenant.dart';
import '../logic/documents_notifier.dart';
import '../../properties/logic/properties_notifier.dart';
import '../../tenants/logic/tenants_notifier.dart';

class AddDocumentScreen extends ConsumerStatefulWidget {
  const AddDocumentScreen({super.key});

  @override
  ConsumerState<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends ConsumerState<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentTypeController = TextEditingController();
  final _filePathController = TextEditingController();
  final _notesController = TextEditingController();

  LinkedType _linkedType = LinkedType.property;
  String? _selectedLinkedId;
  DateTime? _expiryDate;

  @override
  void dispose() {
    _documentTypeController.dispose();
    _filePathController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesNotifierProvider);
    final tenantsAsync = ref.watch(tenantsNotifierProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Document'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _documentTypeController,
              decoration: const InputDecoration(
                labelText: 'Document Type *',
                border: OutlineInputBorder(),
                helperText: 'e.g., Lease Agreement, Insurance Policy, Tax Document',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter document type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LinkedType>(
              value: _linkedType,
              decoration: const InputDecoration(
                labelText: 'Link To *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: LinkedType.property,
                  child: Text('Property'),
                ),
                DropdownMenuItem(
                  value: LinkedType.tenant,
                  child: Text('Tenant'),
                ),
                DropdownMenuItem(
                  value: LinkedType.unit,
                  child: Text('Unit'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _linkedType = value;
                    _selectedLinkedId = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (_linkedType == LinkedType.property)
              propertiesAsync.when(
                data: (properties) => DropdownButtonFormField<String>(
                  value: _selectedLinkedId,
                  decoration: const InputDecoration(
                    labelText: 'Select Property *',
                    border: OutlineInputBorder(),
                  ),
                  items: properties.map((property) {
                    return DropdownMenuItem(
                      value: property.id,
                      child: Text(property.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedLinkedId = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a property';
                    }
                    return null;
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('Error: $error'),
              ),
            if (_linkedType == LinkedType.tenant)
              tenantsAsync.when(
                data: (tenants) => DropdownButtonFormField<String>(
                  value: _selectedLinkedId,
                  decoration: const InputDecoration(
                    labelText: 'Select Tenant *',
                    border: OutlineInputBorder(),
                  ),
                  items: tenants.map((tenant) {
                    return DropdownMenuItem(
                      value: tenant.id,
                      child: Text(tenant.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedLinkedId = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a tenant';
                    }
                    return null;
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('Error: $error'),
              ),
            if (_linkedType == LinkedType.unit)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Unit ID *',
                  border: OutlineInputBorder(),
                  helperText: 'Enter the unit identifier',
                ),
                onChanged: (value) => _selectedLinkedId = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter unit ID';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _filePathController,
              decoration: const InputDecoration(
                labelText: 'File Path / Reference *',
                border: OutlineInputBorder(),
                helperText: 'File location or reference identifier',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter file path';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_expiryDate != null
                  ? 'Expiry: ${DateFormat('MMMM dd, yyyy').format(_expiryDate!)}'
                  : 'Expiry Date (Optional)'),
              subtitle: _expiryDate == null
                  ? const Text('No expiry date set')
                  : Text(
                      _getDaysUntilExpiry() < 0
                          ? 'Expired'
                          : '${_getDaysUntilExpiry()} days remaining',
                      style: TextStyle(
                        color: _getDaysUntilExpiry() < 30
                            ? (_getDaysUntilExpiry() < 0 ? Colors.red : Colors.orange)
                            : null,
                      ),
                    ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_expiryDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _expiryDate = null),
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              onTap: () => _selectExpiryDate(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveDocument,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Add Document'),
            ),
          ],
        ),
      ),
    );
  }

  int _getDaysUntilExpiry() {
    if (_expiryDate == null) return 999;
    return _expiryDate!.difference(DateTime.now()).inDays;
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  void _saveDocument() async {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(documentsNotifierProvider.notifier);

      final document = Document(
        id: const Uuid().v4(),
        linkedType: _linkedType,
        linkedId: _selectedLinkedId!,
        documentType: _documentTypeController.text,
        file: _filePathController.text,
        expiryDate: _expiryDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        created: DateTime.now(),
        updated: DateTime.now(),
      );

      await notifier.createDocument(document);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document added')),
        );
      }
    }
  }
}
