import 'package:event_tracker/common/async_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders data through the provided builder', (tester) async {
    await tester.pumpWidget(
      _host(
        AsyncStateView<String>(
          value: const AsyncData('Ready'),
          data: (value) => Text(value),
          errorMessage: 'Failed',
        ),
      ),
    );

    expect(find.text('Ready'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders a configured empty state', (tester) async {
    await tester.pumpWidget(
      _host(
        AsyncStateView<List<String>>(
          value: const AsyncData([]),
          data: (_) => Text('Loaded'),
          errorMessage: 'Failed',
          emptyMessage: 'No rows',
          isEmpty: (value) => value.isEmpty,
        ),
      ),
    );

    expect(find.text('No rows'), findsOneWidget);
    expect(find.text('Loaded'), findsNothing);
  });

  testWidgets('renders a retry action for errors', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      _host(
        AsyncStateView<String>(
          value: AsyncError('boom', StackTrace.current),
          data: (value) => Text(value),
          errorMessage: 'Failed',
          retryLabel: 'Retry',
          onRetry: () {
            retries += 1;
          },
        ),
      ),
    );

    expect(find.text('Failed'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('renders loading state', (tester) async {
    await tester.pumpWidget(
      _host(
        AsyncStateView<String>(
          value: const AsyncLoading(),
          data: (value) => Text(value),
          errorMessage: 'Failed',
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

Widget _host(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}
