import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../models/payment.dart';
import '../models/transaction.dart';

class ExportService {
  static Future<String> exportTransactions({
    required List<LoanTransaction> transactions,
    required List<Payment> payments,
  }) async {
    final rows = <List<dynamic>>[
      [
        'Transaction ID',
        'Person ID',
        'Amount',
        'Type',
        'Interest Rate',
        'Interest Period',
        'Start Date',
        'Due Date',
        'Note',
        'Status',
        'Payment Amount',
        'Payment Date',
        'Payment Mode',
        'Payment Note',
        'Proof Path',
      ],
    ];

    for (final transaction in transactions) {
      final transactionPayments = payments
          .where((payment) => payment.transactionId == transaction.id)
          .toList();

      if (transactionPayments.isEmpty) {
        rows.add([
          transaction.id,
          transaction.personId,
          transaction.amount,
          transaction.type,
          transaction.interestRate,
          transaction.interestPeriod,
          transaction.startDate.toIso8601String(),
          transaction.dueDate?.toIso8601String() ?? '',
          transaction.note ?? '',
          transaction.status,
          '',
          '',
          '',
          '',
          '',
        ]);
      } else {
        for (final payment in transactionPayments) {
          rows.add([
            transaction.id,
            transaction.personId,
            transaction.amount,
            transaction.type,
            transaction.interestRate,
            transaction.interestPeriod,
            transaction.startDate.toIso8601String(),
            transaction.dueDate?.toIso8601String() ?? '',
            transaction.note ?? '',
            transaction.status,
            payment.amount,
            payment.paymentDate.toIso8601String(),
            payment.mode,
            payment.note ?? '',
            payment.proofPath ?? '',
          ]);
        }
      }
    }

    // Convert rows into CSV text.
    final String csvData = csv.encode(rows);

    final directory = await getApplicationDocumentsDirectory();

    final fileName =
        'smart_interest_x_${DateTime.now().millisecondsSinceEpoch}.csv';

    final file = File('${directory.path}/$fileName');

    await file.writeAsString(csvData);

    return file.path;
  }
}
