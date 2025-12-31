import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../../features/documents/presentation/pdf_viewer_screen.dart';
import '../../features/documents/presentation/image_viewer_screen.dart';

class DocumentViewerHelper {
  /// Open document based on file type
  static Future<void> openDocument(
    BuildContext context,
    String filePath,
    String fileName,
  ) async {
    final extension = fileName.split('.').last.toLowerCase();

    if (_isPdf(extension)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            filePath: filePath,
            fileName: fileName,
          ),
        ),
      );
    } else if (_isImage(extension)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageViewerScreen(
            filePath: filePath,
            fileName: fileName,
          ),
        ),
      );
    } else {
      // Open with external app
      await _openWithExternalApp(context, filePath);
    }
  }

  /// Check if file is PDF
  static bool _isPdf(String extension) {
    return extension == 'pdf';
  }

  /// Check if file is an image
  static bool _isImage(String extension) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(extension);
  }

  /// Open file with external app
  static Future<void> _openWithExternalApp(
    BuildContext context,
    String filePath,
  ) async {
    try {
      final result = await OpenFile.open(filePath);
      
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get icon for file type
  static IconData getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (_isPdf(extension)) {
      return Icons.picture_as_pdf;
    } else if (_isImage(extension)) {
      return Icons.image;
    } else if (_isDocument(extension)) {
      return Icons.description;
    } else if (_isSpreadsheet(extension)) {
      return Icons.table_chart;
    } else {
      return Icons.insert_drive_file;
    }
  }

  /// Check if file is a document
  static bool _isDocument(String extension) {
    const docExtensions = ['doc', 'docx', 'txt', 'rtf'];
    return docExtensions.contains(extension);
  }

  /// Check if file is a spreadsheet
  static bool _isSpreadsheet(String extension) {
    const sheetExtensions = ['xls', 'xlsx', 'csv'];
    return sheetExtensions.contains(extension);
  }

  /// Get color for file type
  static Color getFileColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (_isPdf(extension)) {
      return Colors.red;
    } else if (_isImage(extension)) {
      return Colors.blue;
    } else if (_isDocument(extension)) {
      return Colors.indigo;
    } else if (_isSpreadsheet(extension)) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }
}
