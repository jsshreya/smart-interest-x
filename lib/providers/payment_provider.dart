import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../services/database_service.dart';

class PaymentProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Payment> _payments = [];

  bool _isLoading = false;

  List<Payment> get payments => _payments;

  bool get isLoading => _isLoading;

  // ------------------------------------------------------------
  // LOAD ALL PAYMENTS
  // ------------------------------------------------------------

  Future<void> loadPayments() async {
    _isLoading = true;
    notifyListeners();

    try {
      _payments = await _databaseService.getAllPayments();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // LOAD PAYMENTS FOR TRANSACTION
  // ------------------------------------------------------------

  Future<void> loadPaymentsForTransaction(int transactionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _payments = await _databaseService.getPaymentsForTransaction(
        transactionId,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // ADD PAYMENT
  // ------------------------------------------------------------

  Future<void> addPayment(Payment payment) async {
    await _databaseService.insertPayment(payment);

    await loadPaymentsForTransaction(payment.transactionId);
  }

  // ------------------------------------------------------------
  // UPDATE PAYMENT
  // ------------------------------------------------------------

  Future<void> updatePayment(Payment payment) async {
    await _databaseService.updatePayment(payment);

    await loadPaymentsForTransaction(payment.transactionId);
  }

  // ------------------------------------------------------------
  // DELETE PAYMENT
  // ------------------------------------------------------------

  Future<void> deletePayment(Payment payment) async {
    if (payment.id == null) {
      return;
    }

    await _databaseService.deletePayment(payment.id!);

    await loadPaymentsForTransaction(payment.transactionId);
  }

  // ------------------------------------------------------------
  // GET TOTAL PAID
  // ------------------------------------------------------------

  Future<double> getTotalPaid(int transactionId) async {
    return await _databaseService.getTotalPaidForTransaction(transactionId);
  }

  Future<List<Payment>> getPaymentsForTransaction(int transactionId) async {
    return await _databaseService.getPaymentsForTransaction(transactionId);
  }
}
