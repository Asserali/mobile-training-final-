import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart' as models;
import '../models/budget.dart';
import '../models/card_model.dart';
import '../services/firebase_service.dart';
import '../models/notification_model.dart';

class AppState extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();

  // Stream subscriptions
  StreamSubscription? _accountsSubscription;
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _categoriesSubscription;
  StreamSubscription? _budgetsSubscription;
  StreamSubscription? _cardsSubscription;
  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _contactsSubscription;
  StreamSubscription? _authSubscription;

  // Authentication
  bool _isAuthenticated = false;
  String? _currentUserId;

  // Data
  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  List<models.Category> _categories = [];
  List<Budget> _budgets = [];
  List<BankCard> _cards = [];
  List<NotificationItem> _notifications = [];
  List<Map<String, dynamic>> _contacts = [];
  Map<String, dynamic>? _userProfile;
  
  // UI State
  bool _isLoading = false;
  String? _error;
  Account? _selectedAccount;
  BankCard? _activeCard;
  bool _showBalance = true;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  List<Account> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  List<models.Category> get categories => _categories;
  List<Budget> get budgets => _budgets;
  List<BankCard> get cards => _cards;
  List<NotificationItem> get notifications => _notifications;
  List<Map<String, dynamic>> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Account? get selectedAccount => _selectedAccount;
  BankCard? get activeCard => _activeCard;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get showBalance => _showBalance;

  double get totalBalance {
    return _accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  List<Transaction> get recentTransactions {
    final sorted = List<Transaction>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  models.Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  void selectAccount(Account account) {
    _selectedAccount = account;
    notifyListeners();
  }

  void toggleBalanceVisibility() {
    _showBalance = !_showBalance;
    notifyListeners();
  }

  double getTotalIncome(DateTime start, DateTime end) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.isAfter(start) &&
            t.date.isBefore(end))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenses(DateTime start, DateTime end) {
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.isAfter(start) &&
            t.date.isBefore(end))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions
        .where((t) => t.date.isAfter(start) && t.date.isBefore(end))
        .toList();
  }

  Map<String, double> getSpendingByCategory(DateTime start, DateTime end) {
    final spending = <String, double>{};
    for (var transaction in _transactions) {
      if (transaction.type == TransactionType.expense &&
          transaction.date.isAfter(start) &&
          transaction.date.isBefore(end)) {
        spending[transaction.category] =
            (spending[transaction.category] ?? 0) + transaction.amount;
      }
    }
    return spending;
  }

  // Initialize app with Firebase
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _authSubscription = _firebase.authStateChanges.listen((user) async {
        _isAuthenticated = user != null;
        _currentUserId = user?.uid;
        notifyListeners();

        if (_isAuthenticated) {
          await loadUserProfile();
          await _setupDataListeners();
        } else {
          _cancelDataListeners();
          _clearData();
        }
      });

      _isAuthenticated = _firebase.currentUser != null;
      _currentUserId = _firebase.currentUserId;

      if (_isAuthenticated) {
        await loadUserProfile();
        await _setupDataListeners().timeout(
          const Duration(seconds: 10),
          onTimeout: () => debugPrint('⚠️ Data setup timed out'),
        );
        await _ensureDefaultData();
      }
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _setupDataListeners() async {
    _accountsSubscription = _firebase.getAccounts().listen(
      (accounts) {
        _accounts = accounts;
        if (_accounts.isNotEmpty && _selectedAccount == null) {
          _selectedAccount = _accounts.first;
        }
        notifyListeners();
      },
      onError: (e) => debugPrint('Accounts error: $e'),
    );

    _transactionsSubscription = _firebase.getTransactions().listen(
      (transactions) {
        _transactions = transactions;
        notifyListeners();
      },
      onError: (e) => debugPrint('Transactions error: $e'),
    );

    _categoriesSubscription = _firebase.getCategories().listen(
      (categories) {
        _categories = categories;
        notifyListeners();
      },
      onError: (e) => debugPrint('Categories error: $e'),
    );

    _budgetsSubscription = _firebase.getBudgets().listen(
      (budgets) {
        _budgets = budgets;
        notifyListeners();
      },
      onError: (e) => debugPrint('Budgets error: $e'),
    );

    _cardsSubscription = _firebase.getCards().listen(
      (cards) {
        _cards = cards;
        if (_cards.isNotEmpty) {
          try {
            _activeCard = _cards.firstWhere((c) => c.isDefault);
          } catch (e) {
            _activeCard = _cards.first;
          }
        } else {
          _activeCard = null;
        }
        notifyListeners();
      },
      onError: (e) => debugPrint('Cards error: $e'),
    );

    _notificationsSubscription = _firebase.getNotifications().listen(
      (notifications) {
        _notifications = notifications;
        notifyListeners();
      },
      onError: (e) => debugPrint('Notifications error: $e'),
    );

    _contactsSubscription = _firebase.getContacts().listen(
      (contacts) {
        _contacts = contacts;
        notifyListeners();
      },
      onError: (e) => debugPrint('Contacts error: $e'),
    );
  }

  void _cancelDataListeners() {
    _accountsSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    _budgetsSubscription?.cancel();
    _cardsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _contactsSubscription?.cancel();
  }

  void _clearData() {
    _accounts = [];
    _transactions = [];
    _categories = [];
    _budgets = [];
    _cards = [];
    _notifications = [];
    _selectedAccount = null;
    _activeCard = null;
    _userProfile = null;
    notifyListeners();
  }

  Future<void> _ensureDefaultData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_accounts.isEmpty) {
      final defaultAccount = Account(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Main Account',
        balance: 500.0,
        type: AccountType.checking,
        createdAt: DateTime.now(),
      );
      await addAccount(defaultAccount);
    }
    if (_categories.isEmpty) {
      for (var category in models.DefaultCategories.allCategories) {
        await _firebase.addCategory(category);
      }
    }
  }

  // Auth operations
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _firebase.signInWithEmail(email, password);
      return true;
    } catch (e) {
      _setError('Sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    try {
      await _firebase.registerWithEmail(email, password, name);
      return true;
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _firebase.signOut();
      _cancelDataListeners();
      _clearData();
    } catch (e) {
      _setError('Logout failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Account operations
  Future<void> addAccount(Account account) async {
    try {
      await _firebase.addAccount(account);
    } catch (e) {
      _setError('Failed to add account: $e');
    }
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    try {
      final account = _accounts.firstWhere((a) => a.id == accountId);
      await _firebase.updateAccount(account.copyWith(balance: newBalance));
    } catch (e) {
      _setError('Failed to update balance: $e');
    }
  }

  // Transaction operations
  Future<void> addTransaction(Transaction transaction) async {
    try {
      if (transaction.amount <= 0) {
        _setError('Amount must be positive');
        return;
      }

      final account = _accounts.firstWhere((a) => a.id == transaction.accountId);

        BankCard? card;
        try {
          card = _cards.firstWhere((c) => c.accountId == account.id);
        } catch (_) {
          // No card linked - that's fine for some accounts
        }
        
        if (card != null && card.status == CardStatus.frozen) {
          _setError('This card is frozen. Please unfreeze it to perform transactions.');
          return;
        }

        if (card != null && transaction.type == TransactionType.expense) {
          if (transaction.amount > card.dailyLimitRemaining) {
            _setError('Transaction exceeds daily limit of \$${card.dailyLimit}');
            return;
          }
          if (transaction.amount > card.monthlyLimitRemaining) {
            _setError('Transaction exceeds monthly limit of \$${card.monthlyLimit}');
            return;
          }
          
          // Update card spent amounts
          final updatedCard = card.copyWith(
            currentDailySpent: card.currentDailySpent + transaction.amount,
            currentMonthlySpent: card.currentMonthlySpent + transaction.amount,
          );
          await _firebase.updateCard(updatedCard);
        }
      } catch (e) {
        debugPrint('Error in limit/freeze validation: $e');
        // If it was a critical validation error that returned, we don't reach here.
        // If it was just "no card found", we continue.
      }

      final newBalance = transaction.type == TransactionType.income
          ? account.balance + transaction.amount
          : account.balance - transaction.amount;

      if (transaction.type == TransactionType.expense && newBalance < 0) {
        _setError('Insufficient balance');
        return;
      }

      await _firebase.addTransaction(transaction);
      await updateAccountBalance(account.id, newBalance);

      // Handle P2P Transfer if recipient is specified
      if (transaction.category == 'Transfer') {
        final recipientValue = transaction.title.replaceFirst('Sent to ', '');
        await _handleP2PTransfer(recipientValue, transaction.amount, transaction.notes);
      }

      // Add Notification if settings allow
      final settings = _userProfile?['notificationSettings'] as Map<String, dynamic>?;
      final showTransactionAlerts = settings?['transactionAlerts'] ?? true;
      final showPush = settings?['pushNotifications'] ?? true;

      if (showTransactionAlerts && showPush) {
        await addNotification(NotificationItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          icon: transaction.type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
          iconColor: transaction.type == TransactionType.income ? Colors.green : Colors.red,
          title: 'Transaction Alert',
          message: 'You ${transaction.type == TransactionType.income ? 'received' : 'spent'} \$${transaction.amount.toStringAsFixed(2)} for ${transaction.title}',
          time: DateTime.now(),
          category: 'Transactions',
        ));
      }
    } catch (e) {
      _setError('Failed to add transaction: $e');
    }
  }

  Future<void> _handleP2PTransfer(String recipient, double amount, String? notes) async {
    try {
      // 1. Find user by Phone or Account ID (UID)
      Map<String, dynamic>? targetUser;
      String? targetUid;

      // Try searching by phone first (Egyptian format)
      if (recipient.startsWith('01') && recipient.length == 11) {
        final result = await _firebase.findUserByPhone(recipient);
        if (result != null) {
          targetUser = result['data'];
          targetUid = result['uid'];
        }
      }

      // If not found by phone, try searching by National ID / Account ID (numeric)
      if (targetUid == null && RegExp(r'^\d+$').hasMatch(recipient)) {
        final result = await _firebase.findUserByNationalId(recipient);
        if (result != null) {
          targetUser = result['data'];
          targetUid = result['uid'];
        }
      }

      // If not found yet, try searching by UID (Account ID)
      if (targetUid == null) {
        final result = await _firebase.getUserProfileById(recipient);
        if (result != null) {
          targetUser = result;
          targetUid = recipient;
        }
      }

      if (targetUid != null) {
        // 2. Add income transaction to recipient
        final incomeTransaction = Transaction(
          id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
          accountId: 'main', // Default to their main account
          title: 'Received from ${_userProfile?['name'] ?? 'Unknown'}',
          amount: amount,
          date: DateTime.now(),
          type: TransactionType.income,
          category: 'Transfer',
          notes: notes,
        );

        await _firebase.addTransactionToUser(targetUid, incomeTransaction);
        
        // 3. Update recipient balance (this is tricky because we don't know their account IDs easily)
        // For simulation, we'll assume they have a 'main' account or we just record the transaction.
        // A real system would have a more complex ledger.
        
        // 4. Send notification to recipient
        await _firebase.addNotificationToUser(targetUid, NotificationItem(
          id: 'not_${DateTime.now().millisecondsSinceEpoch}',
          icon: Icons.account_balance_wallet,
          iconColor: Colors.green,
          title: 'Money Received',
          message: 'You received \$${amount.toStringAsFixed(2)} from ${_userProfile?['name'] ?? 'Unknown'}',
          time: DateTime.now(),
          category: 'Transfer',
        ));
        
        debugPrint('P2P Transfer successful to $targetUid');
      } else {
        debugPrint('Recipient $recipient not found in system - transaction remains local');
      }
    } catch (e) {
      debugPrint('Error in P2P transfer logic: $e');
    }
  }

  Future<void> updateTransaction(Transaction oldTransaction, Transaction newTransaction) async {
    try {
      final account = _accounts.firstWhere((a) => a.id == oldTransaction.accountId);
      
      // Revert old transaction
      double balanceAfterRevert = oldTransaction.type == TransactionType.income
          ? account.balance - oldTransaction.amount
          : account.balance + oldTransaction.amount;
      
      // Apply new transaction
      double finalBalance = newTransaction.type == TransactionType.income
          ? balanceAfterRevert + newTransaction.amount
          : balanceAfterRevert - newTransaction.amount;

      if (newTransaction.type == TransactionType.expense && finalBalance < 0) {
        _setError('Insufficient balance');
        return;
      }

      await _firebase.updateTransaction(newTransaction);
      await updateAccountBalance(account.id, finalBalance);
    } catch (e) {
      _setError('Failed to update transaction: $e');
    }
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    try {
      final account = _accounts.firstWhere((a) => a.id == transaction.accountId);
      final newBalance = transaction.type == TransactionType.income
          ? account.balance - transaction.amount
          : account.balance + transaction.amount;

      await _firebase.deleteTransaction(transaction.id);
      await updateAccountBalance(account.id, newBalance);
    } catch (e) {
      _setError('Failed to delete transaction: $e');
    }
  }

  // Card operations
  Future<void> addCard(BankCard card, {double initialBalance = 0.0}) async {
    try {
      // 1. Create separate account for this card if requested
      final accountId = 'acc_card_${DateTime.now().millisecondsSinceEpoch}';
      final newAccount = Account(
        id: accountId,
        name: '${card.network.name.toUpperCase()} Card Account',
        balance: initialBalance,
        type: AccountType.checking,
        createdAt: DateTime.now(),
      );
      await addAccount(newAccount);

      // 2. Link card to new account
      BankCard cardToAdd = card.copyWith(
        accountId: accountId,
        isDefault: _cards.isEmpty,
      );
      
      await _firebase.addCard(cardToAdd);

      // 3. Add Notification
      await addNotification(NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        icon: Icons.credit_card,
        iconColor: Colors.blue,
        title: 'Card Added Successfully',
        message: 'Your ${card.network.name} card ending in ${card.cardNumber.substring(card.cardNumber.length - 4)} has been added.',
        time: DateTime.now(),
        category: 'Cards',
      ));
    } catch (e) {
      _setError('Failed to add card: $e');
    }
  }

  Future<void> updateCard(BankCard card) async {
    try {
      await _firebase.updateCard(card);
    } catch (e) {
      _setError('Failed to update card: $e');
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      await _firebase.deleteCard(cardId);
    } catch (e) {
      _setError('Failed to delete card: $e');
    }
  }

  Future<void> setActiveCard(String cardId) async {
    try {
      _setLoading(true);
      for (var card in _cards) {
        if (card.id == cardId && !card.isDefault) {
          await _firebase.updateCard(card.copyWith(isDefault: true));
        } else if (card.id != cardId && card.isDefault) {
          await _firebase.updateCard(card.copyWith(isDefault: false));
        }
      }
    } catch (e) {
      _setError('Failed to set active card: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserProfile() async {
    if (_currentUserId == null) return;
    try {
      final profile = await _firebase.getUserProfile();
      if (profile != null) {
        _userProfile = profile;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      await _firebase.updateUserProfile(data);
      await loadUserProfile();
    } catch (e) {
      _setError('Failed to update profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Notification operations
  Future<void> addNotification(NotificationItem notification) async {
    try {
      await _firebase.addNotification(notification);
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    try {
      await _firebase.markNotificationAsRead(id);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await _firebase.markAllNotificationsAsRead();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  // Contact operations
  Future<void> addContact(String name, String value, String type) async {
    try {
      await _firebase.addContact({
        'name': name,
        'value': value,
        'type': type,
      });
    } catch (e) {
      _setError('Failed to add contact: $e');
    }
  }

  Future<void> removeContact(String id) async {
    try {
      await _firebase.removeContact(id);
    } catch (e) {
      _setError('Failed to remove contact: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelDataListeners();
    _authSubscription?.cancel();
    super.dispose();
  }
}
