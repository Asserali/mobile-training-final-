import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/card_model.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  
  String _selectedCardType = 'visa';
  
  final Map<String, Map<String, dynamic>> _cardTypes = {
    'visa': {
      'name': 'Visa',
      'color': const Color(0xFF1A1F71),
      'icon': Icons.credit_card,
      'network': CardNetwork.visa,
    },
    'mastercard': {
      'name': 'Mastercard',
      'color': const Color(0xFFEB001B),
      'icon': Icons.credit_card,
      'network': CardNetwork.mastercard,
    },
    'meeza': {
      'name': 'Meeza',
      'color': const Color(0xFFFF6F00),
      'icon': Icons.credit_card,
      'network': CardNetwork.meeza,
    },
  };

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += value[i];
    }
    return formatted;
  }

  String _formatExpiry(String value) {
    value = value.replaceAll('/', '');
    if (value.length >= 2) {
      return '${value.substring(0, 2)}/${value.substring(2)}';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Card'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Card Preview
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _cardTypes[_selectedCardType]!['color'] as Color,
                    (_cardTypes[_selectedCardType]!['color'] as Color).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_cardTypes[_selectedCardType]!['color'] as Color).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _cardTypes[_selectedCardType]!['name'].toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const Text(
                        'BALANCE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '\$${(double.tryParse(_balanceController.text) ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'CARD NUMBER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cardNumberController.text.isEmpty
                        ? '**** **** **** ****'
                        : _formatCardNumber(_cardNumberController.text),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CARD HOLDER NAME',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _cardHolderController.text.isEmpty
                                ? 'N/A'
                                : _cardHolderController.text.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'VALID',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _expiryController.text.isEmpty
                                ? 'N/A'
                                : _expiryController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card Type Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _cardTypes.keys.map((type) {
                  final isSelected = _selectedCardType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCardType = type),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00E676) : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _cardTypes[type]!['icon'] as IconData,
                            color: _cardTypes[type]!['color'] as Color,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _cardTypes[type]!['name'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Form
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _cardHolderController,
                      decoration: InputDecoration(
                        hintText: 'Card Holder Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) => setState(() {}),
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cardNumberController,
                      decoration: InputDecoration(
                        hintText: 'Card Number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                      ],
                      onChanged: (value) => setState(() {}),
                      validator: (value) => (value == null || value.length < 13) ? 'Invalid card number' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _expiryController,
                            decoration: InputDecoration(
                              hintText: 'MM/YY',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _expiryController.text = _formatExpiry(value);
                                _expiryController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _expiryController.text.length),
                                );
                              });
                            },
                            validator: (value) => (value == null || value.length < 5) ? 'Invalid' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _balanceController,
                            decoration: InputDecoration(
                              hintText: 'Initial Balance',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final last4 = _cardNumberController.text.substring(_cardNumberController.text.length - 4);
                            
                            final expiryParts = _expiryController.text.split('/');
                            final expiryDate = DateTime(
                              2000 + int.parse(expiryParts[1]),
                              int.parse(expiryParts[0]),
                            );

                            final newCard = BankCard(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              accountId: 'pending', // Set by appState.addCard
                              cardNumber: last4,
                              cardHolderName: _cardHolderController.text,
                              type: CardType.debit,
                              network: _cardTypes[_selectedCardType]!['network'] as CardNetwork,
                              expiryDate: expiryDate,
                              cardColor: _cardTypes[_selectedCardType]!['color'] as Color,
                              isVirtual: false,
                            );

                            final initialBalance = double.tryParse(_balanceController.text) ?? 0.0;
                            await appState.addCard(newCard, initialBalance: initialBalance);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Card added successfully!'),
                                  backgroundColor: Color(0xFF00E676),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Add Card',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
