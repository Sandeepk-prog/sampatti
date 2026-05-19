import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class TransactionTableWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const TransactionTableWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> transactions = data["props"]['transactions'] ?? [];
    final String title = data['title'] ?? 'Recent Transactions';

    if (transactions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No transactions to display.'),
        ),
      );
    }

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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.list_alt_rounded, color: AppColors.primary, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(child: Text(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                )),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              horizontalMargin: 20,
              headingRowHeight: 40,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 60,
              headingTextStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
              columns: const [
                DataColumn(label: Text('DATE')),
                DataColumn(label: Text('DESCRIPTION')),
                DataColumn(label: Text('AMOUNT')),
              ],
              rows: transactions.map((t) {
                final typeStr = (t['type'] ?? '').toString().toLowerCase();
                final isDebit = typeStr == 'debit' || typeStr == 'dr' || typeStr == 'outbound';
                
                // Handle both 'amount' and 'amt' keys, and ensure it's a double
                final dynamic rawAmount = t['amount'] ?? t['amt'] ?? 0.0;
                final double amount = (rawAmount is num) ? rawAmount.toDouble().abs() : double.tryParse(rawAmount.toString().replaceAll(RegExp(r'[^0-9.]'), ''))?.abs() ?? 0.0;
                
                final dateStr = t['date'] ?? '';
                final description = t['description'] ?? t['desc'] ?? 'No Description';
                
                return DataRow(
                  cells: [
                    DataCell(Text(
                      dateStr,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                    )),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          description,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(
                      '${isDebit ? "-" : "+"}₹$amount',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDebit ? AppColors.error : AppColors.success,
                      ),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
