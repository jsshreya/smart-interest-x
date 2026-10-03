import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/payment.dart';
import '../../models/person.dart';
import '../../models/transaction.dart';
import '../../providers/payment_provider.dart';
import '../../providers/person_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/transaction_status.dart';
import '../payments/add_payment_screen.dart';
import 'add_transaction_screen.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final LoanTransaction transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  LoanTransaction get transaction => widget.transaction;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final personProvider = context.watch<PersonProvider>();

    final person = _findPerson(personProvider.people, transaction.personId);

    final isGiven = transaction.type.toLowerCase() == 'given';

    final color = isGiven ? Colors.blue : Colors.orange;

    final interest = _calculateInterestPreview();

    final total = transaction.amount + interest;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showDeleteConfirmation(context);
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPersonHeader(person, isGiven, color),

            const SizedBox(height: 24),

            _buildAmountCard(transaction, interest, total, color),

            const SizedBox(height: 24),

            _buildPaymentSummary(total, color),

            const SizedBox(height: 28),

            _buildSectionTitle('Transaction Information'),

            const SizedBox(height: 12),

            _buildDetailsCard(),

            if (transaction.note != null &&
                transaction.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 24),

              _buildSectionTitle('Notes'),

              const SizedBox(height: 12),

              _buildNotesCard(),
            ],

            const SizedBox(height: 28),

            _buildSectionTitle('Payment History'),

            const SizedBox(height: 12),

            _buildPaymentHistory(),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: transaction.id == null ? null : _openAddPayment,
                icon: const Icon(Icons.add_card_rounded),
                label: const Text(
                  'Add Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // EDIT TRANSACTION
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: transaction.id == null ? null : _openEditTransaction,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Transaction'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton.icon(
                onPressed: () {
                  _showDeleteConfirmation(context);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                label: const Text(
                  'Delete Transaction',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EDIT TRANSACTION
  // ============================================================

  Future<void> _openEditTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(transaction: transaction),
      ),
    );

    if (result == true && mounted) {
      await context.read<TransactionProvider>().loadTransactions();

      final updatedTransaction = context
          .read<TransactionProvider>()
          .transactions
          .where((item) => item.id == transaction.id)
          .firstOrNull;

      if (updatedTransaction != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TransactionDetailsScreen(transaction: updatedTransaction),
          ),
        );
      }
    }
  }

  // ============================================================
  // ADD PAYMENT
  // ============================================================

  Future<void> _openAddPayment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPaymentScreen(transactionId: transaction.id!),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // PAYMENT SUMMARY
  // ============================================================

  Widget _buildPaymentSummary(double total, Color color) {
    return FutureBuilder<double>(
      future: context.read<PaymentProvider>().getTotalPaid(transaction.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(color: color)),
            ),
          );
        }

        final paid = snapshot.data ?? 0;

        final remaining = (total - paid).clamp(0, total);

        final status = TransactionStatus.calculate(
          transaction: transaction,
          totalPaid: paid,
        );

        final isPaid = status == TransactionStatus.paid;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _statusIcon(status),
                      color: _statusColor(status),
                      size: 25,
                    ),

                    const SizedBox(width: 10),

                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(status),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: _summaryItem('Total Due', total)),

                    Expanded(child: _summaryItem('Paid', paid)),

                    Expanded(
                      child: _summaryItem(
                        'Remaining',
                        remaining.toDouble(),
                        highlight: !isPaid,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: total <= 0 ? 0 : (paid / total).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPaid ? Colors.green : color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    switch (status) {
      case TransactionStatus.paid:
        return Colors.green;

      case TransactionStatus.overdue:
        return Colors.red;

      case TransactionStatus.partiallyPaid:
        return Colors.orange;

      case TransactionStatus.active:
      default:
        return Colors.blue;
    }
  }

  // ============================================================
  // STATUS ICON
  // ============================================================

  IconData _statusIcon(String status) {
    switch (status) {
      case TransactionStatus.paid:
        return Icons.check_circle_rounded;

      case TransactionStatus.overdue:
        return Icons.warning_rounded;

      case TransactionStatus.partiallyPaid:
        return Icons.timelapse_rounded;

      case TransactionStatus.active:
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  // ============================================================
  // SUMMARY ITEM
  // ============================================================

  Widget _summaryItem(String title, double amount, {bool highlight = false}) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 5),

        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: highlight ? Colors.orange : null,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAYMENT HISTORY
  // ============================================================

  Widget _buildPaymentHistory() {
    return FutureBuilder<List<Payment>>(
      future: context.read<PaymentProvider>().getPaymentsForTransaction(
        transaction.id!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildNoPayments('Unable to load payments.');
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return _buildNoPayments('No payments recorded yet.');
        }

        return Column(
          children: payments.map((payment) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildPaymentCard(payment),
            );
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // PAYMENT CARD
  // ============================================================

  Widget _buildPaymentCard(Payment payment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.10),
              ),
              child: const Icon(
                Icons.arrow_downward_rounded,
                color: Colors.green,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${payment.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    payment.mode,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    _formatDate(payment.paymentDate),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),

                  if (payment.note != null &&
                      payment.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Text(payment.note!, style: const TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deletePayment(payment);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NO PAYMENTS
  // ============================================================

  Widget _buildNoPayments(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 40,
                color: Colors.grey.shade500,
              ),

              const SizedBox(height: 10),

              Text(message, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DELETE PAYMENT
  // ============================================================

  Future<void> _deletePayment(Payment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Payment?'),
          content: const Text(
            'This payment record will be permanently removed.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await context.read<PaymentProvider>().deletePayment(payment);

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // PERSON HEADER
  // ============================================================

  Widget _buildPersonHeader(Person? person, bool isGiven, Color color) {
    final name = person?.name ?? 'Unknown Person';

    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color.withOpacity(0.10),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isGiven ? 'Money Given' : 'Money Taken',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AMOUNT CARD
  // ============================================================

  Widget _buildAmountCard(
    LoanTransaction transaction,
    double interest,
    double total,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: color.withOpacity(0.07),
      ),
      child: Column(
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 6),

          Text(
            '₹${total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _amountInfo('Principal', transaction.amount)),

              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withOpacity(0.3),
              ),

              Expanded(child: _amountInfo('Interest', interest)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountInfo(String title, double amount) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 4),

        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ============================================================
  // DETAILS CARD
  // ============================================================

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _detailRow(
              'Transaction Type',
              transaction.type,
              Icons.swap_vert_rounded,
            ),

            _detailRow(
              'Interest Rate',
              '${transaction.interestRate}%',
              Icons.percent_rounded,
            ),

            _detailRow(
              'Interest Period',
              transaction.interestPeriod,
              Icons.schedule_outlined,
            ),

            _detailRow(
              'Start Date',
              _formatDate(transaction.startDate),
              Icons.play_circle_outline,
            ),

            if (transaction.dueDate != null)
              _detailRow(
                'Due Date',
                _formatDate(transaction.dueDate!),
                Icons.event_outlined,
              ),

            _detailRow('Status', transaction.status, Icons.flag_outlined),

            _detailRow(
              'Created',
              _formatDate(transaction.createdAt),
              Icons.access_time_rounded,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),

          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTES
  // ============================================================

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notes_rounded),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                transaction.note!,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }

  // ============================================================
  // FIND PERSON
  // ============================================================

  Person? _findPerson(List<Person> people, int personId) {
    for (final person in people) {
      if (person.id == personId) {
        return person;
      }
    }

    return null;
  }

  // ============================================================
  // INTEREST
  // ============================================================

  double _calculateInterestPreview() {
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

  // ============================================================
  // DELETE TRANSACTION
  // ============================================================

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Transaction?'),
          content: const Text('This transaction will be permanently removed.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () async {
                if (transaction.id != null) {
                  await context.read<TransactionProvider>().deleteTransaction(
                    transaction.id!,
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthName(date.month)} '
        '${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}
