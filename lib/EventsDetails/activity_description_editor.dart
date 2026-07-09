import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../stateProviders.dart';

class ActivityDescriptionEditor extends ConsumerStatefulWidget {
  const ActivityDescriptionEditor({
    Key? key,
    required this.activityId,
  }) : super(key: key);

  final int activityId;

  @override
  ConsumerState<ActivityDescriptionEditor> createState() =>
      _ActivityDescriptionEditorState();
}

class _ActivityDescriptionEditorState
    extends ConsumerState<ActivityDescriptionEditor> {
  final TextEditingController _controller = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final description =
        ref.watch(activityDescriptionProvider(widget.activityId));

    return description.when(
      data: _buildDescription,
      error: (error, stackTrace) => Text("加载描述失败"),
      loading: () => Text("加载中"),
    );
  }

  Widget _buildDescription(String? rawDescription) {
    if (_isEditing) {
      return Center(
        child: TextField(
          textAlign: TextAlign.center,
          onSubmitted: _saveDescription,
          autofocus: true,
          controller: _controller,
        ),
      );
    }

    final displayDescription = _displayDescription(rawDescription);
    final hasDescription = rawDescription != null && rawDescription.isNotEmpty;

    return InkWell(
      onTap: () {
        _controller.text = rawDescription ?? '';
        setState(() {
          _isEditing = true;
        });
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

  Future<void> _saveDescription(String newValue) async {
    await ref
        .read(activityRepositoryProvider)
        .updateActivityDescription(widget.activityId, newValue);
    ref.invalidate(activityDescriptionProvider(widget.activityId));

    if (!mounted) {
      return;
    }
    setState(() {
      _isEditing = false;
    });
  }

  String _displayDescription(String? rawDescription) {
    if (rawDescription == null || rawDescription.isEmpty) {
      return "无描述";
    }
    return rawDescription;
  }
}
