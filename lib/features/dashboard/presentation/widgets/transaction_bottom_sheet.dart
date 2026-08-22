import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/currency_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/transaction.dart';
import '../../providers/transactions_provider.dart';
import '../../../goals/providers/budgets_provider.dart';
import '../../../wallet/providers/accounts_provider.dart';

class TransactionBottomSheet extends ConsumerStatefulWidget {
  const TransactionBottomSheet({super.key});

  @override
  ConsumerState<TransactionBottomSheet> createState() => _TransactionBottomSheetState();
}

class _TransactionBottomSheetState extends ConsumerState<TransactionBottomSheet> {
  bool _isExpense = true;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  TransactionCategory _selectedCategory = TransactionCategory.other;
  String? _selectedBudgetId;
  String? _selectedAccountId;

  final List<TransactionCategory> _expenseCategories = [
    TransactionCategory.food,
    TransactionCategory.transport,
    TransactionCategory.utilities,
    TransactionCategory.shopping,
    TransactionCategory.entertainment,
    TransactionCategory.other,
  ];

  final List<TransactionCategory> _incomeCategories = [
    TransactionCategory.salary,
    TransactionCategory.other,
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    final title = _titleController.text.trim();

    if (amount == null || amount <= 0 || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount and title')),
      );
      return;
    }

    final transaction = TransactionModel(
      id: const Uuid().v4(),
      title: title,
      storeName: _selectedCategory == TransactionCategory.other && _customCategoryController.text.isNotEmpty 
          ? _customCategoryController.text.trim().toUpperCase() 
          : _selectedCategory.name.toUpperCase(),
      amount: amount,
      date: DateTime.now(),
      category: _selectedCategory,
      customCategoryName: _selectedCategory == TransactionCategory.other && _customCategoryController.text.isNotEmpty 
          ? _customCategoryController.text.trim() 
          : null,
      isExpense: _isExpense,
      accountId: _selectedAccountId,
    );

    ref.read(transactionsProvider.notifier).addTransaction(transaction);

    if (_selectedAccountId != null) {
      ref.read(accountsProvider.notifier).updateAccountBalance(_selectedAccountId!, amount, isExpense: _isExpense);
    }

    if (_isExpense && _selectedBudgetId != null) {
      ref.read(budgetsProvider.notifier).updateBudgetCurrentSpent(_selectedBudgetId!, amount);
    }

    Navigator.of(context).pop();
  }

  IconData _getCategoryIcon(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food: return Icons.restaurant;
      case TransactionCategory.transport: return Icons.directions_car;
      case TransactionCategory.utilities: return Icons.bolt;
      case TransactionCategory.entertainment: return Icons.movie;
      case TransactionCategory.shopping: return Icons.shopping_bag;
      case TransactionCategory.salary: return Icons.account_balance;
      case TransactionCategory.other: return Icons.more_horiz;
    }
  }

  String _getCategoryName(TransactionCategory cat) {
    final name = cat.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final categories = _isExpense ? _expenseCategories : _incomeCategories;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }
    
    final budgets = ref.watch(budgetsProvider);
    final accounts = ref.watch(accountsProvider);

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
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isExpense = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isExpense ? Theme.of(context).colorScheme.error.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _isExpense ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Expense',
                        style: GoogleFonts.manrope(
                          color: _isExpense ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isExpense = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isExpense ? Theme.of(context).primaryColor.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: !_isExpense ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Income',
                        style: GoogleFonts.manrope(
                          color: !_isExpense ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                prefixText: '$currency ',
                prefixStyle: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                hintText: '0.00',
                hintStyle: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'What was this for?',
                hintStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            Text('Category', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? (_isExpense ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor) : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(cat),
                            color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getCategoryName(cat),
                            style: GoogleFonts.manrope(
                              color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_selectedCategory == TransactionCategory.other) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customCategoryController,
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Custom category name...',
                  hintStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
            if (accounts.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Link to Account (Optional)', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // "None" option
                    GestureDetector(
                      onTap: () => setState(() => _selectedAccountId = null),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedAccountId == null ? (_isExpense ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor) : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'None',
                          style: GoogleFonts.manrope(
                            color: _selectedAccountId == null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Accounts
                    ...accounts.map((a) {
                      final isSelected = _selectedAccountId == a.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAccountId = a.id),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? (_isExpense ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor) : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Text(a.icon ?? '🏦', style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                a.name,
                                style: GoogleFonts.manrope(
                                  color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            if (_isExpense && budgets.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Link to Budget (Optional)', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // "None" option
                    GestureDetector(
                      onTap: () => setState(() => _selectedBudgetId = null),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedBudgetId == null ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'None',
                          style: GoogleFonts.manrope(
                            color: _selectedBudgetId == null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Budgets
                    ...budgets.map((b) {
                      final isSelected = _selectedBudgetId == b.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedBudgetId = b.id),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Text(b.icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                b.category,
                                style: GoogleFonts.manrope(
                                  color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isExpense ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Add ${_isExpense ? 'Expense' : 'Income'}',
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
