import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/async_state.dart';
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
      data: (rawDescription) => _buildDescription(ref, rawDescription),
      errorMessage: '加载描述失败',
      layout: AsyncStateLayout.inline,
      onRetry: () => ref.invalidate(activityDescriptionProvider(activityId)),
    );
  }

  Widget _buildDescription(WidgetRef ref, String? rawDescription) {
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

    final displayDescription = _displayDescription(rawDescription);
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
    await ref
        .read(activityRepositoryProvider)
        .updateActivityDescription(activityId, newValue);
    ref.invalidate(activityDescriptionProvider(activityId));
    ref
        .read(activityDescriptionEditingProvider(activityId).notifier)
        .set(false);
  }

  String _displayDescription(String? rawDescription) {
    if (rawDescription == null || rawDescription.isEmpty) {
      return "无描述";
    }
    return rawDescription;
  }
}
