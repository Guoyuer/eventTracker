import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('architecture dependencies', () {
    test('domain is independent from outer layers', () {
      _expectNoImports(_dartFilesUnder('lib/domain'), _outerLayerImports);
    });

    test('application is independent from Flutter and infrastructure', () {
      _expectNoImports(_dartFilesUnder('lib/application'), _outerLayerImports);
    });

    test('analytics is pure Dart over domain models', () {
      _expectNoImports(_dartFilesUnder('lib/analytics'), _outerLayerImports);
    });

    test('state and UI do not reach into database implementation', () {
      final stateAndUiFiles = <File>[
        ..._dartFilesUnder('lib/state'),
        ..._dartFilesUnder('lib/common'),
        ..._dartFilesUnder('lib/EventsList'),
        ..._dartFilesUnder('lib/EventsDetails'),
        ..._dartFilesUnder('lib/Statistics'),
        ..._dartFilesUnder('lib/UnitManager'),
        ..._dartFilesUnder('lib/heatmap_calendar'),
        ...[
          'lib/main.dart',
          'lib/activity_editor_page.dart',
          'lib/settings_page.dart',
        ].map(File.new),
      ];

      _expectNoImports(stateAndUiFiles, _databaseImplementationImports);
    });

    test('database schema stays independent from Flutter bootstrap', () {
      _expectNoImports(
        [File('lib/persistence/database/app_database.dart')],
        (uri) =>
            uri.startsWith('package:flutter/') ||
            uri.startsWith('package:drift_sqflite/') ||
            uri.startsWith('package:path_provider/'),
      );
    });

    test('runtime source contains no hard-coded CJK strings outside l10n', () {
      final violations = <String>[];
      final cjk = RegExp(r'[\u4e00-\u9fff]');

      for (final file in _dartFilesUnder('lib')) {
        if (path.isWithin('lib/l10n', file.path)) {
          continue;
        }
        final unit = parseFile(
          path: path.normalize(file.absolute.path),
          featureSet: FeatureSet.latestLanguageVersion(),
        ).unit;
        final visitor = _HardCodedCjkVisitor(cjk);
        unit.accept(visitor);
        for (final literal in visitor.violations) {
          violations.add('${path.normalize(file.path)}: $literal');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Move user-visible strings into lib/l10n:\n${violations.join('\n')}',
      );
    });
  });
}

bool _outerLayerImports(String uri) {
  return uri.startsWith('package:flutter/') ||
      uri.startsWith('package:flutter_riverpod/') ||
      _referencesLibModule(uri, 'persistence') ||
      _referencesLibModule(uri, 'state') ||
      _referencesLibModule(uri, 'application') ||
      _referencesLibModule(uri, 'l10n') ||
      _referencesLibModule(uri, 'EventsList') ||
      _referencesLibModule(uri, 'EventsDetails') ||
      _referencesLibModule(uri, 'Statistics') ||
      _referencesLibModule(uri, 'UnitManager') ||
      _referencesLibFile(uri, 'activity_editor_page.dart') ||
      _referencesLibFile(uri, 'settings_page.dart');
}

class _HardCodedCjkVisitor extends RecursiveAstVisitor<void> {
  _HardCodedCjkVisitor(this._cjk);

  final RegExp _cjk;
  final violations = <String>[];

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (_cjk.hasMatch(node.value)) {
      violations.add(node.value);
    }
    super.visitSimpleStringLiteral(node);
  }
}

bool _databaseImplementationImports(String uri) {
  return _referencesLibModule(uri, 'persistence/database') ||
      _referencesLibFile(uri, 'drift_activity_repository.dart') ||
      _referencesLibFile(uri, 'drift_statistics_repository.dart') ||
      _referencesLibFile(uri, 'drift_unit_repository.dart') ||
      _referencesLibFile(uri, 'activity_aggregate_store.dart') ||
      _referencesLibFile(uri, 'activity_snapshot_store.dart') ||
      _referencesLibFile(uri, 'record_lifecycle_store.dart');
}

bool _referencesLibModule(String uri, String module) {
  return uri.startsWith('package:event_tracker/$module/') ||
      uri.contains('../$module/') ||
      uri.startsWith('$module/');
}

bool _referencesLibFile(String uri, String fileName) {
  return uri == 'package:event_tracker/$fileName' ||
      uri.endsWith('/$fileName') ||
      uri == fileName;
}

List<File> _dartFilesUnder(String directoryPath) {
  return Directory(directoryPath)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList(growable: false);
}

void _expectNoImports(
  Iterable<File> files,
  bool Function(String uri) isForbidden,
) {
  final violations = <String>[];

  for (final file in files) {
    final unit = parseFile(
      path: path.normalize(file.absolute.path),
      featureSet: FeatureSet.latestLanguageVersion(),
    ).unit;
    for (final import in unit.directives.whereType<ImportDirective>()) {
      final uri = import.uri.stringValue;
      if (uri != null && isForbidden(uri)) {
        violations.add('${path.normalize(file.path)} imports $uri');
      }
    }
  }

  expect(
    violations,
    isEmpty,
    reason: 'Layer violations:\n${violations.join('\n')}',
  );
}
