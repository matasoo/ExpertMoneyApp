class CurrencyFormatter {
  static String format(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
    } else if (amount >= 100000) {
      return '${(amount / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}k';
    } else {
      // Use 2 decimal places if there are decimals, otherwise 0
      if (amount == amount.truncateToDouble()) {
        return amount.toStringAsFixed(0);
      } else {
        return amount.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '').replaceAll(RegExp(r'\.$'), '');
      }
    }
  }
}
