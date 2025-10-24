import 'package:flutter/material.dart';
import '../../../widgets/app_loading_indicator.dart';

/// Reusable widget for showing loading state in analytics modals
/// Shows loader while data is fetching, then displays the data
class AnalyticsModalContent extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingMessage;

  const AnalyticsModalContent({
    Key? key,
    required this.isLoading,
    required this.child,
    this.loadingMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: AppLoadingIndicator.centered(
          message: loadingMessage ?? 'Loading analytics...',
        ),
      );
    }

    return child;
  }
}

/// Future builder wrapper for analytics modals with loading state
class AnalyticsModalFuture<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final String? loadingMessage;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const AnalyticsModalFuture({
    Key? key,
    required this.future,
    required this.builder,
    this.loadingMessage,
    this.errorBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: AppLoadingIndicator.centered(
              message: loadingMessage ?? 'Loading analytics...',
            ),
          );
        }

        if (snapshot.hasError) {
          if (errorBuilder != null) {
            return errorBuilder!(context, snapshot.error!);
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No data available',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        return builder(context, snapshot.data as T);
      },
    );
  }
}
