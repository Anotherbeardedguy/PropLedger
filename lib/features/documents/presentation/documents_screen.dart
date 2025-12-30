import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/document.dart';
import '../../../data/models/property.dart';
import '../../../data/models/unit.dart';
import '../../../data/models/tenant.dart';
import '../logic/documents_notifier.dart';
import '../../properties/logic/properties_notifier.dart';
import '../../tenants/logic/tenants_notifier.dart';
import 'add_document_screen.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  LinkedType? _selectedLinkedType;
  String? _selectedLinkedId;

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(documentsNotifierProvider);
    final propertiesAsync = ref.watch(propertiesNotifierProvider);
    final tenantsAsync = ref.watch(tenantsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: documentsAsync.when(
        data: (allDocuments) {
          var documents = _applyFilters(allDocuments);
          documents.sort((a, b) => b.created.compareTo(a.created));

          if (documents.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No documents found'),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add your first document',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final expiring = ref.read(documentsNotifierProvider.notifier).getExpiringDocuments();
          final expired = ref.read(documentsNotifierProvider.notifier).getExpiredDocuments();

          return Column(
            children: [
              if (_hasActiveFilters())
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getFilterSummary(),
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              if (expired.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.red.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '${expired.length} expired document${expired.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (expiring.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '${expiring.length} document${expiring.length > 1 ? 's' : ''} expiring soon',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    return _buildDocumentCard(
                      context,
                      document,
                      propertiesAsync,
                      tenantsAsync,
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddDocument(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Document> _applyFilters(List<Document> documents) {
    var filtered = documents;

    if (_selectedLinkedType != null && _selectedLinkedId != null) {
      filtered = filtered
          .where((d) =>
              d.linkedType == _selectedLinkedType && d.linkedId == _selectedLinkedId)
          .toList();
    }

    return filtered;
  }

  bool _hasActiveFilters() {
    return _selectedLinkedType != null && _selectedLinkedId != null;
  }

  String _getFilterSummary() {
    if (_selectedLinkedType != null) {
      return 'Filtered by ${_getLinkedTypeLabel(_selectedLinkedType!)}';
    }
    return 'Filtered';
  }

  void _clearFilters() {
    setState(() {
      _selectedLinkedType = null;
      _selectedLinkedId = null;
    });
  }

  Widget _buildDocumentCard(
    BuildContext context,
    Document document,
    AsyncValue<List<Property>> propertiesAsync,
    AsyncValue<List<Tenant>> tenantsAsync,
  ) {
    final linkedName = _getLinkedEntityName(
      document,
      propertiesAsync,
      tenantsAsync,
    );

    final isExpired = document.isExpired;
    final isExpiring = document.isExpiringSoon();

    Color? statusColor;
    IconData? statusIcon;
    if (isExpired) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else if (isExpiring) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor?.withOpacity(0.2) ?? Colors.blue.shade100,
          child: Icon(
            _getDocumentTypeIcon(document.documentType),
            color: statusColor ?? Colors.blue.shade700,
          ),
        ),
        title: Text(
          document.documentType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${_getLinkedTypeLabel(document.linkedType)}: $linkedName'),
            if (document.expiryDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (statusIcon != null) ...[
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    'Expires: ${DateFormat('MMM dd, yyyy').format(document.expiryDate!)}',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: isExpired || isExpiring ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ],
            if (document.notes != null) ...[
              const SizedBox(height: 4),
              Text(
                document.notes!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDelete(context, document),
        ),
        onTap: () => _showDocumentDetails(context, document, linkedName),
      ),
    );
  }

  String _getLinkedEntityName(
    Document document,
    AsyncValue<List<Property>> propertiesAsync,
    AsyncValue<List<Tenant>> tenantsAsync,
  ) {
    switch (document.linkedType) {
      case LinkedType.property:
        return propertiesAsync.maybeWhen(
          data: (properties) {
            final property = properties.cast<Property?>().firstWhere(
                  (p) => p?.id == document.linkedId,
                  orElse: () => null,
                );
            return property?.name ?? 'Unknown';
          },
          orElse: () => 'Loading...',
        );
      case LinkedType.tenant:
        return tenantsAsync.maybeWhen(
          data: (tenants) {
            final tenant = tenants.cast<Tenant?>().firstWhere(
                  (t) => t?.id == document.linkedId,
                  orElse: () => null,
                );
            return tenant?.name ?? 'Unknown';
          },
          orElse: () => 'Loading...',
        );
      case LinkedType.unit:
        return 'Unit';
    }
  }

  String _getLinkedTypeLabel(LinkedType type) {
    switch (type) {
      case LinkedType.property:
        return 'Property';
      case LinkedType.unit:
        return 'Unit';
      case LinkedType.tenant:
        return 'Tenant';
    }
  }

  IconData _getDocumentTypeIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('lease') || lower.contains('contract')) {
      return Icons.description;
    } else if (lower.contains('insurance')) {
      return Icons.security;
    } else if (lower.contains('tax') || lower.contains('receipt')) {
      return Icons.receipt_long;
    } else if (lower.contains('inspection')) {
      return Icons.checklist;
    } else if (lower.contains('deed') || lower.contains('title')) {
      return Icons.gavel;
    }
    return Icons.insert_drive_file;
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Documents'),
        content: const Text('Filter by linked entity coming soon'),
        actions: [
          TextButton(
            onPressed: () {
              _clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDocumentDetails(BuildContext context, Document document, String linkedName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(document.documentType),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Linked to', linkedName),
              _buildDetailRow('Type', _getLinkedTypeLabel(document.linkedType)),
              if (document.expiryDate != null)
                _buildDetailRow(
                  'Expires',
                  DateFormat('MMMM dd, yyyy').format(document.expiryDate!),
                ),
              _buildDetailRow('File', document.file),
              if (document.notes != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(document.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Document document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.documentType}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final notifier = ref.read(documentsNotifierProvider.notifier);
              await notifier.deleteDocument(document.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddDocument(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddDocumentScreen(),
      ),
    );
  }
}
