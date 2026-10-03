import '../models/transaction.dart';

class TransactionStatus {
  static const String active = 'Active';

  static const String partiallyPaid = 'Partially Paid';

  static const String paid = 'Paid';

  static const String overdue = 'Overdue';

  static String calculate({
    required LoanTransaction transaction,
    required double totalPaid,
  }) {
    final totalDue = _calculateTotalDue(transaction);

    final remaining = totalDue - totalPaid;

    // ---------------------------------------------
    // FULLY PAID
    // ---------------------------------------------

    if (remaining <= 0) {
      return paid;
    }

    // ---------------------------------------------
    // OVERDUE
    // ---------------------------------------------

    if (transaction.dueDate != null &&
        DateTime.now().isAfter(transaction.dueDate!)) {
      return overdue;
    }

    // ---------------------------------------------
    // PARTIALLY PAID
    // ---------------------------------------------

    if (totalPaid > 0) {
      return partiallyPaid;
    }

    // ---------------------------------------------
    // ACTIVE
    // ---------------------------------------------

    return active;
  }

  static double calculateTotalDue(LoanTransaction transaction) {
    return _calculateTotalDue(transaction);
  }

  static double _calculateTotalDue(LoanTransaction transaction) {
    final interest = _calculateInterest(transaction);

    return transaction.amount + interest;
  }

  static double _calculateInterest(LoanTransaction transaction) {
    if (transaction.interestRate <= 0) {
      return 0;
    }

    final endDate = transaction.dueDate ?? DateTime.now();

    final days = endDate.difference(transaction.startDate).inDays;

    if (days <= 0) {
      return 0;
    }

    if (transaction.interestPeriod.toLowerCase() == 'monthly') {
      final months = days / 30;

      return transaction.amount * (transaction.interestRate / 100) * months;
    }

    final years = days / 365;

    return transaction.amount * (transaction.interestRate / 100) * years;
  }
}
