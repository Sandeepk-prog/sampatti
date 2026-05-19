/// A model representing a single bank transaction extracted from a PDF statement.
class Transaction {
  final String date;
  final String description;
  final double debit;
  final double credit;
  final double balance;

  Transaction({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  /// Converts the transaction to a JSON map.
  Map<String, dynamic> toJson() => {
        "date": date,
        "description": description,
        "debit": debit,
        "credit": credit,
        "balance": balance,
      };

  @override
  String toString() {
    return 'Transaction(date: $date, desc: ${description.length > 20 ? description.substring(0, 20) : description}, debit: $debit, credit: $credit, bal: $balance)';
  }
}
