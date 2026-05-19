import 'package:flutter/material.dart';
import '../../../core/widgets/shimmer_widget.dart';

class HomeShimmerLoading extends StatelessWidget {
  const HomeShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final theme = Theme.of(context);

        return SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: CustomScrollView(
                physics: const NeverScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 40 : 24, 
                        vertical: isWide ? 40 : 20,
                      ),
                      child: _buildHeaderShimmer(isWide),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: isWide ? 280 : 240,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 24),
                        child: _buildCardShimmer(isWide, theme),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _buildPageIndicatorShimmer(4, theme),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isWide ? 40 : 24, 
                        isWide ? 48 : 32, 
                        isWide ? 40 : 24, 
                        16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerWidget.rectangular(height: 24, width: 180),
                          ShimmerWidget.rectangular(height: 14, width: 60),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 24),
                    sliver: _buildGridShimmer(constraints.maxWidth, theme),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderShimmer(bool isWide) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            ShimmerWidget.rectangular(height: 14, width: 100),
            const SizedBox(height: 6),
            ShimmerWidget.rectangular(height: isWide ? 32 : 26, width: 160),
          ],
        ),
        ShimmerWidget.circular(width: isWide ? 64 : 56, height: isWide ? 64 : 56),
      ],
    );
  }

  Widget _buildCardShimmer(bool isWide, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerWidget.rectangular(height: 14, width: 120),
              ShimmerWidget.circular(width: 20, height: 20),
            ],
          ),
          const SizedBox(height: 24),
          ShimmerWidget.rectangular(height: 36, width: 200),
          const Spacer(),
          Row(
            children: [
              ShimmerWidget.rectangular(height: 20, width: 60),
              const SizedBox(width: 8),
              ShimmerWidget.rectangular(height: 12, width: 80),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPageIndicatorShimmer(int count, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        bool isSelected = 0 == index;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isSelected ? 32 : 8,
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildGridShimmer(double width, ThemeData theme) {
    int crossAxisCount = 2;
    if (width > 1000) {
      crossAxisCount = 4;
    } else if (width > 600) {
      crossAxisCount = 3;
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor.withOpacity(0.1), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerWidget.circular(width: 22, height: 22),
                    ShimmerWidget.rectangular(height: 14, width: 40),
                  ],
                ),
                const Spacer(),
                ShimmerWidget.rectangular(height: 14, width: 80),
                const SizedBox(height: 6),
                ShimmerWidget.rectangular(height: 20, width: 100),
                const SizedBox(height: 8),
                ShimmerWidget.rectangular(height: 10, width: 60),
              ],
            ),
          );
        },
        childCount: 6,
      ),
    );
  }
}
