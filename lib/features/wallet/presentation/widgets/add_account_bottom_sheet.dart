import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/currency_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../providers/accounts_provider.dart';
import '../../domain/models/account.dart';
import '../../../../core/utils/icon_utils.dart';

class AddAccountBottomSheet extends ConsumerStatefulWidget {
  final AccountModel? accountToEdit;

  const AddAccountBottomSheet({super.key, this.accountToEdit});

  @override
  ConsumerState<AddAccountBottomSheet> createState() => _AddAccountBottomSheetState();
}

class _AddAccountBottomSheetState extends ConsumerState<AddAccountBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  
  Color _selectedColor = const Color(0xFF3b82f6);
  String _selectedIcon = Icons.account_balance.codePoint.toString();

  final List<Color> _colors = [
    const Color(0xFF3b82f6), // Blue
    const Color(0xFF8b5cf6), // Purple
    const Color(0xFF10b981), // Emerald
    const Color(0xFFf59e0b), // Amber
    const Color(0xFFef4444), // Red
    const Color(0xFF14B8A6), // Teal
  ];

  final List<IconData> _icons = [
    Icons.account_balance,
    Icons.credit_card,
    Icons.attach_money,
    Icons.savings,
    Icons.phone_iphone,
    Icons.account_balance_wallet,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.accountToEdit != null) {
      _nameController.text = widget.accountToEdit!.name;
      _balanceController.text = widget.accountToEdit!.balance.toString();
      _selectedColor = widget.accountToEdit!.colorValue != null 
          ? Color(widget.accountToEdit!.colorValue!) 
          : _colors[0];
      _selectedIcon = widget.accountToEdit!.icon ?? _icons[0].codePoint.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _saveAccount() {
    final name = _nameController.text.trim();
    final balanceText = _balanceController.text.replaceAll(',', '.');
    final balance = double.tryParse(balanceText);

    if (name.isEmpty || balance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid name and balance')),
      );
      return;
    }

    if (widget.accountToEdit != null) {
      ref.read(accountsProvider.notifier).removeAccount(widget.accountToEdit!.id);
    }

    final newAccount = AccountModel(
      id: widget.accountToEdit?.id ?? const Uuid().v4(),
      name: name,
      balance: balance,
      colorValue: _selectedColor.toARGB32(),
      icon: _selectedIcon,
    );

    ref.read(accountsProvider.notifier).addAccount(newAccount);
    Navigator.pop(context);
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
            const SizedBox(height: 24),
            Text(
              widget.accountToEdit != null ? 'Edit Account' : 'New Account',
              style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 24),
            
            // Name
            TextField(
              controller: _nameController,
              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Account Name (e.g. Main Bank)',
                hintStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Balance
            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Starting Balance',
                prefixText: '$currency ',
                hintStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Text('Icon', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _icons.map((icon) {
                  final iconStr = icon.codePoint.toString();
                  final isSelected = _selectedIcon == iconStr;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = iconStr;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
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
            const SizedBox(height: 24),

            // Color
            Text('Card Color', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _colors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saveAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Save Account',
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
