import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/card_model.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;
  final TransactionType? initialType;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.initialType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late TransactionType _type;
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  BankCard? _selectedCard;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _notesController.text = widget.transaction!.notes ?? '';
      _type = widget.transaction!.type;
      _selectedDate = widget.transaction!.date;
    } else {
      _type = widget.initialType ?? TransactionType.expense;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnackBar('Please select a category');
      return;
    }

    final appState = context.read<AppState>();
    // If no card is selected, try to use active card or first account
    final accountId = _selectedCard?.accountId ?? 
                     appState.activeCard?.accountId ?? 
                     (appState.accounts.isNotEmpty ? appState.accounts.first.id : null);

    if (accountId == null) {
      _showSnackBar('No account available for transaction');
      return;
    }

    final transaction = Transaction(
      id: widget.transaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      amount: double.parse(_amountController.text),
      category: _selectedCategory!.id,
      date: _selectedDate,
      type: _type,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      accountId: accountId,
    );

    if (widget.transaction != null) {
      await appState.updateTransaction(widget.transaction!, transaction);
    } else {
      await appState.addTransaction(transaction);
    }

    if (appState.error != null && mounted) {
      _showSnackBar(appState.error!, isError: true);
      appState.clearError();
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final categories = appState.categories.where((c) => c.type == _type).toList();
    final cards = appState.cards;

    if (widget.transaction != null && _selectedCategory == null) {
      _selectedCategory = appState.getCategoryById(widget.transaction!.category);
    }
    
    // Default selected card to active card if not set
    _selectedCard ??= appState.activeCard;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction != null ? 'Edit Transaction' : 'Add Transaction'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _submit)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Amount at Top for prominence
            TextFormField(
              controller: _amountController,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _type == TransactionType.income ? const Color(0xFF00E676) : Colors.red,
              ),
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              validator: (val) => (val == null || double.tryParse(val) == null || double.parse(val) <= 0) ? 'Invalid amount' : null,
            ),
            const SizedBox(height: 16),

            // Card / Account Selector
            if (cards.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.credit_card),
                  title: const Text('Payment Method'),
                  subtitle: Text(_selectedCard != null 
                    ? '${_selectedCard!.network.name.toUpperCase()} (**** ${_selectedCard!.cardNumber})'
                    : 'Select Card'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          return ListTile(
                            leading: Icon(Icons.credit_card, color: card.cardColor),
                            title: Text(card.network.name.toUpperCase()),
                            subtitle: Text('**** ${card.cardNumber}'),
                            selected: _selectedCard?.id == card.id,
                            onTap: () {
                              setState(() => _selectedCard = card);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            // Type Selector
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Expense')),
                    selected: _type == TransactionType.expense,
                    onSelected: (val) => setState(() {
                      if (val) _type = TransactionType.expense;
                      _selectedCategory = null;
                    }),
                    selectedColor: Colors.red.withOpacity(0.2),
                    labelStyle: TextStyle(color: _type == TransactionType.expense ? Colors.red : Colors.black),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Income')),
                    selected: _type == TransactionType.income,
                    onSelected: (val) => setState(() {
                      if (val) _type = TransactionType.income;
                      _selectedCategory = null;
                    }),
                    selectedColor: const Color(0xFF00E676).withOpacity(0.2),
                    labelStyle: TextStyle(color: _type == TransactionType.income ? const Color(0xFF00E676) : Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'What was this for?',
                border: OutlineInputBorder(),
              ),
              validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Category Selection
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: categories.map((cat) {
                final isSelected = _selectedCategory?.id == cat.id;
                return FilterChip(
                  selected: isSelected,
                  label: Text(cat.name),
                  avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                  onSelected: (val) => setState(() => _selectedCategory = val ? cat : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Date & Notes
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat('MMMM dd, yyyy').format(_selectedDate)),
              onTap: _selectDate,
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: appState.isLoading ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                child: Text(widget.transaction != null ? 'Update' : 'Add Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
