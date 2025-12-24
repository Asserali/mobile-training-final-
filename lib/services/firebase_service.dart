import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/card_model.dart';
import '../models/category.dart';
import '../models/notification_model.dart';

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

  /// Get user profile by ID
  Future<Map<String, dynamic>?> getUserProfileById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Find user by phone number
  Future<Map<String, dynamic>?> findUserByPhone(String phone) async {
    final result = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: phone)
        .limit(1)
        .get();
    
    if (result.docs.isEmpty) return null;
    return {
      'uid': result.docs.first.id,
      'data': result.docs.first.data(),
    };
  }

  /// Find user by national ID or account number
  Future<Map<String, dynamic>?> findUserByNationalId(String nationalId) async {
    final result = await _firestore
        .collection('users')
        .where('nationalId', isEqualTo: nationalId)
        .limit(1)
        .get();
    
    if (result.docs.isEmpty) return null;
    return {
      'uid': result.docs.first.id,
      'data': result.docs.first.data(),
    };
  }

  /// Find user and account by card number
  Future<Map<String, dynamic>?> findUserByCardNumber(String cardNumber) async {
    try {
      // We use collectionGroup to search across all 'cards' subcollections
      final query = await _firestore
          .collectionGroup('cards')
          .where('cardNumber', isEqualTo: cardNumber)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print('findUserByCardNumber: No card found for $cardNumber');
        return null;
      }
      
      final cardDoc = query.docs.first;
      final accountId = cardDoc.data()['accountId'] as String;
      // The user ID is the parent of the cards collection (users/{uid}/cards/{cardId})
      final uid = cardDoc.reference.parent.parent!.id;
      
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      return {
        'uid': uid,
        'accountId': accountId,
        'userData': userDoc.data(),
      };
    } catch (e) {
      print('Error in findUserByCardNumber: $e');
      return null;
    }
  }

  // Transaction Methods

  /// Add transaction
  Future<void> addTransaction(Transaction transaction) async {
    if (currentUserId == null) throw Exception('No user logged in');
    await addTransactionToUser(currentUserId!, transaction);
  }

  /// Add transaction to specific user
  Future<void> addTransactionToUser(String uid, Transaction transaction) async {
    await _firestore
        .collection('users')
        .doc(uid)
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

  /// Update account balance directly for P2P
  Future<void> updateAccountBalanceDirect(String uid, String accountId, double amount) async {
    final accountRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(accountId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(accountRef);
      if (!snapshot.exists) return;
      
      final currentBalance = (snapshot.data()?['balance'] as num).toDouble();
      transaction.update(accountRef, {'balance': currentBalance + amount});
    });
  }

  /// Get specific account
  Future<Account?> getAccountById(String uid, String accountId) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(accountId)
        .get();
    
    if (!doc.exists) return null;
    return Account.fromFirestore(doc);
  }

  /// Get primary account (first one found)
  Future<Account?> getPrimaryAccount(String uid) async {
    final query = await _firestore
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) return null;
    return Account.fromFirestore(query.docs.first);
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

  // Notification Methods

  /// Add notification
  Future<void> addNotification(NotificationItem notification) async {
    if (currentUserId == null) throw Exception('No user logged in');
    await addNotificationToUser(currentUserId!, notification);
  }

  /// Add notification to specific user
  Future<void> addNotificationToUser(String uid, NotificationItem notification) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());
  }

  /// Get all notifications
  Stream<List<NotificationItem>> getNotifications() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .orderBy('time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationItem.fromMap(doc.data()))
            .toList());
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
        
    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }
  // Contact Methods
  Future<void> addContact(Map<String, String> contact) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('contacts')
        .add({
          ...contact,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<List<Map<String, dynamic>>> getContacts() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('contacts')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
              ...doc.data(),
              'id': doc.id,
            })
            .toList());
  }

  Future<void> removeContact(String contactId) async {
    if (currentUserId == null) throw Exception('No user logged in');
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('contacts')
        .doc(contactId)
        .delete();
  }
}
