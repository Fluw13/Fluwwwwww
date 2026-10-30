import 'package:flutter/material.dart';

/// Fades the incoming page in while it slides a short distance from the right,
/// so the destination and its loading state are visible right away.
/// Replaces Android's predictive-back transition; predictive back is not
/// enabled in the app manifest, so nothing is lost today.
class FluwPageTransitionsBuilder extends PageTransitionsBuilder {
  const FluwPageTransitionsBuilder();

  static const Offset _startOffset = Offset(0.06, 0);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: _startOffset, end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
