/// Upper bound (inclusive) for `Records.value`.
///
/// Must stay in lockstep with the `abs(value) <= 1000000000000000.0` SQL
/// CHECK on the records table (see lib/persistence/database/tables.dart and
/// the matching v6 migration/v5-prep guard in
/// lib/persistence/database/app_database.dart). The SQL is a plain decimal
/// literal, not `1e15`, because drift_dev 2.34.0's sqlparser corrupts
/// scientific-notation exponents when re-parsing CHECK text; see the
/// comment at the CHECK for details. If this constant changes, the SQL
/// strings must be updated to match byte-for-byte (schema regeneration
/// must produce no diff), or the SQL <-> Dart consistency test will fail.
const double maxRecordValue = 1000000000000000.0;

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
  if (value > maxRecordValue) {
    throw ArgumentError.value(
      value,
      'value',
      'value must be at most $maxRecordValue',
    );
  }
  return value;
}
