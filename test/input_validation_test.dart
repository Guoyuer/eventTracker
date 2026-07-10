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

  test('numeric values must be finite', () {
    expect(validateOptionalFiniteValue(null), isNull);
    expect(validateOptionalFiniteValue(3.5), 3.5);
    expect(() => validateOptionalFiniteValue(double.nan), throwsArgumentError);
    expect(
      () => validateOptionalFiniteValue(double.infinity),
      throwsArgumentError,
    );
    expect(
      () => validateOptionalFiniteValue(double.negativeInfinity),
      throwsArgumentError,
    );
  });
}
