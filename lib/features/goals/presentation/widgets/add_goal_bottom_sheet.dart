import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/currency_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/goal.dart';
import '../../providers/goals_provider.dart';

class AddGoalBottomSheet extends ConsumerStatefulWidget {
  final GoalModel? goalToEdit;
  const AddGoalBottomSheet({super.key, this.goalToEdit});

  @override
  ConsumerState<AddGoalBottomSheet> createState() => _AddGoalBottomSheetState();
}

class _AddGoalBottomSheetState extends ConsumerState<AddGoalBottomSheet> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _dateController = TextEditingController(); // "Jul 2027"
  final _monthlyController = TextEditingController(); // inside the green card
  final _dayController = TextEditingController();
  final _currentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Color? _selectedColor;
  bool _isAutoDeduct = false;

  List<Color> get _colorOptions => [
    Theme.of(context).primaryColor,
    Color(0xFF3b82f6), // Blue
    Color(0xFFf59e0b), // Orange
    Color(0xFFa855f7), // Purple
    Color(0xFFec4899), // Pink
  ];

  @override
  void initState() {
    super.initState();
    if (widget.goalToEdit != null) {
      final goal = widget.goalToEdit!;
      _titleController.text = goal.title;
      _targetController.text = goal.targetAmount.toStringAsFixed(0);
      _dateController.text = goal.targetDate ?? '';
      _monthlyController.text = goal.monthlyContribution.toStringAsFixed(0);
      _currentController.text = goal.currentAmount.toStringAsFixed(0);
      _selectedColor = Color(goal.colorValue ?? Theme.of(context).primaryColor.toARGB32());
      _isAutoDeduct = goal.isAutoDeduct;
      if (goal.autoDeductDay != null) {
        _dayController.text = goal.autoDeductDay.toString();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedColor ??= Theme.of(context).primaryColor;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _dateController.dispose();
    _monthlyController.dispose();
    _dayController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  void _saveGoal() {
    if (!_formKey.currentState!.validate()) return;

    final target = double.tryParse(_targetController.text.replaceAll(ref.watch(currencyProvider), '').replaceAll(',', '')) ?? 0;
    final monthly = double.tryParse(_monthlyController.text.replaceAll(ref.watch(currencyProvider), '').replaceAll(',', '')) ?? 0;
    final current = double.tryParse(_currentController.text.replaceAll(ref.watch(currencyProvider), '').replaceAll(',', '')) ?? (widget.goalToEdit?.currentAmount ?? 0);
    final day = int.tryParse(_dayController.text);

    if (_isAutoDeduct && day == null) {
      // Basic validation if day is not entered properly
      return;
    }

    final goal = GoalModel(
      id: widget.goalToEdit?.id ?? Uuid().v4(),
      title: _titleController.text.trim(),
      targetAmount: target,
      currentAmount: current,
      monthlyContribution: monthly,
      targetDate: _dateController.text.trim(),
      colorValue: _selectedColor!.toARGB32(),
      isAutoDeduct: _isAutoDeduct,
      autoDeductDay: _isAutoDeduct ? day : null,
    );

    if (widget.goalToEdit != null) {
      ref.read(goalsProvider.notifier).updateGoal(goal);
    } else {
      ref.read(goalsProvider.notifier).addGoal(goal);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
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
                  Text(widget.goalToEdit != null ? 'Edit Goal' : 'New Goal', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w800)),
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
              
              // --- GOAL NAME ---
              Text('Goal name', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              _buildTextField('Vacation 2027', _titleController, TextInputType.text),
              SizedBox(height: 20),
              
              // --- INITIAL SAVED AMOUNT ---
              Text(widget.goalToEdit != null ? 'Current saved amount' : 'Initial saved amount', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              _buildTextField('e.g. 1000', _currentController, TextInputType.numberWithOptions(decimal: true), prefix: currency),
              SizedBox(height: 20),
              
              // --- TARGET AND DATE ---
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        _buildTextField('${ref.watch(currencyProvider)} 3,000', _targetController, TextInputType.numberWithOptions(decimal: true)),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('By date', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        _buildTextField('Jul 2027', _dateController, TextInputType.text, isRequired: false),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // --- CONTRIBUTION OPTIONS ---
              Text('Monthly Contribution', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              _buildTextField('${ref.watch(currencyProvider)} 0', _monthlyController, TextInputType.numberWithOptions(decimal: true)),
              SizedBox(height: 20),

              Text('Contribution Type', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isAutoDeduct = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !_isAutoDeduct ? _selectedColor!.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: !_isAutoDeduct ? _selectedColor! : Colors.transparent),
                        ),
                        alignment: Alignment.center,
                        child: Text('Manual Add', style: GoogleFonts.manrope(color: !_isAutoDeduct ? _selectedColor! : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isAutoDeduct = true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isAutoDeduct ? _selectedColor!.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _isAutoDeduct ? _selectedColor! : Colors.transparent),
                        ),
                        alignment: Alignment.center,
                        child: Text('Auto Deduct', style: GoogleFonts.manrope(color: _isAutoDeduct ? _selectedColor! : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isAutoDeduct) ...[
                SizedBox(height: 16),
                Text('Day of the month', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                _buildTextField('e.g., 15', _dayController, TextInputType.number, isRequired: true),
              ],
              SizedBox(height: 24),

              // --- COLOR PICKER ---
              Text('Color', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              Row(
                children: _colorOptions.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      margin: EdgeInsets.only(right: 12),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 40),

              // --- SUBMIT BUTTON ---
              ElevatedButton(
                onPressed: _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor ?? Theme.of(context).primaryColor,
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(widget.goalToEdit != null ? 'Save Changes' : 'Create goal', style: GoogleFonts.manrope(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, TextInputType type, {bool isRequired = true, String? prefix}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix != null ? '$prefix ' : null,
        hintStyle: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface, // Match screenshot textfield bg
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'Required';
        }
        return null;
      },
    );
  }
}
