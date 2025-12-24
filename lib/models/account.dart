class Account {
  final String id;
  final String name;
  final double balance;
  final String currency;
  final AccountType type;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    required this.balance,
    this.currency = 'USD',
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'currency': currency,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'USD',
      type: AccountType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Account copyWith({
    String? id,
    String? name,
    double? balance,
    String? currency,
    AccountType? type,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'currency': currency,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Account.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Account(
      id: doc.id,
      name: data['name'] as String,
      balance: (data['balance'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'USD',
      type: AccountType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
      ),
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum AccountType {
  checking,
  savings,
  credit,
  investment,
}
