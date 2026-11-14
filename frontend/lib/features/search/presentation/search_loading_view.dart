import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// The free server can take about a minute to wake up; after a few seconds the wait is explained.
class SearchLoadingView extends StatefulWidget {
  const SearchLoadingView({super.key});

  static const Duration slowAfter = Duration(seconds: 4);

  @override
  State<SearchLoadingView> createState() => _SearchLoadingViewState();
}

class _SearchLoadingViewState extends State<SearchLoadingView> {
  late final Timer _timer;
  bool _isSlow = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SearchLoadingView.slowAfter, () => setState(() => _isSlow = true));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          if (_isSlow) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Máy chủ đang khởi động, lần đầu có thể mất khoảng 1 phút.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
