import '../models/investment_summary.dart';
import '../models/investment_holding.dart';

abstract class InvestmentRepository {
  Future<List<InvestmentSummary>> getInvestmentSummaries(String userId, String memberId);
  Future<List<InvestmentHolding>> getInvestmentHoldings(String userId, String memberId, String type);
  Future<bool> checkInvestmentDataExists(String userId);
  Future<void> seedSampleInvestmentData(String userId);
}
