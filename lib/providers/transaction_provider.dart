import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/database_service.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<LoanTransaction> _transactions = [];

  bool _isLoading = false;

  List<LoanTransaction> get transactions => _transactions;

  bool get isLoading => _isLoading;

  // ------------------------------------------------------------
  // LOAD ALL TRANSACTIONS
  // ------------------------------------------------------------

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _databaseService.getAllTransactions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // LOAD TRANSACTIONS FOR PERSON
  // ------------------------------------------------------------

  Future<List<LoanTransaction>> getTransactionsForPerson(int personId) async {
    return await _databaseService.getTransactionsForPerson(personId);
  }

  // ------------------------------------------------------------
  // ADD TRANSACTION
  // ------------------------------------------------------------

  Future<void> addTransaction(LoanTransaction transaction) async {
    await _databaseService.insertTransaction(transaction);

    await loadTransactions();
  }

  // ------------------------------------------------------------
  // UPDATE TRANSACTION
  // ------------------------------------------------------------

  Future<void> updateTransaction(LoanTransaction transaction) async {
    await _databaseService.updateTransaction(transaction);

    await loadTransactions();
  }

  // ------------------------------------------------------------
  // DELETE TRANSACTION
  // ------------------------------------------------------------

  Future<void> deleteTransaction(int id) async {
    await _databaseService.deleteTransaction(id);

    await loadTransactions();
  }
}
