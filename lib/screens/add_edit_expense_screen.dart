import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../data/models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/formatters.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  const AddEditExpenseScreen({
    super.key,
    this.expense,
    this.initialIsIncome,
  });

  final Expense? expense;
  final bool? initialIsIncome;

  bool get isEditing => expense != null;

  @override
  ConsumerState<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late bool _isIncome;
  late String _category;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.expense;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _amountController = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _isIncome = existing?.isIncome ?? widget.initialIsIncome ?? false;
    _date = existing?.date ?? DateTime.now();

    final available = categoriesFor(isIncome: _isIncome);
    final existingCategory = existing?.category;
    _category = available.any((c) => c.name == existingCategory)
        ? existingCategory!
        : available.first.name;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _setType(bool isIncome) {
    if (_isIncome == isIncome) return;
    final nextCategories = categoriesFor(isIncome: isIncome);
    setState(() {
      _isIncome = isIncome;
      if (!nextCategories.any((c) => c.name == _category)) {
        _category = nextCategories.first.name;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final expense = Expense(
      id: widget.expense?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      isIncome: _isIncome,
      category: _category,
      date: _date,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    try {
      final notifier = ref.read(expenseProvider.notifier);
      if (widget.isEditing) {
        await notifier.edit(expense);
      } else {
        await notifier.add(expense);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
      setState(() => _saving = false);
    }
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _isIncome
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFFE57373) : const Color(0xFFC62828));
    final availableCategories = categoriesFor(isIncome: _isIncome);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? (_isIncome ? 'Edit income' : 'Edit expense')
              : (_isIncome ? 'Add income' : 'Add expense'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _isIncome
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isIncome ? 'Money in' : 'Money out',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isIncome
                                ? 'Salary, gifts, freelance, and other income'
                                : 'Food, bills, shopping, and daily spending',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Type',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Expense'),
                    icon: Icon(Icons.north_east_rounded),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Income'),
                    icon: Icon(Icons.south_west_rounded),
                  ),
                ],
                selected: {_isIncome},
                onSelectionChanged: (values) => _setType(values.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  label: 'Title',
                  hint: _isIncome ? 'e.g. October salary' : 'e.g. Grocery run',
                  prefixIcon: const Icon(Icons.edit_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  label: _isIncome ? 'Income amount' : 'Expense amount',
                  hint: '0.00',
                  prefixIcon: Icon(
                    _isIncome
                        ? Icons.add_card_rounded
                        : Icons.money_off_csred_rounded,
                    color: accent,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null) {
                    return 'Enter a valid number';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: ValueKey('category-$_isIncome-$_category'),
                initialValue: _category,
                decoration: _decoration(
                  label: _isIncome ? 'Income category' : 'Expense category',
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: availableCategories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.name,
                        child: Row(
                          children: [
                            Icon(category.icon, color: category.color, size: 20),
                            const SizedBox(width: 10),
                            Text(category.name),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: _decoration(
                    label: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    suffixIcon: const Icon(Icons.chevron_right_rounded),
                  ),
                  child: Text(
                    shortDateFormat.format(_date),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  label: 'Note (optional)',
                  hint: _isIncome
                      ? 'Source, client, or payout details'
                      : 'Store, bill period, or reason',
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Material(
        color: scheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isIncome
                          ? Icons.add_rounded
                          : Icons.check_rounded,
                    ),
              label: Text(
                widget.isEditing
                    ? (_isIncome ? 'Save income' : 'Save expense')
                    : (_isIncome ? 'Add income' : 'Add expense'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
