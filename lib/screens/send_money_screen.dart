import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/account.dart';
import '../models/transaction.dart';

class SendMoneyScreen extends StatefulWidget {
  final String? initialRecipient;
  final double? initialAmount;

  const SendMoneyScreen({
    super.key,
    this.initialRecipient,
    this.initialAmount,
  });

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _amountController = TextEditingController(text: '0.00');
  final _descriptionController = TextEditingController();
  final _recipientController = TextEditingController();
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipient != null) {
      _recipientController.text = widget.initialRecipient!;
    }
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.accounts.isNotEmpty) {
      _selectedAccountId = (appState.selectedAccount ?? appState.accounts.first).id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    // Find the selected account object from the list to get the latest balance
    final selectedAccount = appState.accounts.firstWhere(
      (a) => a.id == _selectedAccountId,
      orElse: () => appState.accounts.isNotEmpty ? appState.accounts.first : appState.accounts[0], // fallback which should stay in sync
    );
    final double balance = selectedAccount.balance;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Send Money'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Input Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Enter Amount',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '\$',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: IntrinsicWidth(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            onChanged: (value) => setState(() {}),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '0.00',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Balance: ${currencyFormat.format(balance)}',
                    style: TextStyle(
                      color: balance < (double.tryParse(_amountController.text) ?? 0) 
                          ? Colors.red 
                          : const Color(0xFF00E676),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recipient Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recipient',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _recipientController,
                    decoration: InputDecoration(
                      hintText: 'Phone number or Account ID',
                      prefixIcon: const Icon(Icons.person_outline),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF00E676)),
                        onPressed: () {
                           // Mock QR Scanner logic
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Quick Selection',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _RecipientTypeTile(
                        icon: Icons.phone_android,
                        label: 'Phone Number',
                        onTap: () => _showContactsSheet(context, 'Phone'),
                      ),
                      const SizedBox(width: 16),
                      _RecipientTypeTile(
                        icon: Icons.badge_outlined,
                        label: 'Account ID',
                        onTap: () => _showContactsSheet(context, 'Account ID'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'What is this for?',
                      prefixIcon: const Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pay From Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pay From',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedAccountId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: appState.accounts.map((account) {
                      final card = appState.cards.where((c) => c.accountId == account.id).firstOrNull;
                      final suffix = card != null ? ' (ending with ${card.cardNumber})' : '';
                      return DropdownMenuItem(
                        value: account.id,
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet, color: Color(0xFF00E676), size: 20),
                            const SizedBox(width: 12),
                            Text('${account.name}$suffix'),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedAccountId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Total and Send Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total to pay',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        currencyFormat.format(double.tryParse(_amountController.text) ?? 0),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount = double.tryParse(_amountController.text) ?? 0.0;
                        if (amount <= 0) return;
                        if (amount > balance) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Insufficient balance'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        if (_recipientController.text.isEmpty) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a recipient'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        final transaction = Transaction(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          accountId: _selectedAccountId!,
                          title: 'Sent to ${_recipientController.text}',
                          amount: amount,
                          date: DateTime.now(),
                          type: TransactionType.expense,
                          category: 'transfer',
                          notes: _descriptionController.text,
                        );

                        await appState.addTransaction(transaction);

                        if (appState.error != null && mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(appState.error!), backgroundColor: Colors.red),
                          );
                          appState.clearError();
                          return;
                        }

                        // Check if we should save this recipient
                        final isAlreadySaved = appState.contacts.any((c) => c['value'] == _recipientController.text);
                        if (!isAlreadySaved) {
                          _showSaveContactDialog(context, _recipientController.text);
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Money sent successfully!'),
                              backgroundColor: Color(0xFF00E676),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Send Money',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactsSheet(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final appState = Provider.of<AppState>(context);
        final filteredContacts = appState.contacts.where((c) => c['type'] == type).toList();

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saved $type Contacts',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (filteredContacts.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No saved contacts for this type'),
                ))
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF00E676).withOpacity(0.1),
                        child: Text(contact['name'][0].toUpperCase(), style: const TextStyle(color: Color(0xFF00E676))),
                      ),
                      title: Text(contact['name']),
                      subtitle: Text(contact['value']),
                      onTap: () {
                        setState(() {
                          _recipientController.text = contact['value'];
                        });
                        Navigator.pop(context);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => appState.removeContact(contact['id']),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showSaveContactDialog(BuildContext context, String value) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Recipient?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Would you like to save this recipient for future use?'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Contact Name',
                hintText: 'e.g. Mom, John Doe',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back from SendMoneyScreen
            },
            child: const Text('No Thanks'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final appState = Provider.of<AppState>(context, listen: false);
                String type = 'Account ID';
                if (RegExp(r'^01[0-2,5]\d{8}$').hasMatch(value)) {
                  type = 'Phone';
                }
                await appState.addContact(nameController.text, value, type);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back from SendMoneyScreen
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            child: const Text('Save & Finish'),
          ),
        ],
      ),
    );
  }
}

class _RecipientTypeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RecipientTypeTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF00E676).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00E676).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF00E676)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00E676),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
