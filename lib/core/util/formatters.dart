/// One formatting rule per kind of value, so every screen shows them the same
/// way.
library;

/// `$9.99`
String formatPrice(double value) => '\$${value.toStringAsFixed(2)}';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// `Apr 30, 2025`
String formatShortDate(DateTime date) {
  final d = date.toLocal();
  return '${_months[d.month - 1]} ${d.day}, ${d.year}';
}

/// Up to two initials from a name: "Lucas Gordon" → "LG".
String initialsOf(String name) => name
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .take(2)
    .map((w) => w[0].toUpperCase())
    .join();
