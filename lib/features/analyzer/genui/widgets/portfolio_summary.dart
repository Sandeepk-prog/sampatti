import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class PortfolioSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const PortfolioSummaryWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final double totalValue = _parseDouble(data["props"]['totalValue']);
    final double totalInvestment = _parseDouble(data["props"]['totalInvestment']);
    final double xirr = _parseDouble(data['xirr']);
    final List<dynamic> topHoldings = data['topHoldings'] ?? [];

    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isProfit = totalValue >= totalInvestment;
    final absReturns = totalValue - totalInvestment;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.chartPie, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Portfolio Summary',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          // Total Value
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Value',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormatter.format(totalValue),
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isProfit ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProfit ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                            color: isProfit ? AppColors.success : AppColors.error,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${currencyFormatter.format(absReturns.abs())} (${((absReturns / (totalInvestment == 0 ? 1 : totalInvestment)) * 100).toStringAsFixed(2)}%)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isProfit ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (xirr > 0)
                      Text(
                        'XIRR: ${xirr.toStringAsFixed(2)}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(20),
            child: Divider(height: 1),
          ),

          // Top Holdings
          if (topHoldings.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Top Holdings',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...topHoldings.map((holding) {
              final name = holding['name'] ?? 'Unknown';
              final value = _parseDouble(holding['value']);
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      currencyFormatter.format(value),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
    }
    return 0.0;
  }
}
