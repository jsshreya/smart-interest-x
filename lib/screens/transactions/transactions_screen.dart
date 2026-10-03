import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/person.dart';
import '../../models/transaction.dart';
import '../../providers/person_provider.dart';
import '../../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';
import 'transaction_details_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    await Future.wait([
      context.read<PersonProvider>().loadPeople(),
      context.read<TransactionProvider>().loadTransactions(),
    ]);
  }

  // ============================================================
  // ADD TRANSACTION
  // ============================================================

  Future<void> _openAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );

    if (result == true && mounted) {
      await context.read<TransactionProvider>().loadTransactions();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _openAddTransaction,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Transaction',
          ),
        ],
      ),

      body: Consumer2<PersonProvider, TransactionProvider>(
        builder: (context, personProvider, transactionProvider, child) {
          if (personProvider.isLoading || transactionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = _filteredTransactions(
            transactionProvider.transactions,
          );

          if (transactionProvider.transactions.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildFilterBar(),

              Expanded(
                child: transactions.isEmpty
                    ? _buildNoFilterResults()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                          itemCount: transactions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];

                            final person = _findPerson(
                              personProvider.people,
                              transaction.personId,
                            );

                            return _buildTransactionCard(transaction, person);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          _filterChip('All'),
          const SizedBox(width: 8),
          _filterChip('Given'),
          const SizedBox(width: 8),
          _filterChip('Taken'),
          const SizedBox(width: 8),
          _filterChip('Active'),
          const SizedBox(width: 8),
          _filterChip('Completed'),
          const SizedBox(width: 8),
          _filterChip('Overdue'),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget _filterChip(String value) {
    final selected = _filter == value;

    return ChoiceChip(
      label: Text(value),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _filter = value;
        });
      },
    );
  }

  // ============================================================
  // FILTER TRANSACTIONS
  // ============================================================

  List<LoanTransaction> _filteredTransactions(
    List<LoanTransaction> transactions,
  ) {
    if (_filter == 'All') {
      return transactions;
    }

    return transactions.where((transaction) {
      final type = transaction.type.toLowerCase();

      final status = transaction.status.toLowerCase();

      return type == _filter.toLowerCase() || status == _filter.toLowerCase();
    }).toList();
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
  // TRANSACTION CARD
  // ============================================================

  Widget _buildTransactionCard(LoanTransaction transaction, Person? person) {
    final bool isGiven = transaction.type.toLowerCase() == 'given';

    final Color color = isGiven ? Colors.blue : Colors.orange;

    final String personName = person?.name ?? 'Unknown Person';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TransactionDetailsScreen(transaction: transaction),
            ),
          );

          if (mounted) {
            await context.read<TransactionProvider>().loadTransactions();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.10),
                    child: Icon(
                      isGiven
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: color,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          personName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          isGiven ? 'Money Given' : 'Money Taken',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    '₹${transaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Divider(),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _infoItem(
                      'Interest',
                      '${transaction.interestRate}%',
                    ),
                  ),

                  Expanded(
                    child: _infoItem('Period', transaction.interestPeriod),
                  ),

                  Expanded(child: _infoItem('Status', transaction.status)),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.play_circle_outline_rounded, size: 16),

                  const SizedBox(width: 8),

                  Text(
                    'Started: ${_formatDate(transaction.startDate)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),

              if (transaction.dueDate != null) ...[
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16),

                    const SizedBox(width: 8),

                    Text(
                      'Due: ${_formatDate(transaction.dueDate!)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],

              if (transaction.note != null &&
                  transaction.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_rounded, size: 17),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          transaction.note!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _infoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.55),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'No Transactions Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            Text(
              'Your loans and interest records will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _openAddTransaction,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NO FILTER RESULTS
  // ============================================================

  Widget _buildNoFilterResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 60,
              color: Colors.grey.shade500,
            ),

            const SizedBox(height: 16),

            const Text(
              'No Matching Transactions',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            Text(
              'There are no transactions under the "$_filter" filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
