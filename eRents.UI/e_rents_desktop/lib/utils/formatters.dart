import 'package:intl/intl.dart';

/// Global currency formatter for Bosnian Marks (KM).
final kCurrencyFormat = NumberFormat.currency(
  locale: 'bs_BA', // Bosnian locale
  symbol: 'KM', // Currency symbol
);
