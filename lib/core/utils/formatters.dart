import 'package:intl/intl.dart';

class CurrencyFormatter {
  static const Map<String, String> _symbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'ZAR': 'R',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  static String format(double amount, String currency) {
    final symbol = _symbols[currency] ?? currency;
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$symbol${formatter.format(amount)}';
  }

  static String formatCompact(double amount, String currency) {
    final symbol = _symbols[currency] ?? currency;
    
    if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '$symbol${amount.toStringAsFixed(0)}';
    }
  }
}

class DateFormatter {
  static String format(DateTime date, String format) {
    switch (format) {
      case 'MM/dd/yyyy':
        return DateFormat('MM/dd/yyyy').format(date);
      case 'dd/MM/yyyy':
        return DateFormat('dd/MM/yyyy').format(date);
      case 'yyyy-MM-dd':
        return DateFormat('yyyy-MM-dd').format(date);
      default:
        return DateFormat('MM/dd/yyyy').format(date);
    }
  }

  static String formatShort(DateTime date, String format) {
    switch (format) {
      case 'MM/dd/yyyy':
        return DateFormat('MMM dd, yyyy').format(date);
      case 'dd/MM/yyyy':
        return DateFormat('dd MMM yyyy').format(date);
      case 'yyyy-MM-dd':
        return DateFormat('yyyy-MM-dd').format(date);
      default:
        return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
}
