import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/card_model.dart';
import '../models/category.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Authentication Methods
  
  /// Register new user with email and password
  Future<UserCredential> registerWithEmail(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send email verification
      await credential.user!.sendEmailVerification();

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore.collection('users').doc(currentUserId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUserId == null) return null;
    
    final doc = await _firestore.collection('users').doc(currentUserId).get();
    return doc.data();
  }

  // Transaction Methods

  /// Add transaction
  Future<void> addTransaction(Transaction transaction) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toFirestore());
  }

  /// Update transaction
  Future<void> updateTransaction(Transaction transaction) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toFirestore());
  }

  /// Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  /// Get all transactions
  Stream<List<Transaction>> getTransactions() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Transaction.fromFirestore(doc))
            .toList());
  }

  // Account Methods

  /// Add account
  Future<void> addAccount(Account account) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('accounts')
        .doc(account.id)
        .set(account.toFirestore());
  }

  /// Update account
  Future<void> updateAccount(Account account) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('accounts')
        .doc(account.id)
        .update(account.toFirestore());
  }

  /// Delete account
  Future<void> deleteAccount(String accountId) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('accounts')
        .doc(accountId)
        .delete();
  }

  /// Get all accounts
  Stream<List<Account>> getAccounts() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('accounts')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Account.fromFirestore(doc))
            .toList());
  }

  // Budget Methods

  /// Add budget
  Future<void> addBudget(Budget budget) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('budgets')
        .doc(budget.id)
        .set(budget.toFirestore());
  }

  /// Update budget
  Future<void> updateBudget(Budget budget) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('budgets')
        .doc(budget.id)
        .update(budget.toFirestore());
  }

  /// Delete budget
  Future<void> deleteBudget(String budgetId) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('budgets')
        .doc(budgetId)
        .delete();
  }

  /// Get all budgets
  Stream<List<Budget>> getBudgets() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('budgets')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Budget.fromFirestore(doc))
            .toList());
  }

  // Category Methods

  /// Add category
  Future<void> addCategory(Category category) async {
    if (currentUserId == null) throw Exception('No user logged in');

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('categories')
        .doc(category.id)
        .set(category.toFirestore());
  }

  /// Update category
  Future<void> updateCategory(Category category) async {
    if (currentUserId == null) throw Exception('No user logged in');

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('categories')
        .doc(category.id)
        .update(category.toFirestore());
  }

  /// Delete category
  Future<void> deleteCategory(String categoryId) async {
    if (currentUserId == null) throw Exception('No user logged in');

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  /// Get all categories
  Stream<List<Category>> getCategories() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromFirestore(doc))
            .toList());
  }

  // Card Methods

  /// Add card
  Future<void> addCard(BankCard card) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('cards')
        .doc(card.id)
        .set(card.toFirestore());
  }

  /// Update card
  Future<void> updateCard(BankCard card) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('cards')
        .doc(card.id)
        .update(card.toFirestore());
  }

  /// Delete card
  Future<void> deleteCard(String cardId) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('cards')
        .doc(cardId)
        .delete();
  }

  /// Get all cards
  Stream<List<BankCard>> getCards() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('cards')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BankCard.fromFirestore(doc))
            .toList());
  }
}
