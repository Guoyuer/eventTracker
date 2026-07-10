import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AsyncStateLayout { page, card, inline }

class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    Key? key,
    required this.value,
    required this.data,
    required this.errorMessage,
    this.retryLabel,
    this.layout = AsyncStateLayout.page,
    this.emptyMessage,
    this.isEmpty,
    this.onRetry,
  }) : assert(isEmpty == null || emptyMessage != null),
       assert(onRetry == null || retryLabel != null),
       super(key: key);

  final AsyncValue<T> value;
  final Widget Function(T value) data;
  final String errorMessage;
  final String? retryLabel;
  final AsyncStateLayout layout;
  final String? emptyMessage;
  final bool Function(T value)? isEmpty;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (loadedValue) {
        if (isEmpty?.call(loadedValue) ?? false) {
          return _wrap(_MessageState(message: emptyMessage!));
        }

        return data(loadedValue);
      },
      error: (error, stackTrace) => _wrap(
        _MessageState(
          message: errorMessage,
          icon: Icons.error_outline,
          action: onRetry == null
              ? null
              : TextButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh),
                  label: Text(retryLabel!),
                ),
        ),
      ),
      loading: () => _wrap(_LoadingState(layout: layout)),
    );
  }

  Widget _wrap(Widget child) {
    switch (layout) {
      case AsyncStateLayout.page:
        return Center(child: child);
      case AsyncStateLayout.card:
        return Card(
          elevation: 10,
          child: Padding(padding: EdgeInsets.all(16), child: child),
        );
      case AsyncStateLayout.inline:
        return child;
    }
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.layout});

  final AsyncStateLayout layout;

  @override
  Widget build(BuildContext context) {
    final size = layout == AsyncStateLayout.inline ? 18.0 : 36.0;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 3),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, this.icon, this.action});

  final String message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final messageWidget = Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.black54),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.black45),
          SizedBox(height: 8),
        ],
        messageWidget,
        if (action != null) ...[SizedBox(height: 8), action!],
      ],
    );
  }
}
