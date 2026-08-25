import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/currency_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/models/transaction.dart';
import '../providers/transactions_provider.dart';

class TransactionsHistoryScreen extends ConsumerWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final transactions = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 24.0, left: 16.0, right: 24.0, bottom: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'All Transactions',
                    style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Text(
                        'No transactions found.',
                        style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16),
                      ),
                    )
                  : ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final t = transactions[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: _buildDismissibleTransaction(context, ref, t),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleTransaction(BuildContext context, WidgetRef ref, TransactionModel t) {
    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onSurface, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete Transaction?', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800)),
            content: Text('Are you sure you want to delete this transaction?', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(transactionsProvider.notifier).removeTransaction(t.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction deleted')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(t.icon, color: Theme.of(context).colorScheme.onSurface, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text(t.storeName, style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    t.isExpense ? '- ${ref.watch(currencyProvider)} ${t.amount.toStringAsFixed(2)}' : '+ ${ref.watch(currencyProvider)} ${t.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.manrope(color: t.isExpense ? Color(0xFFE74C3C) : Theme.of(context).primaryColor, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${t.date.day}/${t.date.month}/${t.date.year}',
                    style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
