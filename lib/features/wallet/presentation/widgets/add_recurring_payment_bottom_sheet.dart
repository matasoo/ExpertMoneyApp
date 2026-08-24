import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/currency_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/recurring_payment.dart';
import '../../providers/recurring_payments_provider.dart';
import '../../../../core/utils/icon_utils.dart';

class AddRecurringPaymentBottomSheet extends ConsumerStatefulWidget {
  final RecurringPaymentModel? paymentToEdit;

  const AddRecurringPaymentBottomSheet({super.key, this.paymentToEdit});

  @override
  ConsumerState<AddRecurringPaymentBottomSheet> createState() => _AddRecurringPaymentBottomSheetState();
}

class _AddRecurringPaymentBottomSheetState extends ConsumerState<AddRecurringPaymentBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  String _selectedIcon = Icons.live_tv.codePoint.toString();
  PaymentInterval _selectedInterval = PaymentInterval.monthly;
  DateTime _nextPaymentDate = DateTime.now();
  DateTime _startDate = DateTime.now();

  final List<IconData> _icons = [
    Icons.live_tv,
    Icons.music_note,
    Icons.fitness_center,
    Icons.home,
    Icons.phone_iphone,
    Icons.directions_car,
    Icons.sports_esports,
    Icons.lightbulb,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.paymentToEdit != null) {
      _nameController.text = widget.paymentToEdit!.name;
      _amountController.text = widget.paymentToEdit!.amount.toString();
      _selectedIcon = widget.paymentToEdit!.icon;
      if (int.tryParse(_selectedIcon) == null) {
        _selectedIcon = _icons[0].codePoint.toString(); // Fallback for legacy
      }
      _selectedInterval = widget.paymentToEdit!.interval;
      _nextPaymentDate = widget.paymentToEdit!.nextPaymentDate;
      _startDate = widget.paymentToEdit!.startDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _savePayment() {
    final name = _nameController.text.trim();
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (name.isEmpty || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid name and amount')),
      );
      return;
    }

    if (widget.paymentToEdit != null) {
      ref.read(recurringPaymentsProvider.notifier).removePayment(widget.paymentToEdit!.id);
    }

    final newPayment = RecurringPaymentModel(
      id: widget.paymentToEdit?.id ?? Uuid().v4(),
      name: name,
      amount: amount,
      icon: _selectedIcon,
      interval: _selectedInterval,
      nextPaymentDate: _nextPaymentDate,
      startDate: _startDate,
    );

    ref.read(recurringPaymentsProvider.notifier).addPayment(newPayment);
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _nextPaymentDate,
      firstDate: DateTime.now(),
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

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(Duration(days: 365 * 10)),
      lastDate: DateTime.now(),
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
      setState(() => _startDate = date);
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
              widget.paymentToEdit != null ? 'Edit Subscription' : 'New Subscription',
              style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(height: 24),
            
            // Name
            TextField(
              controller: _nameController,
              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Name (e.g. Netflix, Rent)',
                hintStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Amount',
                prefixText: '$currency ',
                hintStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            SizedBox(height: 24),

            // Start Date
            Text('Started On (for total tracking)', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            SizedBox(height: 12),
            GestureDetector(
              onTap: _pickStartDate,
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
                      DateFormat('MMMM d, yyyy').format(_startDate),
                      style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 20),
                  ],
                ),
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

            // Interval
            Text('Interval', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            SizedBox(height: 12),
            Row(
              children: PaymentInterval.values.map((interval) {
                final isSelected = _selectedInterval == interval;
                final name = interval.name[0].toUpperCase() + interval.name.substring(1);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedInterval = interval),
                    child: Container(
                      margin: EdgeInsets.only(right: interval != PaymentInterval.yearly ? 8 : 0),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.2) : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name,
                        style: GoogleFonts.manrope(
                          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24),

            // Icon
            Text('Icon', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _icons.map((icon) {
                  final iconStr = icon.codePoint.toString();
                  final isSelected = _selectedIcon == iconStr;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = iconStr),
                    child: Container(
                      margin: EdgeInsets.only(right: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface, size: 28),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 32),

            ElevatedButton(
              onPressed: _savePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Save Subscription',
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
