import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/activity_detail_controller.dart';
import '../common/async_state.dart';
import '../l10n/app_localizations.dart';
import '../persistence/persistence_providers.dart';
import '../state/activity_detail_providers.dart';

class ActivityDescriptionEditor extends ConsumerWidget {
  const ActivityDescriptionEditor({Key? key, required this.activityId})
    : super(key: key);

  final int activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final description = ref.watch(activityDescriptionProvider(activityId));

    return AsyncStateView<String?>(
      value: description,
      data: (rawDescription) => _buildDescription(context, ref, rawDescription),
      errorMessage: AppLocalizations.of(context)!.loadDescriptionFailed,
      layout: AsyncStateLayout.inline,
      onRetry: () => ref.invalidate(activityDescriptionProvider(activityId)),
      retryLabel: AppLocalizations.of(context)!.retry,
    );
  }

  Widget _buildDescription(
    BuildContext context,
    WidgetRef ref,
    String? rawDescription,
  ) {
    final isEditing = ref.watch(activityDescriptionEditingProvider(activityId));
    if (isEditing) {
      return Center(
        child: TextFormField(
          textAlign: TextAlign.center,
          initialValue: rawDescription ?? '',
          onFieldSubmitted: (newValue) => _saveDescription(ref, newValue),
          autofocus: true,
        ),
      );
    }

    final displayDescription = _displayDescription(
      AppLocalizations.of(context)!,
      rawDescription,
    );
    final hasDescription = rawDescription != null && rawDescription.isNotEmpty;

    return InkWell(
      onTap: () {
        ref
            .read(activityDescriptionEditingProvider(activityId).notifier)
            .set(true);
      },
      child: Text(
        displayDescription,
        style: TextStyle(
          color: hasDescription ? null : Colors.black38,
          fontSize: 18.0,
        ),
      ),
    );
  }

  Future<void> _saveDescription(WidgetRef ref, String newValue) async {
    await ActivityDetailController(
      repository: ref.read(activityWriterProvider),
    ).saveDescription(
      activityId,
      newValue,
      refresh: () => ref.invalidate(activityDescriptionProvider(activityId)),
      exitEditing: () => ref
          .read(activityDescriptionEditingProvider(activityId).notifier)
          .set(false),
    );
  }

  String _displayDescription(
    AppLocalizations localizations,
    String? rawDescription,
  ) {
    if (rawDescription == null || rawDescription.isEmpty) {
      return localizations.noDescription;
    }
    return rawDescription;
  }
}
