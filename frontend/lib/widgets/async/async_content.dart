import 'package:flutter/material.dart';

/// Shows [loadingBuilder] until [future] completes, then cross-fades to the
/// data or error view. Give it a new future to retry.
class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.future,
    required this.loadingBuilder,
    required this.dataBuilder,
    required this.errorBuilder,
  });

  static const Duration switchDuration = Duration(milliseconds: 220);

  final Future<T> future;
  final WidgetBuilder loadingBuilder;
  final Widget Function(BuildContext context, T data) dataBuilder;
  final Widget Function(BuildContext context, Object error) errorBuilder;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        return AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : switchDuration,
          layoutBuilder: _topAlignedLayout,
          child: _childFor(context, snapshot),
        );
      },
    );
  }

  Widget _childFor(BuildContext context, AsyncSnapshot<T> snapshot) {
    // A new future keeps the previous result in the snapshot until it settles,
    // so the connection state is checked first.
    if (snapshot.connectionState != ConnectionState.done) {
      return KeyedSubtree(key: const ValueKey('loading'), child: loadingBuilder(context));
    }

    final Object? error = snapshot.error;
    if (error != null) {
      return KeyedSubtree(key: const ValueKey('error'), child: errorBuilder(context, error));
    }

    return KeyedSubtree(key: const ValueKey('data'), child: dataBuilder(context, snapshot.data as T));
  }

  static Widget _topAlignedLayout(Widget? currentChild, List<Widget> previousChildren) {
    // passthrough keeps the parent's constraints, so a page body stays tight
    // and a section inside a scroll view stays unbounded. The view fading out
    // is inert: no second tap on its buttons and not read by screen readers.
    return Stack(
      alignment: Alignment.topCenter,
      fit: StackFit.passthrough,
      children: [
        for (final Widget previous in previousChildren) _inert(previous, inert: true),
        if (currentChild != null) _inert(currentChild, inert: false),
      ],
    );
  }

  // Every child gets the same wrapper, keyed like the child, so a view that
  // starts fading out keeps its State instead of being rebuilt from scratch.
  static Widget _inert(Widget child, {required bool inert}) {
    return IgnorePointer(
      key: child.key,
      ignoring: inert,
      child: ExcludeSemantics(excluding: inert, child: child),
    );
  }
}
