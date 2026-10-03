import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/person.dart';
import '../../models/transaction.dart';
import '../../providers/person_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/interest_service.dart';
import '../../services/notification_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final LoanTransaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();

  final TextEditingController _rateController = TextEditingController();

  final TextEditingController _noteController = TextEditingController();

  Person? _selectedPerson;

  String _transactionType = 'Given';
  String _interestPeriod = 'Monthly';
  String _status = 'Active';

  DateTime _startDate = DateTime.now();
  DateTime? _dueDate;

  bool _isSaving = false;

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();

    _amountController.addListener(_refreshPreview);
    _rateController.addListener(_refreshPreview);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final personProvider = context.read<PersonProvider>();

      await personProvider.loadPeople();

      if (!mounted) return;

      if (_isEditMode) {
        _loadTransactionData(personProvider.people);
      }
    });
  }

  void _loadTransactionData(List<Person> people) {
    final transaction = widget.transaction;

    if (transaction == null) return;

    Person? person;

    for (final item in people) {
      if (item.id == transaction.personId) {
        person = item;
        break;
      }
    }

    setState(() {
      _selectedPerson = person;
      _transactionType = transaction.type;
      _interestPeriod = transaction.interestPeriod;
      _status = transaction.status;
      _startDate = transaction.startDate;
      _dueDate = transaction.dueDate;

      _amountController.text = transaction.amount.toString();

      _rateController.text = transaction.interestRate.toString();

      _noteController.text = transaction.note ?? '';
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  void _refreshPreview() {
    if (!mounted) return;
    setState(() {});
  }

  double get _amount {
    return double.tryParse(_amountController.text.trim()) ?? 0;
  }

  double get _rate {
    return double.tryParse(_rateController.text.trim()) ?? 0;
  }

  double get _calculatedInterest {
    if (_amount <= 0 || _rate <= 0) {
      return 0;
    }

    return InterestService.calculateSimpleInterest(
      principal: _amount,
      annualRate: _rate,
      startDate: _startDate,
      endDate: _dueDate ?? DateTime.now(),
      interestPeriod: _interestPeriod,
    );
  }

  double get _totalAmount {
    return InterestService.calculateTotalAmount(
      principal: _amount,
      interest: _calculatedInterest,
    );
  }

  Future<void> _selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) return;

    setState(() {
      _startDate = selectedDate;

      if (_dueDate != null && _dueDate!.isBefore(_startDate)) {
        _dueDate = null;
      }
    });
  }

  Future<void> _selectDueDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) return;

    setState(() {
      _dueDate = selectedDate;
    });
  }

  Future<void> _saveTransaction() async {
    FocusScope.of(context).unfocus();

    if (_selectedPerson == null) {
      _showMessage('Please select a person.');
      return;
    }

    if (_amount <= 0) {
      _showMessage('Please enter a valid amount.');
      return;
    }

    if (_rate < 0) {
      _showMessage('Please enter a valid interest rate.');
      return;
    }

    if (_dueDate != null && _dueDate!.isBefore(_startDate)) {
      _showMessage('Due date cannot be before the start date.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final transaction = LoanTransaction(
        id: widget.transaction?.id,
        personId: _selectedPerson!.id!,
        amount: _amount,
        type: _transactionType,
        interestRate: _rate,
        interestPeriod: _interestPeriod,
        startDate: _startDate,
        dueDate: _dueDate,
        status: _status,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: widget.transaction?.createdAt ?? DateTime.now(),
      );

      final provider = context.read<TransactionProvider>();

      if (_isEditMode) {
        await provider.updateTransaction(transaction);
      } else {
        await provider.addTransaction(transaction);
      }

      // --------------------------------------------------------
      // SCHEDULE DUE DATE REMINDER
      // --------------------------------------------------------

      if (_dueDate != null) {
        final notificationId = _getNotificationId(transaction);

        await NotificationService.cancel(notificationId);

        // Schedule the reminder for 9:00 AM,
        // one day before the due date.
        final reminderDate = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          9,
          0,
        );

        await NotificationService.scheduleDueReminder(
          id: notificationId,
          title: 'Payment Due Tomorrow',
          body:
              'Your ${_transactionType.toLowerCase()} transaction '
              'with ${_selectedPerson!.name} is due tomorrow.',
          dueDate: reminderDate,
          daysBefore: 1,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Transaction updated successfully.'
                : 'Transaction saved successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _isEditMode
            ? 'Could not update transaction.'
            : 'Could not save transaction.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  int _getNotificationId(LoanTransaction transaction) {
    if (transaction.id != null) {
      return transaction.id!;
    }

    return transaction.createdAt.millisecondsSinceEpoch.remainder(2147483647);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final personProvider = context.watch<PersonProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Transaction' : 'Add Transaction',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: personProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : personProvider.people.isEmpty
          ? _buildNoPeopleState()
          : _buildForm(personProvider.people),
    );
  }

  Widget _buildForm(List<Person> people) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Person', 'Who is this transaction with?'),

          const SizedBox(height: 12),

          _buildPersonDropdown(people),

          const SizedBox(height: 28),

          _buildSectionTitle(
            'Transaction Type',
            'Choose whether money was given or taken.',
          ),

          const SizedBox(height: 12),

          _buildTransactionTypeSelector(),

          const SizedBox(height: 28),

          _buildSectionTitle('Amount', 'Enter the principal amount.'),

          const SizedBox(height: 12),

          _buildAmountField(),

          const SizedBox(height: 28),

          _buildSectionTitle(
            'Interest',
            'Set the rate and calculation period.',
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildRateField()),
              const SizedBox(width: 12),
              Expanded(child: _buildPeriodDropdown()),
            ],
          ),

          const SizedBox(height: 28),

          _buildSectionTitle(
            'Dates',
            'Set when the transaction started and is due.',
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildDateCard(
                  title: 'Start Date',
                  date: _startDate,
                  icon: Icons.play_circle_outline,
                  onTap: _selectStartDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateCard(
                  title: 'Due Date',
                  date: _dueDate,
                  icon: Icons.event_outlined,
                  onTap: _selectDueDate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          _buildSectionTitle('Status', 'Current state of this transaction.'),

          const SizedBox(height: 12),

          _buildStatusDropdown(),

          const SizedBox(height: 28),

          _buildSectionTitle('Notes', 'Add any additional information.'),

          const SizedBox(height: 12),

          _buildNotesField(),

          const SizedBox(height: 28),

          _buildCalculationPreview(),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveTransaction,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isEditMode ? Icons.save_rounded : Icons.check_rounded,
                    ),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : _isEditMode
                    ? 'Update Transaction'
                    : 'Save Transaction',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
    );
  }

  Widget _buildPersonDropdown(List<Person> people) {
    return DropdownButtonFormField<Person>(
      value: _selectedPerson,
      decoration: const InputDecoration(
        labelText: 'Select Person',
        prefixIcon: Icon(Icons.person_outline_rounded),
      ),
      items: people.map((person) {
        return DropdownMenuItem<Person>(
          value: person,
          child: Text(person.name),
        );
      }).toList(),
      onChanged: (person) {
        setState(() {
          _selectedPerson = person;
        });
      },
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _typeButton(
            title: 'Given',
            icon: Icons.arrow_upward_rounded,
            selected: _transactionType == 'Given',
            onTap: () {
              setState(() {
                _transactionType = 'Given';
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _typeButton(
            title: 'Taken',
            icon: Icons.arrow_downward_rounded,
            selected: _transactionType == 'Taken',
            onTap: () {
              setState(() {
                _transactionType = 'Taken';
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _typeButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.10)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Theme.of(context).colorScheme.primary : null,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Amount',
        hintText: 'Enter amount',
        prefixText: '₹ ',
        prefixIcon: Icon(Icons.currency_rupee_rounded),
      ),
    );
  }

  Widget _buildRateField() {
    return TextField(
      controller: _rateController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Interest Rate',
        hintText: '2',
        suffixText: '%',
        prefixIcon: Icon(Icons.percent_rounded),
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return DropdownButtonFormField<String>(
      value: _interestPeriod,
      decoration: const InputDecoration(
        labelText: 'Period',
        prefixIcon: Icon(Icons.schedule_rounded),
      ),
      items: const [
        DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
        DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _interestPeriod = value;
        });
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: const InputDecoration(
        labelText: 'Status',
        prefixIcon: Icon(Icons.flag_outlined),
      ),
      items: const [
        DropdownMenuItem(value: 'Active', child: Text('Active')),
        DropdownMenuItem(value: 'Completed', child: Text('Completed')),
        DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _status = value;
        });
      },
    );
  }

  Widget _buildDateCard({
    required String title,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              date == null ? 'Select date' : _formatDate(date),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _noteController,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Notes',
        hintText: 'Example: Personal loan for laptop',
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 60),
          child: Icon(Icons.notes_rounded),
        ),
      ),
    );
  }

  Widget _buildCalculationPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interest Preview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Principal'),
              Text(
                '₹${_amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Interest'),
              Text(
                '₹${_calculatedInterest.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                '₹${_totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoPeopleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 70,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              'Add a Person First',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'You need at least one person before creating a transaction.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
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
