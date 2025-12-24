import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/card_model.dart';
import '../models/notification_model.dart';
import '../widgets/transaction_tile.dart';
import 'add_card_screen.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  int _focusedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final cards = appState.cards;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Cards',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddCardScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Card Carousel
            if (cards.isEmpty)
              SizedBox(
                height: 220,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No cards added yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddCardScreen()),
                        ),
                        child: const Text('Add your first card'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: PageView.builder(
                  padEnds: false,
                  controller: _pageController,
                  itemCount: cards.length,
                  onPageChanged: (index) {
                    setState(() {
                      _focusedIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return _buildCard(
                      context,
                      card: card,
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),

            // Quick Actions
            if (cards.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        icon: cards[_focusedIndex].status == CardStatus.frozen
                            ? Icons.lock_open_outlined
                            : Icons.lock_outline,
                        label: cards[_focusedIndex].status == CardStatus.frozen
                            ? 'Unfreeze Card'
                            : 'Freeze Card',
                        onTap: () {
                          final selectedCard = cards[_focusedIndex];
                          final isFrozen = selectedCard.status == CardStatus.frozen;
                          final updatedCard = selectedCard.copyWith(
                            status: isFrozen ? CardStatus.active : CardStatus.frozen,
                          );
                          appState.updateCard(updatedCard);
                          
                          // Add notification
                          appState.addNotification(NotificationItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            icon: isFrozen ? Icons.lock_open : Icons.lock,
                            iconColor: Colors.blue,
                            title: isFrozen ? 'Card Unfrozen' : 'Card Frozen',
                            message: 'Your ${selectedCard.network.name} card ending in ${selectedCard.cardNumber.substring(selectedCard.cardNumber.length - 4)} has been ${isFrozen ? 'unfrozen' : 'frozen'}.',
                            time: DateTime.now(),
                            category: 'Cards',
                          ));

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isFrozen ? 'Card unfrozen!' : 'Card frozen!'),
                              backgroundColor: const Color(0xFF00E676),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.credit_card,
                        label: 'Virtual Card',
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (_) => const CreateVirtualCardSheet(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Card Transactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Builder(
                builder: (context) {
                  final cardTransactions = cards.isNotEmpty 
                    ? appState.transactions.where((t) => t.accountId == cards[_focusedIndex].accountId).toList()
                    : <Transaction>[];
                  
                  if (cardTransactions.isEmpty) {
                    return Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No card transactions yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: cardTransactions.length,
                    itemBuilder: (context, index) {
                      return TransactionTile(transaction: cardTransactions[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required BankCard card,
  }) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final appState = Provider.of<AppState>(context, listen: false);
    final isDefault = card.isDefault;
    
    // Get specific account balance for this card
    double cardBalance = 0.0;
    try {
      final account = appState.accounts.firstWhere((a) => a.id == card.accountId);
      cardBalance = account.balance;
    } catch (e) {
      cardBalance = 0.0;
    }

    return GestureDetector(
      onLongPress: () {
        if (!isDefault) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Set as Active Card?'),
              content: const Text('This card will be shown on your home screen and used for primary transactions.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    appState.setActiveCard(card.id);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                  child: const Text('Set Active'),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16, bottom: 8, top: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: card.status == CardStatus.frozen
                ? [Colors.grey[700]!, Colors.grey[900]!]
                : [card.cardColor, card.cardColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: card.cardColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: isDefault
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            if (isDefault)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.star, color: Colors.yellow, size: 20),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card.network.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      card.status == CardStatus.frozen ? Icons.ac_unit : Icons.contactless,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${cardBalance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.status == CardStatus.frozen ? 'CARD FROZEN' : 'Card Balance',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.isVirtual ? 'VIRTUAL CARD' : card.maskedCardNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card.cardHolderName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'VALID THRU',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 8,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          card.expiryDateFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00E676)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Virtual Card Creation Sheet
class CreateVirtualCardSheet extends StatefulWidget {
  const CreateVirtualCardSheet({super.key});

  @override
  State<CreateVirtualCardSheet> createState() => _CreateVirtualCardSheetState();
}

class _CreateVirtualCardSheetState extends State<CreateVirtualCardSheet> {
  String _expiryPeriod = '24h';
  final _limitController = TextEditingController(text: '1000');
  final _balanceController = TextEditingController(text: '500');

  @override
  void dispose() {
    _limitController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: Color(0xFF00E676),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Virtual Card',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Temporary card for online shopping',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Valid For',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: _expiryPeriod,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: '24h', child: Text('24 Hours')),
                  DropdownMenuItem(value: '7d', child: Text('7 Days')),
                  DropdownMenuItem(value: '30d', child: Text('30 Days')),
                ],
                onChanged: (value) => setState(() => _expiryPeriod = value!),
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Initial Balance',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _balanceController,
              decoration: InputDecoration(
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '500',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            const Text(
              'Daily Spending Limit',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _limitController,
              decoration: InputDecoration(
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '1000',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Virtual cards are perfect for online shopping. They expire automatically and can be deleted anytime.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  final initialBalance = double.tryParse(_balanceController.text) ?? 500.0;
                  
                  final newCard = BankCard(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    accountId: 'temp', // Will be set by appState.addCard
                    cardNumber: List.generate(16, (index) => (index == 0 ? 4 : (DateTime.now().millisecond + index) % 10)).join(),
                    cardHolderName: appState.userProfile?['fullNameEnglish'] ?? 'VALUED CUSTOMER',
                    type: CardType.prepaid,
                    network: CardNetwork.visa,
                    expiryDate: DateTime.now().add(const Duration(days: 1)),
                    isVirtual: true,
                    cardColor: Colors.deepPurple,
                  );
                  appState.addCard(newCard, initialBalance: initialBalance);
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Virtual card created!'),
                      backgroundColor: Color(0xFF00E676),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  'Create Virtual Card',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
