import 'package:flutter/material.dart';
import 'transaction.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'color': color.value,
      'type': type.toString().split('.').last,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
      color: Color(map['color'] as int),
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
    );
  }

  // Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'color': color.value,
      'type': type.toString().split('.').last,
    };
  }

  factory Category.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] as String,
      icon: IconData(data['icon'] as int, fontFamily: 'MaterialIcons'),
      color: Color(data['color'] as int),
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
      ),
    );
  }
}

// Default categories
class DefaultCategories {
  static List<Category> get expenseCategories => [
        Category(
          id: 'food',
          name: 'Food & Dining',
          icon: Icons.restaurant,
          color: Colors.orange,
          type: TransactionType.expense,
        ),
        Category(
          id: 'transport',
          name: 'Transportation',
          icon: Icons.directions_car,
          color: Colors.blue,
          type: TransactionType.expense,
        ),
        Category(
          id: 'shopping',
          name: 'Shopping',
          icon: Icons.shopping_bag,
          color: Colors.pink,
          type: TransactionType.expense,
        ),
        Category(
          id: 'entertainment',
          name: 'Entertainment',
          icon: Icons.movie,
          color: Colors.purple,
          type: TransactionType.expense,
        ),
        Category(
          id: 'bills',
          name: 'Bills & Utilities',
          icon: Icons.receipt_long,
          color: Colors.red,
          type: TransactionType.expense,
        ),
        Category(
          id: 'health',
          name: 'Health & Fitness',
          icon: Icons.fitness_center,
          color: Colors.green,
          type: TransactionType.expense,
        ),
        Category(
          id: 'education',
          name: 'Education',
          icon: Icons.school,
          color: Colors.indigo,
          type: TransactionType.expense,
        ),
        Category(
          id: 'transfer',
          name: 'Transfer',
          icon: Icons.swap_horiz,
          color: Colors.green,
          type: TransactionType.expense,
        ),
        Category(
          id: 'other_expense',
          name: 'Other',
          icon: Icons.more_horiz,
          color: Colors.grey,
          type: TransactionType.expense,
        ),
      ];

  static List<Category> get incomeCategories => [
        Category(
          id: 'salary',
          name: 'Salary',
          icon: Icons.work,
          color: Colors.teal,
          type: TransactionType.income,
        ),
        Category(
          id: 'business',
          name: 'Business',
          icon: Icons.business,
          color: Colors.cyan,
          type: TransactionType.income,
        ),
        Category(
          id: 'investment',
          name: 'Investment',
          icon: Icons.trending_up,
          color: Colors.lightGreen,
          type: TransactionType.income,
        ),
        Category(
          id: 'gift',
          name: 'Gift',
          icon: Icons.card_giftcard,
          color: Colors.amber,
          type: TransactionType.income,
        ),
        Category(
          id: 'transfer',
          name: 'Transfer',
          icon: Icons.swap_horiz,
          color: Colors.green,
          type: TransactionType.income,
        ),
        Category(
          id: 'other_income',
          name: 'Other',
          icon: Icons.more_horiz,
          color: Colors.grey,
          type: TransactionType.income,
        ),
      ];

  static List<Category> get allCategories => [
        ...expenseCategories,
        ...incomeCategories,
      ];
}
