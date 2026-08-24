import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/currency_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/budget.dart';
import '../../providers/budgets_provider.dart';
import '../../../../core/utils/icon_utils.dart';

class AddBudgetBottomSheet extends ConsumerStatefulWidget {
  final BudgetModel? budgetToEdit;
  const AddBudgetBottomSheet({super.key, this.budgetToEdit});

  @override
  ConsumerState<AddBudgetBottomSheet> createState() => _AddBudgetBottomSheetState();
}

class _AddBudgetBottomSheetState extends ConsumerState<AddBudgetBottomSheet> {
  final _limitController = TextEditingController();
  final _customCategoryController = TextEditingController();

  String _selectedCategory = 'Food';
  String _selectedIcon = Icons.restaurant.codePoint.toString();
  String _selectedReset = 'Monthly';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Fuel', 'icon': Icons.local_gas_station},
    {'name': 'Fun', 'icon': Icons.celebration},
    {'name': 'Transport', 'icon': Icons.directions_bus},
    {'name': 'Home', 'icon': Icons.home},
    {'name': 'Custom', 'icon': Icons.edit},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.budgetToEdit != null) {
      final b = widget.budgetToEdit!;
      _limitController.text = b.limitAmount.toStringAsFixed(0);
      _selectedReset = b.resetPeriod;
      
      final bool isStandard = _categories.any((c) => c['name'] == b.category && c['name'] != 'Custom');
      if (isStandard) {
        _selectedCategory = b.category;
        _selectedIcon = b.icon;
      } else {
        _selectedCategory = 'Custom';
        _selectedIcon = b.icon;
        _customCategoryController.text = b.category;
      }
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _saveBudget() {
    final limit = double.tryParse(_limitController.text.replaceAll(ref.watch(currencyProvider), '').replaceAll(',', '').trim()) ?? 0;
    if (limit <= 0) return;

    final String finalCategory = _selectedCategory == 'Custom' 
        ? (_customCategoryController.text.trim().isEmpty ? 'Custom' : _customCategoryController.text.trim())
        : _selectedCategory;

    final budget = BudgetModel(
      id: widget.budgetToEdit?.id ?? Uuid().v4(),
      category: finalCategory,
      icon: _selectedIcon,
      limitAmount: limit,
      currentSpent: widget.budgetToEdit?.currentSpent ?? 0,
      resetPeriod: _selectedReset,
    );

    if (widget.budgetToEdit != null) {
      ref.read(budgetsProvider.notifier).updateBudget(budget);
    } else {
      ref.read(budgetsProvider.notifier).addBudget(budget);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // Dark background from screenshot
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- DRAG HANDLE ---
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            SizedBox(height: 24),
            
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.budgetToEdit != null ? 'Edit Budget' : 'New Budget', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w800)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle),
                    child: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 18),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // --- CATEGORY ---
            Text('Category', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat['name']!;
                      _selectedIcon = (cat['icon'] as IconData).codePoint.toString();
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat['icon'] as IconData, size: 18, color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface),
                        SizedBox(width: 8),
                        Text(
                          cat['name']!,
                          style: GoogleFonts.manrope(
                            color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedCategory == 'Custom') ...[
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
                child: TextFormField(
                  controller: _customCategoryController,
                  style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Enter category name...',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
            SizedBox(height: 24),

            // --- MONTHLY LIMIT ---
            Text('Monthly limit', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('${ref.watch(currencyProvider)} ', style: GoogleFonts.manrope(color: Theme.of(context).primaryColor, fontSize: 32, fontWeight: FontWeight.w800)),
                  IntrinsicWidth(
                    child: TextFormField(
                      controller: _limitController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 40, fontWeight: FontWeight.w800),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // --- RESETS ---
            Text('Resets', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedReset = 'Monthly'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedReset == 'Monthly' ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _selectedReset == 'Monthly' ? Theme.of(context).primaryColor : Colors.transparent),
                      ),
                      alignment: Alignment.center,
                      child: Text('Monthly', style: GoogleFonts.manrope(color: _selectedReset == 'Monthly' ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedReset = 'Weekly'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedReset == 'Weekly' ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _selectedReset == 'Weekly' ? Theme.of(context).primaryColor : Colors.transparent),
                      ),
                      alignment: Alignment.center,
                      child: Text('Weekly', style: GoogleFonts.manrope(color: _selectedReset == 'Weekly' ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),

            // --- SUBMIT BUTTON ---
            ElevatedButton(
              onPressed: _saveBudget,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(widget.budgetToEdit != null ? 'Save Changes' : 'Create budget', style: GoogleFonts.manrope(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
