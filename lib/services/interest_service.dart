class InterestService {
  // ------------------------------------------------------------
  // CALCULATE SIMPLE INTEREST
  // ------------------------------------------------------------

  static double calculateSimpleInterest({
    required double principal,
    required double annualRate,
    required DateTime startDate,
    DateTime? endDate,
    required String interestPeriod,
  }) {
    final calculationEndDate = endDate ?? DateTime.now();

    if (calculationEndDate.isBefore(startDate)) {
      return 0;
    }

    final days = calculationEndDate.difference(startDate).inDays;

    double timeInYears;

    if (interestPeriod.toLowerCase() == 'monthly') {
      // Convert days into approximate months.
      final months = days / 30;

      // Monthly rate is supplied by the user.
      final monthlyRate = annualRate / 100;

      return principal * monthlyRate * months;
    }

    if (interestPeriod.toLowerCase() == 'yearly') {
      timeInYears = days / 365;

      final yearlyRate = annualRate / 100;

      return principal * yearlyRate * timeInYears;
    }

    return 0;
  }

  // ------------------------------------------------------------
  // CALCULATE TOTAL AMOUNT
  // ------------------------------------------------------------

  static double calculateTotalAmount({
    required double principal,
    required double interest,
  }) {
    return principal + interest;
  }

  // ------------------------------------------------------------
  // CALCULATE NUMBER OF DAYS
  // ------------------------------------------------------------

  static int calculateDays({required DateTime startDate, DateTime? endDate}) {
    final calculationEndDate = endDate ?? DateTime.now();

    if (calculationEndDate.isBefore(startDate)) {
      return 0;
    }

    return calculationEndDate.difference(startDate).inDays;
  }

  // ------------------------------------------------------------
  // CALCULATE INTEREST TILL TODAY
  // ------------------------------------------------------------

  static double calculateInterestTillToday({
    required double principal,
    required double rate,
    required DateTime startDate,
    required String interestPeriod,
  }) {
    return calculateSimpleInterest(
      principal: principal,
      annualRate: rate,
      startDate: startDate,
      endDate: DateTime.now(),
      interestPeriod: interestPeriod,
    );
  }

  // ------------------------------------------------------------
  // CALCULATE INTEREST TILL DUE DATE
  // ------------------------------------------------------------

  static double calculateInterestTillDueDate({
    required double principal,
    required double rate,
    required DateTime startDate,
    required DateTime dueDate,
    required String interestPeriod,
  }) {
    return calculateSimpleInterest(
      principal: principal,
      annualRate: rate,
      startDate: startDate,
      endDate: dueDate,
      interestPeriod: interestPeriod,
    );
  }

  // ------------------------------------------------------------
  // FORMAT AMOUNT
  // ------------------------------------------------------------

  static double roundAmount(double amount) {
    return double.parse(amount.toStringAsFixed(2));
  }
}
