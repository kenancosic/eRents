import 'package:intl/intl.dart';

/// Global currency formatter for Bosnian Marks (KM).
final kCurrencyFormat = NumberFormat.currency(
  locale: 'en_US', // Bosnian locale
  symbol: '\$', // Currency symbol
);
