import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart' as models;
import '../models/budget.dart';
import '../services/firebase_service.dart';

class AppState extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();

  // Stream subscriptions
  StreamSubscription? _accountsSubscription;
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _categoriesSubscription;
  StreamSubscription? _budgetsSubscription;
  StreamSubscription? _authSubscription;

  // Authentication
  bool _isAuthenticated = false;
  String? _currentUserId;

  // Data
  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  List<models.Category> _categories = [];
  List<Budget> _budgets = [];
  Map<String, dynamic>? _userProfile;

  // UI State
  bool _isLoading = false;
  String? _error;
  Account? _selectedAccount;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  List<Account> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  List<models.Category> get categories => _categories;
  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Account? get selectedAccount => _selectedAccount;
  Map<String, dynamic>? get userProfile => _userProfile;

  double get totalBalance {
    return _accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  List<Transaction> get recentTransactions {
    final sorted = List<Transaction>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  // Initialize app with Firebase
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Listen to auth state changes
      _authSubscription = _firebase.authStateChanges.listen((user) async {
        _isAuthenticated = user != null;
        _currentUserId = user?.uid;
        notifyListeners();

        if (_isAuthenticated) {
          await loadUserProfile();
          _setupDataListeners();
        } else {
          _cancelDataListeners();
          _clearData();
        }
      });

      // Check current auth state
      _isAuthenticated = _firebase.currentUser != null;
      _currentUserId = _firebase.currentUserId;

      if (_isAuthenticated) {
        // Load user profile
        await loadUserProfile();
        
        // Add timeout to prevent hanging on slow connections
        await _setupDataListeners().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('⚠️ Data listener setup timed out, continuing anyway...');
          },
        );
        await _ensureDefaultData().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('⚠️ Default data creation timed out, continuing anyway...');
          },
        );
      }
    } catch (e) {
      _setError('Failed to initialize: $e');
      debugPrint('Initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Setup real-time listeners for Firebase data
  Future<void> _setupDataListeners() async {
    // Listen to accounts
    _accountsSubscription = _firebase.getAccounts().listen(
      (accounts) {
        _accounts = accounts;
        if (_accounts.isNotEmpty && _selectedAccount == null) {
          _selectedAccount = _accounts.first;
        }
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Accounts stream error: $error');
      },
    );

    // Listen to transactions
    _transactionsSubscription = _firebase.getTransactions().listen(
      (transactions) {
        _transactions = transactions;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Transactions stream error: $error');
      },
    );

    // Listen to categories
    _categoriesSubscription = _firebase.getCategories().listen(
      (categories) {
        _categories = categories;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Categories stream error: $error');
      },
    );

    // Listen to budgets
    _budgetsSubscription = _firebase.getBudgets().listen(
      (budgets) {
        _budgets = budgets;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Budgets stream error: $error');
      },
    );
  }

  // Cancel all data listeners
  void _cancelDataListeners() {
    _accountsSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    _budgetsSubscription?.cancel();
  }

  // Clear local data
  void _clearData() {
    _accounts = [];
    _transactions = [];
    _categories = [];
    _budgets = [];
    _selectedAccount = null;
    _userProfile = null;
    notifyListeners();
  }

  // Ensure default data exists
  Future<void> _ensureDefaultData() async {
    // Wait a bit for initial data load
    await Future.delayed(const Duration(milliseconds: 500));

    // Create default account if none exists
    if (_accounts.isEmpty) {
      final defaultAccount = Account(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Main Account',
        balance: 10000.0, // Demo balance
        type: AccountType.checking,
        createdAt: DateTime.now(),
      );
      await addAccount(defaultAccount);
    }

    // Create default categories if none exist
    if (_categories.isEmpty) {
      for (var category in models.DefaultCategories.allCategories) {
        await _firebase.addCategory(category);
      }
    }
  }

  // Authentication
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
      // Data will update automatically via stream
    } catch (e) {
      _setError('Failed to add account: $e');
    }
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    try {
      final account = _accounts.firstWhere((a) => a.id == accountId);
      final updated = account.copyWith(balance: newBalance);
      await _firebase.updateAccount(updated);
      // Data will update automatically via stream
    } catch (e) {
      _setError('Failed to update account: $e');
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      await _firebase.deleteAccount(accountId);
      // Data will update automatically via stream
    } catch (e) {
      _setError('Failed to delete account: $e');
    }
  }

  void selectAccount(Account account) {
    _selectedAccount = account;
    notifyListeners();
  }

  // Transaction operations
  Future<void> addTransaction(Transaction transaction) async {
    try {
      // Validate amount
      if (transaction.amount <= 0) {
        _setError('Amount must be greater than 0');
        return;
      }

      // Get account
      final account = _accounts.firstWhere((a) => a.id == transaction.accountId);

      // Calculate new balance
      final newBalance = transaction.type == TransactionType.income
          ? account.balance + transaction.amount
          : account.balance - transaction.amount;

      // Check for negative balance on expense
      if (transaction.type == TransactionType.expense && newBalance < 0) {
        _setError('Insufficient balance');
        return;
      }

      // Add transaction and update balance
      await _firebase.addTransaction(transaction);
      await updateAccountBalance(account.id, newBalance);
      // Data will update automatically via stream
    } catch (e) {
      _setError('Failed to add transaction: $e');
    }
  }

  Future<void> updateTransaction(Transaction oldTransaction, Transaction newTransaction) async {
    try {
      // Reverse old transaction effect
      final account = _accounts.firstWhere((a) => a.id == oldTransaction.accountId);
      double balance = account.balance;

      if (oldTransaction.type == TransactionType.income) {
        balance -= oldTransaction.amount;
      } else {
        balance += oldTransaction.amount;
      }

      // Apply new transaction effect
      if (newTransaction.type == TransactionType.income) {
        balance += newTransaction.amount;
      } else {
        balance -= newTransaction.amount;
      }

      if (balance < 0) {
        _setError('Insufficient balance');
        return;
      }

      await _firebase.updateTransaction(newTransaction);
      await updateAccountBalance(account.id, balance);
      // Data will update automatically via stream
    } catch (e) {
      _setError('Failed to update transaction: $e');
    }
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    try {
      // Reverse transaction effect on balance
      final account = _accounts.firstWhere((a) => a.id == transaction.accountId);
      final newBalance = transaction.type == TransactionType.income
          ? account.balance - transaction.amount
          : account.balance + transaction.amount;

      await _firebase.deleteTransaction(transaction.id);
      await updateAccountBalance(account.id, newBalance);
      // Data will update automatically via stream
    } catch (e) {
      _setError('Failed to delete transaction: $e');
    }
  }

  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions
        .where((t) => t.date.isAfter(start) && t.date.isBefore(end))
        .toList();
  }

  // Category operations
  models.Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Budget operations
  Future<void> addBudget(Budget budget) async {
    try {
      await _firebase.addBudget(budget);
      // Data will update automatically via stream
    } catch (e) {
      _setError('Failed to add budget: $e');
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      await _firebase.updateBudget(budget);
      // Data will update automatically via stream
    } catch (e) {
      _setError('Failed to update budget: $e');
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      await _firebase.deleteBudget(budgetId);
      // Data will update automatically via stream
    } catch (e) {
      _setError('Failed to delete budget: $e');
    }
  }

  // Analytics
  Map<String, double> getSpendingByCategory(DateTime start, DateTime end) {
    final Map<String, double> spending = {};
    final filtered = _transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.date.isAfter(start) &&
        t.date.isBefore(end));

    for (var transaction in filtered) {
      spending[transaction.category] =
          (spending[transaction.category] ?? 0.0) + transaction.amount;
    }

    return spending;
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

  double getSpentForCategory(String categoryId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _transactions
        .where((t) =>
            t.category == categoryId &&
            t.type == TransactionType.expense &&
            t.date.isAfter(startOfMonth) &&
            t.date.isBefore(endOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // User Profile
  Future<void> loadUserProfile() async {
    if (_currentUserId == null) return;
    
    try {
      // Try with FirebaseService (real)
      final profile = await _firebase.getUserProfile();
      if (profile != null) {
        _userProfile = profile;
        notifyListeners();
        return;
      }
      
      // Fallback to MockFirebaseService for hybrid usage if needed, 
      // or if you want to be explicit about using the Mock service that handles the custom registration.
      // Since AppState uses FirebaseService by default, we should double check if FirebaseService has getUserProfile.
      // It does (I checked earlier).
      
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  // Helper methods
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

