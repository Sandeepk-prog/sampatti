import 'package:flutter/material.dart';
import '../../../core/widgets/shimmer_widget.dart';

class InvestmentsShimmer extends StatelessWidget {
  final String selectedTab;

  const InvestmentsShimmer({
    super.key,
    required this.selectedTab,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedTab == 'Mutual Funds' || selectedTab == 'Equity') {
      return const FundsShimmer();
    }
    return const DashboardShimmer();
  }
}

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerWidget.rectangular(height: 20, width: 180),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const ShimmerWidget.circular(height: 240, width: 240),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerRight,
                child: ShimmerWidget.rounded(height: 30, width: 150),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(
                  4,
                  (index) => const ShimmerWidget.rounded(height: 36, width: 100),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const ShimmerWidget.rectangular(height: 20, width: 180),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerWidget.rectangular(height: 16, width: 120),
                        SizedBox(height: 4),
                        ShimmerWidget.rectangular(height: 12, width: 80),
                      ],
                    ),
                    const ShimmerWidget.rectangular(height: 16, width: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FundsShimmer extends StatelessWidget {
  const FundsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Portfolio Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerWidget.rectangular(height: 18, width: 80),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  ShimmerWidget.rectangular(height: 24, width: 120),
                  SizedBox(height: 4),
                  ShimmerWidget.rectangular(height: 12, width: 80),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Allocation Section
        const ShimmerWidget.rectangular(height: 20, width: 180),
        const SizedBox(height: 16),
        const ShimmerWidget.rectangular(height: 24),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(
            3,
            (index) => Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                ShimmerWidget.circular(height: 12, width: 12),
                SizedBox(width: 8),
                ShimmerWidget.rectangular(height: 14, width: 60),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Funds List
        Column(
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerWidget.rounded(height: 18, width: 60),
                        SizedBox(height: 8),
                        ShimmerWidget.rectangular(height: 16, width: 150),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      ShimmerWidget.rectangular(height: 18, width: 80),
                      SizedBox(height: 4),
                      ShimmerWidget.rectangular(height: 12, width: 70),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
