import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/category.dart' as models;
import '../services/database_helper.dart';

/// Test Data Generator
/// Creates a test account with sample data for testing
class TestDataGenerator {
  static Future<void> createTestAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final db = DatabaseHelper.instance;

    // Create test account credentials
    await prefs.setString('username', 'test@banking.com');
    await prefs.setString('password', 'test123');
    await prefs.setBool('isAuthenticated', true);
    await prefs.setString('userId', 'test@banking.com');

    print('✅ Test account created:');
    print('   Email: test@banking.com');
    print('   Password: test123');

    // Create sample accounts
    final savingsAccount = Account(
      id: 'acc_savings',
      name: 'Savings Account',
      type: AccountType.savings,
      balance: 12450.00,
      currency: 'USD',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
    );

    final checkingAccount = Account(
      id: 'acc_checking',
      name: 'Checking Account',
      type: AccountType.checking,
      balance: 3250.75,
      currency: 'USD',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    );

    await db.createAccount(savingsAccount);
    await db.createAccount(checkingAccount);
    print('✅ Created 2 accounts');

    // Create sample categories (they should already exist from default categories)
    final categories = await db.getAllCategories();
    print('✅ Found ${categories.length} categories');

    // Create sample transactions
    final now = DateTime.now();
    final transactions = [
      // Recent transactions
      Transaction(
        id: 'txn_1',
        title: 'Salary',
        amount: 5000.00,
        type: TransactionType.income,
        category: 'cat_salary',
        date: now.subtract(const Duration(days: 2)),
        accountId: savingsAccount.id,
      ),
      Transaction(
        id: 'txn_2',
        title: 'Grocery Shopping',
        amount: 156.50,
        type: TransactionType.expense,
        category: 'cat_food',
        date: now.subtract(const Duration(days: 1)),
        accountId: checkingAccount.id,
        notes: 'Weekly groceries at Supermarket',
      ),
      Transaction(
        id: 'txn_3',
        title: 'Coffee Shop',
        amount: 12.50,
        type: TransactionType.expense,
        category: 'cat_food',
        date: now.subtract(const Duration(hours: 5)),
        accountId: checkingAccount.id,
      ),
      Transaction(
        id: 'txn_4',
        title: 'Uber Ride',
        amount: 25.00,
        type: TransactionType.expense,
        category: 'cat_transport',
        date: now.subtract(const Duration(days: 3)),
        accountId: checkingAccount.id,
      ),
      Transaction(
        id: 'txn_5',
        title: 'Netflix Subscription',
        amount: 15.99,
        type: TransactionType.expense,
        category: 'cat_entertainment',
        date: now.subtract(const Duration(days: 5)),
        accountId: checkingAccount.id,
        notes: 'Monthly subscription',
      ),
      // Older transactions for analytics
      Transaction(
        id: 'txn_6',
        title: 'Freelance Project',
        amount: 1200.00,
        type: TransactionType.income,
        category: 'cat_salary',
        date: now.subtract(const Duration(days: 10)),
        accountId: savingsAccount.id,
      ),
      Transaction(
        id: 'txn_7',
        title: 'Electricity Bill',
        amount: 85.00,
        type: TransactionType.expense,
        category: 'cat_bills',
        date: now.subtract(const Duration(days: 12)),
        accountId: checkingAccount.id,
      ),
      Transaction(
        id: 'txn_8',
        title: 'Restaurant Dinner',
        amount: 67.50,
        type: TransactionType.expense,
        category: 'cat_food',
        date: now.subtract(const Duration(days: 7)),
        accountId: checkingAccount.id,
      ),
      Transaction(
        id: 'txn_9',
        title: 'Gas Station',
        amount: 45.00,
        type: TransactionType.expense,
        category: 'cat_transport',
        date: now.subtract(const Duration(days: 8)),
        accountId: checkingAccount.id,
      ),
      Transaction(
        id: 'txn_10',
        title: 'Online Shopping',
        amount: 199.99,
        type: TransactionType.expense,
        category: 'cat_shopping',
        date: now.subtract(const Duration(days: 15)),
        accountId: savingsAccount.id,
        notes: 'New headphones',
      ),
      Transaction(
        id: 'txn_11',
        title: 'Gym Membership',
        amount: 50.00,
        type: TransactionType.expense,
        category: 'cat_health',
        date: now.subtract(const Duration(days: 20)),
        accountId: checkingAccount.id,
      ),
      Transaction(
        id: 'txn_12',
        title: 'Bonus Payment',
        amount: 800.00,
        type: TransactionType.income,
        category: 'cat_salary',
        date: now.subtract(const Duration(days: 25)),
        accountId: savingsAccount.id,
      ),
    ];

    for (var transaction in transactions) {
      await db.createTransaction(transaction);
    }
    print('✅ Created ${transactions.length} transactions');

    print('\n🎉 Test data created successfully!');
    print('   Total Balance: \$${savingsAccount.balance + checkingAccount.balance}');
    print('   Transactions: ${transactions.length}');
    print('\n📝 Login with:');
    print('   Email: test@banking.com');
    print('   Password: test123');
  }

  /// Clear all test data
  static Future<void> clearTestData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // Note: Database will be cleared on next app restart
    print('✅ Test data cleared');
  }
}
