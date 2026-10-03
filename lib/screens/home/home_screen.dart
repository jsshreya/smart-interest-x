import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/person.dart';
import '../../models/transaction.dart';
import '../../providers/payment_provider.dart';
import '../../providers/person_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/transaction_status.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transaction_details_screen.dart';
import '../transactions/transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  Future<void> _loadDashboard() async {
    await Future.wait([
      context.read<PersonProvider>().loadPeople(),
      context.read<TransactionProvider>().loadTransactions(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionProvider = context.watch<TransactionProvider>();
    final personProvider = context.watch<PersonProvider>();

    if (transactionProvider.isLoading || personProvider.isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final transactions = transactionProvider.transactions;
    final people = personProvider.people;

    return Scaffold(
      appBar: _buildAppBar(),

      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning 👋',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 4),

              Text(
                'Here is your financial overview',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 24),

              FutureBuilder<DashboardStats>(
                future: _calculateDashboardStats(transactions),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildDashboardError();
                  }

                  final stats = snapshot.data ?? DashboardStats.empty();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCard(context, stats),

                      const SizedBox(height: 24),

                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Given',
                              amount: _money(stats.totalGiven),
                              icon: Icons.arrow_upward_rounded,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Taken',
                              amount: _money(stats.totalTaken),
                              icon: Icons.arrow_downward_rounded,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Interest Earned',
                              amount: _money(stats.interestEarned),
                              icon: Icons.trending_up_rounded,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Interest Paid',
                              amount: _money(stats.interestPaid),
                              icon: Icons.trending_down_rounded,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Outstanding',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 14),

                      _buildOutstandingCard(
                        context,
                        title: 'Receivables',
                        subtitle: 'Money others owe you',
                        amount: _money(stats.receivable),
                        icon: Icons.call_received_rounded,
                        color: Colors.green,
                      ),

                      const SizedBox(height: 12),

                      _buildOutstandingCard(
                        context,
                        title: 'Payables',
                        subtitle: 'Money you owe others',
                        amount: _money(stats.payable),
                        icon: Icons.call_made_rounded,
                        color: Colors.red,
                      ),

                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: _openTransactions,
                            child: const Text('View All'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      if (transactions.isEmpty)
                        _buildNoTransactions()
                      else
                        ..._buildRecentTransactions(transactions, people),

                      const SizedBox(height: 28),

                      const Text(
                        'Due Dates',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 14),

                      ..._buildDueTransactions(transactions, people),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransaction,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'SmartInterestX',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<DashboardStats> _calculateDashboardStats(
    List<LoanTransaction> transactions,
  ) async {
    double totalGiven = 0;
    double totalTaken = 0;
    double interestEarned = 0;
    double interestPaid = 0;
    double receivable = 0;
    double payable = 0;

    final paymentProvider = context.read<PaymentProvider>();

    for (final transaction in transactions) {
      final interest =
          TransactionStatus.calculateTotalDue(transaction) - transaction.amount;

      final totalDue = transaction.amount + interest;

      final paid = transaction.id == null
          ? 0.0
          : await paymentProvider.getTotalPaid(transaction.id!);

      final remaining = (totalDue - paid).clamp(0, totalDue).toDouble();

      final isGiven = transaction.type.toLowerCase() == 'given';

      if (isGiven) {
        totalGiven += transaction.amount;
        interestEarned += interest;
        receivable += remaining;
      } else {
        totalTaken += transaction.amount;
        interestPaid += interest;
        payable += remaining;
      }
    }

    return DashboardStats(
      totalGiven: totalGiven,
      totalTaken: totalTaken,
      interestEarned: interestEarned,
      interestPaid: interestPaid,
      receivable: receivable,
      payable: payable,
    );
  }

  Widget _buildBalanceCard(BuildContext context, DashboardStats stats) {
    final net = stats.receivable - stats.payable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Net Outstanding',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),

          const SizedBox(height: 8),

          Text(
            _money(net.abs()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            net >= 0
                ? 'You are owed more than you owe'
                : 'You owe more than you are owed',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Receivable',
                  amount: _money(stats.receivable),
                ),
              ),

              Container(width: 1, height: 40, color: Colors.white24),

              Expanded(
                child: _buildBalanceItem(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Payable',
                  amount: _money(stats.payable),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem({
    required IconData icon,
    required String label,
    required String amount,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: 20),

        const SizedBox(width: 8),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),

          const SizedBox(height: 14),

          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            amount,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),

          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentTransactions(
    List<LoanTransaction> transactions,
    List<Person> people,
  ) {
    final recent = [...transactions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return recent.take(3).map((transaction) {
      final person = _findPerson(people, transaction.personId);

      final isGiven = transaction.type.toLowerCase() == 'given';

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildTransactionCard(
          transaction: transaction,
          person: person,
          isGiven: isGiven,
        ),
      );
    }).toList();
  }

  Widget _buildTransactionCard({
    required LoanTransaction transaction,
    required Person? person,
    required bool isGiven,
  }) {
    final color = isGiven ? Colors.blue : Colors.orange;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: transaction.id == null
          ? null
          : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TransactionDetailsScreen(transaction: transaction),
                ),
              );

              if (mounted) {
                await _loadDashboard();
              }
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
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
                    person?.name ?? 'Unknown Person',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    isGiven ? 'Money Given' : 'Money Taken',
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                ],
              ),
            ),

            Text(
              _money(transaction.amount),
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DUE TRANSACTIONS
  // ============================================================

  List<Widget> _buildDueTransactions(
    List<LoanTransaction> transactions,
    List<Person> people,
  ) {
    final now = DateTime.now();

    final dueTransactions = transactions.where((transaction) {
      if (transaction.dueDate == null) {
        return false;
      }

      return true;
    }).toList();

    dueTransactions.sort((a, b) {
      return a.dueDate!.compareTo(b.dueDate!);
    });

    if (dueTransactions.isEmpty) {
      return [_buildNoDueTransactions()];
    }

    final limited = dueTransactions.take(5).toList();

    return limited.map((transaction) {
      final person = _findPerson(people, transaction.personId);

      return FutureBuilder<double>(
        future: transaction.id == null
            ? Future.value(0)
            : context.read<PaymentProvider>().getTotalPaid(transaction.id!),
        builder: (context, snapshot) {
          final paid = snapshot.data ?? 0;

          final totalDue = TransactionStatus.calculateTotalDue(transaction);

          final remaining = (totalDue - paid).clamp(0, totalDue).toDouble();

          final status = TransactionStatus.calculate(
            transaction: transaction,
            totalPaid: paid,
          );

          if (status == TransactionStatus.paid) {
            return const SizedBox.shrink();
          }

          final dueDate = transaction.dueDate!;

          final isOverdue = dueDate.isBefore(now);

          final isToday =
              dueDate.year == now.year &&
              dueDate.month == now.month &&
              dueDate.day == now.day;

          String label;

          if (isOverdue) {
            final days = now.difference(dueDate).inDays;

            label = days == 0
                ? 'Due today'
                : 'Overdue by $days day${days == 1 ? '' : 's'}';
          } else if (isToday) {
            label = 'Due today';
          } else {
            final days = dueDate.difference(now).inDays;

            label = 'Due in $days day${days == 1 ? '' : 's'}';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildDueCard(
              transaction: transaction,
              name: person?.name ?? 'Unknown Person',
              amount: _money(remaining),
              dueDate: dueDate,
              label: label,
              isOverdue: isOverdue,
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildDueCard({
    required LoanTransaction transaction,
    required String name,
    required String amount,
    required DateTime dueDate,
    required String label,
    required bool isOverdue,
  }) {
    final color = isOverdue ? Colors.red : Colors.orange;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: transaction.id == null
          ? null
          : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TransactionDetailsScreen(transaction: transaction),
                ),
              );

              if (mounted) {
                await _loadDashboard();
              }
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isOverdue
                    ? Icons.warning_amber_rounded
                    : Icons.calendar_month_rounded,
                color: color,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'Due: ${_formatDate(dueDate)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              amount,
              style: TextStyle(fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDueTransactions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 40,
                color: Colors.green.shade400,
              ),

              const SizedBox(height: 10),

              const Text(
                'No pending dues.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 4),

              Text(
                'You are all caught up for now.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoTransactions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: Colors.grey.shade500,
              ),

              const SizedBox(height: 10),

              Text(
                'No transactions yet.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.red,
            ),

            const SizedBox(height: 12),

            const Text(
              'Unable to load dashboard.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: _loadDashboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Person? _findPerson(List<Person> people, int personId) {
    for (final person in people) {
      if (person.id == personId) {
        return person;
      }
    }

    return null;
  }

  Future<void> _openTransactions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionsScreen()),
    );

    if (mounted) {
      await _loadDashboard();
    }
  }

  Future<void> _openAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );

    if (result == true && mounted) {
      await _loadDashboard();
    }
  }

  String _money(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

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

class DashboardStats {
  final double totalGiven;
  final double totalTaken;
  final double interestEarned;
  final double interestPaid;
  final double receivable;
  final double payable;

  const DashboardStats({
    required this.totalGiven,
    required this.totalTaken,
    required this.interestEarned,
    required this.interestPaid,
    required this.receivable,
    required this.payable,
  });

  factory DashboardStats.empty() {
    return const DashboardStats(
      totalGiven: 0,
      totalTaken: 0,
      interestEarned: 0,
      interestPaid: 0,
      receivable: 0,
      payable: 0,
    );
  }
}
