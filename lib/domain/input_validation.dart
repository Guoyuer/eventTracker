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

double? validateOptionalFiniteValue(double? value) {
  if (value != null && !value.isFinite) {
    throw ArgumentError.value(value, 'value', 'value must be finite');
  }
  return value;
}
