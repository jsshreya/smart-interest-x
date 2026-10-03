import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/person.dart';
import '../../models/transaction.dart';
import '../../providers/payment_provider.dart';
import '../../providers/person_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/export_service.dart';
import '../../utils/transaction_status.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  bool _isExporting = false;

  double _totalGiven = 0;
  double _totalTaken = 0;
  double _totalInterest = 0;
  double _totalPaid = 0;
  double _totalPending = 0;

  int _activeCount = 0;
  int _partialCount = 0;
  int _paidCount = 0;
  int _overdueCount = 0;

  String _monthFilter = 'All';
  String _yearFilter = 'All';
  String _personFilter = 'All';

  List<Person> _people = [];
  List<LoanTransaction> _allTransactions = [];

  final List<String> _months = const [
    'All',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final transactionProvider = context.read<TransactionProvider>();

    final personProvider = context.read<PersonProvider>();

    await transactionProvider.loadTransactions();
    await personProvider.loadPeople();

    _allTransactions = List<LoanTransaction>.from(
      transactionProvider.transactions,
    );

    _people = List<Person>.from(personProvider.people);

    await _calculateAnalytics();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _calculateAnalytics() async {
    final paymentProvider = context.read<PaymentProvider>();

    final filteredTransactions = _getFilteredTransactions();

    double given = 0;
    double taken = 0;
    double interest = 0;
    double paid = 0;
    double pending = 0;

    int active = 0;
    int partial = 0;
    int completed = 0;
    int overdue = 0;

    for (final transaction in filteredTransactions) {
      final totalDue = TransactionStatus.calculateTotalDue(transaction);

      final totalPaid = await paymentProvider.getTotalPaid(transaction.id!);

      final transactionInterest = totalDue - transaction.amount;

      if (transaction.type.toLowerCase() == 'given') {
        given += transaction.amount;
      } else {
        taken += transaction.amount;
      }

      interest += transactionInterest;
      paid += totalPaid;

      final remaining = totalDue - totalPaid;

      if (remaining > 0) {
        pending += remaining;
      }

      final status = TransactionStatus.calculate(
        transaction: transaction,
        totalPaid: totalPaid,
      );

      switch (status) {
        case TransactionStatus.active:
          active++;
          break;

        case TransactionStatus.partiallyPaid:
          partial++;
          break;

        case TransactionStatus.paid:
          completed++;
          break;

        case TransactionStatus.overdue:
          overdue++;
          break;
      }
    }

    if (!mounted) return;

    setState(() {
      _totalGiven = given;
      _totalTaken = taken;
      _totalInterest = interest;
      _totalPaid = paid;
      _totalPending = pending;

      _activeCount = active;
      _partialCount = partial;
      _paidCount = completed;
      _overdueCount = overdue;
    });
  }

  List<LoanTransaction> _getFilteredTransactions() {
    return _allTransactions.where((transaction) {
      final monthMatches =
          _monthFilter == 'All' ||
          transaction.startDate.month == _months.indexOf(_monthFilter);

      final yearMatches =
          _yearFilter == 'All' ||
          transaction.startDate.year.toString() == _yearFilter;

      final personMatches =
          _personFilter == 'All' ||
          transaction.personId.toString() == _personFilter;

      return monthMatches && yearMatches && personMatches;
    }).toList();
  }

  List<String> _availableYears() {
    final years = _allTransactions
        .map((transaction) => transaction.startDate.year.toString())
        .toSet()
        .toList();

    years.sort((a, b) => b.compareTo(a));

    return ['All', ...years];
  }

  Future<void> _changeFilter({
    String? month,
    String? year,
    String? person,
  }) async {
    setState(() {
      if (month != null) {
        _monthFilter = month;
      }

      if (year != null) {
        _yearFilter = year;
      }

      if (person != null) {
        _personFilter = person;
      }

      _isLoading = true;
    });

    await _calculateAnalytics();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _exportData() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final transactionProvider = context.read<TransactionProvider>();

      final paymentProvider = context.read<PaymentProvider>();

      await transactionProvider.loadTransactions();
      await paymentProvider.loadPayments();

      final filePath = await ExportService.exportTransactions(
        transactions: transactionProvider.transactions,
        payments: paymentProvider.payments,
      );

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'SmartInterestX Transaction Data',
        text: 'SmartInterestX exported transaction data.',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  String _money(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _isExporting ? null : _exportData,
            tooltip: 'Export Data',
            icon: _isExporting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                children: [
                  _buildFilters(),

                  const SizedBox(height: 20),

                  _buildMainSummary(),

                  const SizedBox(height: 20),

                  const Text(
                    'Money Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Given',
                          value: _money(_totalGiven),
                          icon: Icons.arrow_upward_rounded,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Taken',
                          value: _money(_totalTaken),
                          icon: Icons.arrow_downward_rounded,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Interest',
                          value: _money(_totalInterest),
                          icon: Icons.percent_rounded,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Paid',
                          value: _money(_totalPaid),
                          icon: Icons.check_circle_outline_rounded,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _buildPendingCard(),

                  const SizedBox(height: 24),

                  const Text(
                    'Given vs Taken',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 12),

                  _buildGivenTakenChart(),

                  const SizedBox(height: 24),

                  const Text(
                    'Monthly Interest Flow',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 12),

                  _buildMonthlyInterestChart(),

                  const SizedBox(height: 24),

                  const Text(
                    'Transaction Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 12),

                  _buildStatusChart(),

                  const SizedBox(height: 16),

                  _buildStatusCard(
                    'Active',
                    _activeCount,
                    Icons.timelapse_rounded,
                    Colors.blue,
                  ),

                  _buildStatusCard(
                    'Partially Paid',
                    _partialCount,
                    Icons.pie_chart_outline_rounded,
                    Colors.orange,
                  ),

                  _buildStatusCard(
                    'Completed',
                    _paidCount,
                    Icons.check_circle_outline_rounded,
                    Colors.green,
                  ),

                  _buildStatusCard(
                    'Overdue',
                    _overdueCount,
                    Icons.warning_amber_rounded,
                    Colors.red,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _monthFilter,
              decoration: const InputDecoration(
                labelText: 'Month',
                prefixIcon: Icon(Icons.calendar_month),
              ),
              items: _months.map((month) {
                return DropdownMenuItem(value: month, child: Text(month));
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                _changeFilter(month: value);
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _yearFilter,
              decoration: const InputDecoration(
                labelText: 'Year',
                prefixIcon: Icon(Icons.date_range),
              ),
              items: _availableYears().map((year) {
                return DropdownMenuItem(value: year, child: Text(year));
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                _changeFilter(year: value);
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _personFilter,
              decoration: const InputDecoration(
                labelText: 'Contact',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'All',
                  child: Text('All Contacts'),
                ),
                ..._people.map((person) {
                  return DropdownMenuItem(
                    value: person.id.toString(),
                    child: Text(person.name),
                  );
                }),
              ],
              onChanged: (value) {
                if (value == null) return;

                _changeFilter(person: value);
              },
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _changeFilter(month: 'All', year: 'All', person: 'All');
                },
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSummary() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Pending',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _money(_totalPending),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text('Amount still outstanding across filtered transactions'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.10),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard() {
    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.10),
          child: const Icon(Icons.pending_actions_rounded, color: Colors.red),
        ),
        title: const Text(
          'Pending Amount',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Total amount yet to be settled'),
        trailing: Text(
          _money(_totalPending),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildGivenTakenChart() {
    if (_totalGiven == 0 && _totalTaken == 0) {
      return _emptyChartCard('No Given/Taken data available.');
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              maxY:
                  [_totalGiven, _totalTaken].reduce((a, b) => a > b ? a : b) *
                  1.25,
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: _totalGiven,
                      width: 45,
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: _totalTaken,
                      width: 45,
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 45),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final title = value.toInt() == 0 ? 'Given' : 'Taken';

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyInterestChart() {
    final year = _yearFilter == 'All'
        ? DateTime.now().year
        : int.parse(_yearFilter);

    final monthlyInterest = List<double>.filled(12, 0);

    final transactions = _getFilteredTransactions()
        .where((transaction) => transaction.startDate.year == year)
        .toList();

    for (final transaction in transactions) {
      final totalDue = TransactionStatus.calculateTotalDue(transaction);

      final interest = totalDue - transaction.amount;

      final month = transaction.startDate.month;

      monthlyInterest[month - 1] += interest;
    }

    final maxInterest = monthlyInterest.reduce((a, b) => a > b ? a : b);

    if (maxInterest <= 0) {
      return _emptyChartCard('No interest data available for $year.');
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 20, 20),
        child: SizedBox(
          height: 280,
          child: BarChart(
            BarChartData(
              maxY: maxInterest * 1.25,
              barGroups: List.generate(12, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: monthlyInterest[index],
                      width: 16,
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 45),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const months = [
                        'J',
                        'F',
                        'M',
                        'A',
                        'M',
                        'J',
                        'J',
                        'A',
                        'S',
                        'O',
                        'N',
                        'D',
                      ];

                      final index = value.toInt();

                      if (index < 0 || index >= months.length) {
                        return const SizedBox();
                      }

                      return Text(
                        months[index],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChart() {
    final total = _activeCount + _partialCount + _paidCount + _overdueCount;

    if (total == 0) {
      return _emptyChartCard('No transaction status data available.');
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 45,
                  sections: [
                    PieChartSectionData(
                      value: _activeCount.toDouble(),
                      title: '$_activeCount',
                      radius: 65,
                      color: Colors.blue,
                    ),
                    PieChartSectionData(
                      value: _partialCount.toDouble(),
                      title: '$_partialCount',
                      radius: 65,
                      color: Colors.orange,
                    ),
                    PieChartSectionData(
                      value: _paidCount.toDouble(),
                      title: '$_paidCount',
                      radius: 65,
                      color: Colors.green,
                    ),
                    PieChartSectionData(
                      value: _overdueCount.toDouble(),
                      title: '$_overdueCount',
                      radius: 65,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 14,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _ChartLegend(color: Colors.blue, label: 'Active'),
                _ChartLegend(color: Colors.orange, label: 'Partial'),
                _ChartLegend(color: Colors.green, label: 'Completed'),
                _ChartLegend(color: Colors.red, label: 'Overdue'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyChartCard(String message) {
    return Card(
      elevation: 0,
      child: SizedBox(
        height: 150,
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.65),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.10),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
