String normalizeRequiredName(String value, {required String field}) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, '$field cannot be blank');
  }
  return normalized;
}

String? normalizeOptionalName(String? value, {required String field}) {
  if (value == null) {
    return null;
  }
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }
  return normalizeRequiredName(normalized, field: field);
}

double? validateRecordValue(double? value, {required bool hasUnit}) {
  if (!hasUnit) {
    if (value != null) {
      throw ArgumentError.value(value, 'value', 'value requires a Unit');
    }
    return null;
  }
  if (value == null) {
    throw ArgumentError.notNull('value');
  }
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(
      value,
      'value',
      'value must be finite and greater than zero',
    );
  }
  return value;
}
