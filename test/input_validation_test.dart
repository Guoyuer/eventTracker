import 'package:event_tracker/domain/input_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('required names are trimmed and blank names are rejected', () {
    expect(normalizeRequiredName('  Read  ', field: 'name'), 'Read');
    expect(
      () => normalizeRequiredName('   ', field: 'name'),
      throwsArgumentError,
    );
  });

  test('optional names normalize blank text to null', () {
    expect(normalizeOptionalName(null, field: 'unit'), isNull);
    expect(normalizeOptionalName('   ', field: 'unit'), isNull);
    expect(normalizeOptionalName(' km ', field: 'unit'), 'km');
  });

  test('record values require a Unit and must be positive and finite', () {
    expect(validateRecordValue(null, hasUnit: false), isNull);
    expect(validateRecordValue(3.5, hasUnit: true), 3.5);
    expect(() => validateRecordValue(1, hasUnit: false), throwsArgumentError);
    expect(() => validateRecordValue(null, hasUnit: true), throwsArgumentError);
    expect(() => validateRecordValue(0, hasUnit: true), throwsArgumentError);
    expect(() => validateRecordValue(-1, hasUnit: true), throwsArgumentError);
    expect(
      () => validateRecordValue(double.nan, hasUnit: true),
      throwsArgumentError,
    );
    expect(
      () => validateRecordValue(double.infinity, hasUnit: true),
      throwsArgumentError,
    );
    expect(
      () => validateRecordValue(double.negativeInfinity, hasUnit: true),
      throwsArgumentError,
    );
  });

  test('record values are rejected above the SQL CHECK bound and '
      'accepted at it', () {
    expect(validateRecordValue(maxRecordValue, hasUnit: true), maxRecordValue);
    expect(
      () => validateRecordValue(maxRecordValue + 1, hasUnit: true),
      throwsArgumentError,
    );
  });
}
