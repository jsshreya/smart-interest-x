import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/payment.dart';
import '../../providers/payment_provider.dart';

class AddPaymentScreen extends StatefulWidget {
  final int transactionId;

  const AddPaymentScreen({super.key, required this.transactionId});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final TextEditingController _amountController = TextEditingController();

  final TextEditingController _noteController = TextEditingController();

  DateTime _paymentDate = DateTime.now();

  String _paymentMode = 'UPI';

  String? _proofPath;

  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount {
    return double.tryParse(_amountController.text.trim()) ?? 0;
  }

  Future<void> _selectPaymentDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) return;

    setState(() {
      _paymentDate = selectedDate;
    });
  }

  // ------------------------------------------------------------
  // PAYMENT PROOF
  // ------------------------------------------------------------

  Future<void> _addProof() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Add Payment Proof',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),

              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context, ImageSource.camera);
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picker = ImagePicker();

    final image = await picker.pickImage(source: source, imageQuality: 80);

    if (image == null) return;

    setState(() {
      _proofPath = image.path;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment proof attached.')));
  }

  Future<void> _savePayment() async {
    FocusScope.of(context).unfocus();

    if (_amount <= 0) {
      _showMessage('Please enter a valid payment amount.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final payment = Payment(
        transactionId: widget.transactionId,
        amount: _amount,
        paymentDate: _paymentDate,
        mode: _paymentMode,
        proofPath: _proofPath,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: DateTime.now(),
      );

      await context.read<PaymentProvider>().addPayment(payment);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment saved successfully.')),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      _showMessage('Could not save payment.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Payment',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            const SizedBox(height: 28),

            _buildSectionTitle(
              'Payment Amount',
              'Enter the amount received or paid.',
            ),

            const SizedBox(height: 12),

            _buildAmountField(),

            const SizedBox(height: 28),

            _buildSectionTitle('Payment Date', 'When was this payment made?'),

            const SizedBox(height: 12),

            _buildDateCard(),

            const SizedBox(height: 28),

            _buildSectionTitle('Payment Mode', 'How was the payment made?'),

            const SizedBox(height: 12),

            _buildPaymentModeSelector(),

            const SizedBox(height: 28),

            _buildSectionTitle('Payment Proof', 'Attach proof when available.'),

            const SizedBox(height: 12),

            _buildProofCard(),

            const SizedBox(height: 28),

            _buildSectionTitle(
              'Notes',
              'Add any information about this payment.',
            ),

            const SizedBox(height: 12),

            _buildNotesField(),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _savePayment,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Payment',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.payments_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Payment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Keep track of every payment made.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
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
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Payment Amount',
        hintText: 'Enter amount',
        prefixText: '₹ ',
        prefixIcon: Icon(Icons.currency_rupee_rounded),
      ),
    );
  }

  Widget _buildDateCard() {
    return InkWell(
      onTap: _selectPaymentDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Date',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatDate(_paymentDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentModeSelector() {
    const modes = [
      (title: 'UPI', icon: Icons.qr_code_rounded),
      (title: 'Cash', icon: Icons.payments_outlined),
      (title: 'Bank', icon: Icons.account_balance_outlined),
      (title: 'Card', icon: Icons.credit_card_outlined),
      (title: 'Other', icon: Icons.more_horiz_rounded),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: modes.map((mode) {
        final selected = _paymentMode == mode.title;

        return InkWell(
          onTap: () {
            setState(() {
              _paymentMode = mode.title;
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: selected
                  ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.10)
                  : Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  mode.icon,
                  size: 18,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 7),
                Text(
                  mode.title,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProofCard() {
    final hasProof = _proofPath != null && _proofPath!.isNotEmpty;

    return InkWell(
      onTap: _addProof,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: Icon(
                hasProof
                    ? Icons.check_circle_outline
                    : Icons.attach_file_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasProof ? 'Proof Added' : 'Add Payment Proof',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasProof ? _proofPath! : 'Receipt, screenshot or photo',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded),
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
        hintText: 'Example: First installment',
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 60),
          child: Icon(Icons.notes_rounded),
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
