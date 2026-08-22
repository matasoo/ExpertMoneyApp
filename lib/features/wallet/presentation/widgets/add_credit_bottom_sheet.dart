import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/currency_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/credit_model.dart';
import '../../providers/credits_provider.dart';

class AddCreditBottomSheet extends ConsumerStatefulWidget {
  final CreditModel? creditToEdit;

  const AddCreditBottomSheet({super.key, this.creditToEdit});

  @override
  ConsumerState<AddCreditBottomSheet> createState() => _AddCreditBottomSheetState();
}

class _AddCreditBottomSheetState extends ConsumerState<AddCreditBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _monthlyContributionController = TextEditingController();
  
  String _selectedIcon = '🏦';
  DateTime _nextPaymentDate = DateTime.now();

  final List<String> _icons = ['🏦', '🚗', '🏠', '💳', '🎓', '📱', '✈️', '💼'];

  @override
  void initState() {
    super.initState();
    if (widget.creditToEdit != null) {
      _nameController.text = widget.creditToEdit!.name;
      _totalAmountController.text = widget.creditToEdit!.totalAmount.toString();
      _paidAmountController.text = widget.creditToEdit!.paidAmount.toString();
      _monthlyContributionController.text = widget.creditToEdit!.monthlyContribution.toString();
      _selectedIcon = widget.creditToEdit!.icon;
      _nextPaymentDate = widget.creditToEdit!.nextPaymentDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalAmountController.dispose();
    _paidAmountController.dispose();
    _monthlyContributionController.dispose();
    super.dispose();
  }

  void _saveCredit() {
    final name = _nameController.text.trim();
    final totalAmount = double.tryParse(_totalAmountController.text.replaceAll(',', '.'));
    final paidAmount = double.tryParse(_paidAmountController.text.replaceAll(',', '.')) ?? 0.0;
    final monthlyContribution = double.tryParse(_monthlyContributionController.text.replaceAll(',', '.'));

    if (name.isEmpty || totalAmount == null || monthlyContribution == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid name, total amount, and monthly rate')),
      );
      return;
    }

    if (widget.creditToEdit != null) {
      ref.read(creditsProvider.notifier).removeCredit(widget.creditToEdit!.id);
    }

    final newCredit = CreditModel(
      id: widget.creditToEdit?.id ?? Uuid().v4(),
      name: name,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      monthlyContribution: monthlyContribution,
      icon: _selectedIcon,
      nextPaymentDate: _nextPaymentDate,
    );

    ref.read(creditsProvider.notifier).addCredit(newCredit);
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _nextPaymentDate,
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Theme.of(context).colorScheme.onSurface,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _nextPaymentDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              widget.creditToEdit != null ? 'Edit Credit/Loan' : 'New Credit/Loan',
              style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(height: 24),
            
            // Name
            TextField(
              controller: _nameController,
              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Credit Name (e.g. Car Loan)',
                hintStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _totalAmountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Total Amount',
                      prefixText: '$currency ',
                      hintStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _paidAmountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Paid So Far',
                      prefixText: '$currency ',
                      hintStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Monthly Contribution
            TextField(
              controller: _monthlyContributionController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Monthly Rate (Contribution)',
                prefixText: '$currency ',
                hintStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            SizedBox(height: 24),

            // Next Payment Date
            Text('Next Payment', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM d, yyyy').format(_nextPaymentDate),
                      style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 20),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Icon
            Text('Icon', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _icons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      margin: EdgeInsets.only(right: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5) : Colors.transparent),
                      ),
                      child: Text(icon, style: TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saveCredit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Save Credit',
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
