import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../data/models/document.dart';
import '../../../data/models/document_link.dart';
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
  final _notesController = TextEditingController();

  File? _selectedFile;
  String? _fileName;
  DateTime? _expiryDate;
  final List<DocumentLink> _selectedLinks = [];

  @override
  void dispose() {
    _documentTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }
  
  void _addPropertyLink() async {
    final propertiesAsync = ref.read(propertiesNotifierProvider);
    final properties = propertiesAsync.maybeWhen(
      data: (props) => props,
      orElse: () => <Property>[],
    );
    
    if (properties.isEmpty) return;
    
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Property'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              return ListTile(
                title: Text(property.name),
                onTap: () => Navigator.pop(context, property.id),
              );
            },
          ),
        ),
      ),
    );
    
    if (selected != null) {
      setState(() {
        _selectedLinks.add(DocumentLink(
          id: const Uuid().v4(),
          documentId: '', // Will be set when document is created
          linkedType: LinkedType.property,
          linkedId: selected,
          created: DateTime.now(),
        ));
      });
    }
  }
  
  void _addTenantLink() async {
    final tenantsAsync = ref.read(tenantsNotifierProvider(null));
    final tenants = tenantsAsync.maybeWhen(
      data: (tens) => tens,
      orElse: () => [],
    );
    
    if (tenants.isEmpty) return;
    
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Tenant'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              final tenant = tenants[index];
              return ListTile(
                title: Text(tenant.name),
                onTap: () => Navigator.pop(context, tenant.id),
              );
            },
          ),
        ),
      ),
    );
    
    if (selected != null) {
      setState(() {
        _selectedLinks.add(DocumentLink(
          id: const Uuid().v4(),
          documentId: '',
          linkedType: LinkedType.tenant,
          linkedId: selected,
          created: DateTime.now(),
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Card(
              child: ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(_fileName ?? 'No file selected'),
                subtitle: _selectedFile != null
                    ? Text(_selectedFile!.path)
                    : const Text('Tap to select a file'),
                trailing: const Icon(Icons.upload_file),
                onTap: _pickFile,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Linked Entities:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._selectedLinks.map((link) => Card(
              child: ListTile(
                leading: Icon(
                  link.linkedType == LinkedType.property
                      ? Icons.home
                      : link.linkedType == LinkedType.tenant
                          ? Icons.person
                          : Icons.apartment,
                ),
                title: Text('${link.linkedType.toString().split('.').last}: ${link.linkedId}'),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedLinks.remove(link);
                    });
                  },
                ),
              ),
            )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addPropertyLink,
                    icon: const Icon(Icons.home),
                    label: const Text('Add Property'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addTenantLink,
                    icon: const Icon(Icons.person),
                    label: const Text('Add Tenant'),
                  ),
                ),
              ],
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
      if (_selectedFile == null || _fileName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a file')),
        );
        return;
      }
      
      if (_selectedLinks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please link to at least one property or tenant')),
        );
        return;
      }

      final notifier = ref.read(documentsNotifierProvider.notifier);
      final documentId = const Uuid().v4();

      final document = Document(
        id: documentId,
        documentType: _documentTypeController.text,
        file: _selectedFile!.path,
        fileName: _fileName!,
        expiryDate: _expiryDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        created: DateTime.now(),
        updated: DateTime.now(),
      );
      
      final links = _selectedLinks.map((link) => link.copyWith(documentId: documentId)).toList();

      await notifier.createDocument(document, links);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document added')),
        );
      }
    }
  }
}
