import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders the loading / error / empty / data states for an [AsyncValue]
/// holding a list, so each encyclopedia tab doesn't repeat this boilerplate.
class AsyncListView<T> extends StatelessWidget {
  const AsyncListView({
    super.key,
    required this.value,
    required this.builder,
    required this.emptyMessage,
  });

  final AsyncValue<List<T>> value;
  final Widget Function(BuildContext context, List<T> items) builder;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(child: Text(emptyMessage));
        }
        return builder(context, items);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Impossible de charger les données : $error', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
