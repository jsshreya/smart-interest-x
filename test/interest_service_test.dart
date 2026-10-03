import 'package:flutter_test/flutter_test.dart';

import 'package:smart_interest_x/services/interest_service.dart';

void main() {
  group('InterestService Tests', () {
    test('Calculates monthly simple interest correctly', () {
      final startDate = DateTime(2026, 1, 1);

      final endDate = DateTime(2026, 4, 1);

      final interest = InterestService.calculateSimpleInterest(
        principal: 50000,
        annualRate: 2,
        startDate: startDate,
        endDate: endDate,
        interestPeriod: 'monthly',
      );

      expect(InterestService.roundAmount(interest), 3000.00);
    });

    test('Calculates total amount correctly', () {
      final total = InterestService.calculateTotalAmount(
        principal: 50000,
        interest: 3000,
      );

      expect(total, 53000);
    });

    test('Returns zero interest when end date is before start date', () {
      final startDate = DateTime(2026, 5, 1);

      final endDate = DateTime(2026, 4, 1);

      final interest = InterestService.calculateSimpleInterest(
        principal: 50000,
        annualRate: 2,
        startDate: startDate,
        endDate: endDate,
        interestPeriod: 'monthly',
      );

      expect(interest, 0);
    });
  });
}
