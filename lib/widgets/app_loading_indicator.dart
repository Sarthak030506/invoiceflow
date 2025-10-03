import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../theme/app_theme.dart';

/// Centralized loading indicator widget for consistent loading states across the app
/// Provides various loading styles: circular, shimmer, skeleton, and inline loaders
class AppLoadingIndicator extends StatelessWidget {
  final LoadingType type;
  final String? message;
  final Color? color;
  final double? size;

  const AppLoadingIndicator({
    Key? key,
    this.type = LoadingType.circular,
    this.message,
    this.color,
    this.size,
  }) : super(key: key);

  /// Centered circular progress indicator for full-screen loading
  const AppLoadingIndicator.centered({
    Key? key,
    this.message,
    this.color,
    this.size,
  })  : type = LoadingType.circular,
        super(key: key);

  /// Shimmer skeleton loader for list items
  const AppLoadingIndicator.shimmer({
    Key? key,
    this.message,
    this.color,
    this.size,
  })  : type = LoadingType.shimmer,
        super(key: key);

  /// Inline loader for pagination or infinite scroll
  const AppLoadingIndicator.inline({
    Key? key,
    this.message,
    this.color,
    this.size,
  })  : type = LoadingType.inline,
        super(key: key);

  /// Small loader for buttons or compact spaces
  const AppLoadingIndicator.small({
    Key? key,
    this.message,
    this.color,
    this.size,
  })  : type = LoadingType.small,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingColor = color ?? theme.colorScheme.primary;

    switch (type) {
      case LoadingType.circular:
        return _buildCenteredLoader(theme, loadingColor);
      case LoadingType.shimmer:
        return _buildShimmerLoader(theme);
      case LoadingType.inline:
        return _buildInlineLoader(theme, loadingColor);
      case LoadingType.small:
        return _buildSmallLoader(theme, loadingColor);
    }
  }

  Widget _buildCenteredLoader(ThemeData theme, Color loadingColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 2.h),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerLoader(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      padding: EdgeInsets.all(3.w),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 2.h),
        child: _ShimmerCard(),
      ),
    );
  }

  Widget _buildInlineLoader(ThemeData theme, Color loadingColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Center(
        child: SizedBox(
          width: size ?? 24,
          height: size ?? 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallLoader(ThemeData theme, Color loadingColor) {
    return SizedBox(
      width: size ?? 20,
      height: size ?? 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
      ),
    );
  }
}

/// Shimmer card skeleton for list loading states
class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildShimmerBox(12.w, 12.w, baseColor, highlightColor),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(40.w, 2.h, baseColor, highlightColor),
                        SizedBox(height: 1.h),
                        _buildShimmerBox(30.w, 1.5.h, baseColor, highlightColor),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _buildShimmerBox(double.infinity, 1.5.h, baseColor, highlightColor),
              SizedBox(height: 1.h),
              _buildShimmerBox(60.w, 1.5.h, baseColor, highlightColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox(
    double width,
    double height,
    Color baseColor,
    Color highlightColor,
  ) {
    final gradientPosition = _controller.value * 3 - 1.5;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: [
            (gradientPosition - 0.3).clamp(0.0, 1.0),
            gradientPosition.clamp(0.0, 1.0),
            (gradientPosition + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for specific content layouts
class SkeletonLoader extends StatelessWidget {
  final SkeletonType type;

  const SkeletonLoader({
    Key? key,
    required this.type,
  }) : super(key: key);

  /// Invoice list skeleton
  const SkeletonLoader.invoiceList({Key? key})
      : type = SkeletonType.invoiceList,
        super(key: key);

  /// Customer card skeleton
  const SkeletonLoader.customerCard({Key? key})
      : type = SkeletonType.customerCard,
        super(key: key);

  /// Analytics dashboard skeleton
  const SkeletonLoader.analytics({Key? key})
      : type = SkeletonType.analytics,
        super(key: key);

  /// Detail page skeleton
  const SkeletonLoader.detail({Key? key})
      : type = SkeletonType.detail,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    switch (type) {
      case SkeletonType.invoiceList:
        return _buildInvoiceListSkeleton(context, baseColor, highlightColor);
      case SkeletonType.customerCard:
        return _buildCustomerCardSkeleton(context, baseColor, highlightColor);
      case SkeletonType.analytics:
        return _buildAnalyticsSkeleton(context, baseColor, highlightColor);
      case SkeletonType.detail:
        return _buildDetailSkeleton(context, baseColor, highlightColor);
    }
  }

  Widget _buildInvoiceListSkeleton(
    BuildContext context,
    Color baseColor,
    Color highlightColor,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      padding: EdgeInsets.all(3.w),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 2.h),
        child: _ShimmerCard(),
      ),
    );
  }

  Widget _buildCustomerCardSkeleton(
    BuildContext context,
    Color baseColor,
    Color highlightColor,
  ) {
    return _ShimmerCard();
  }

  Widget _buildAnalyticsSkeleton(
    BuildContext context,
    Color baseColor,
    Color highlightColor,
  ) {
    return Column(
      children: List.generate(3, (index) =>
        Padding(
          padding: EdgeInsets.only(bottom: 2.h),
          child: _ShimmerCard(),
        ),
      ),
    );
  }

  Widget _buildDetailSkeleton(
    BuildContext context,
    Color baseColor,
    Color highlightColor,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: List.generate(4, (index) =>
          Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: _ShimmerCard(),
          ),
        ),
      ),
    );
  }
}

enum LoadingType {
  circular,
  shimmer,
  inline,
  small,
}

enum SkeletonType {
  invoiceList,
  customerCard,
  analytics,
  detail,
}
