import 'package:flutter/material.dart';

enum CardType {
  debit,
  credit,
  prepaid,
}

enum CardNetwork {
  visa,
  mastercard,
  meeza, // Egyptian national payment network
}

enum CardStatus {
  active,
  frozen,
  blocked,
  expired,
}

class BankCard {
  final String id;
  final String accountId;
  final String cardNumber; // Last 4 digits only for security
  final String cardHolderName;
  final CardType type;
  final CardNetwork network;
  final DateTime expiryDate;
  final CardStatus status;
  final double dailyLimit;
  final double monthlyLimit;
  final double currentDailySpent;
  final double currentMonthlySpent;
  final bool isVirtual;
  final Color cardColor;
  final bool isDefault;

  BankCard({
    required this.id,
    required this.accountId,
    required this.cardNumber,
    required this.cardHolderName,
    required this.type,
    required this.network,
    required this.expiryDate,
    this.status = CardStatus.active,
    this.dailyLimit = 10000.0,
    this.monthlyLimit = 50000.0,
    this.currentDailySpent = 0.0,
    this.currentMonthlySpent = 0.0,
    this.isVirtual = false,
    this.cardColor = Colors.blue,
    this.isDefault = false,
  });

  String get maskedCardNumber {
    if (cardNumber.length <= 4) return '**** **** **** $cardNumber';
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  String get expiryDateFormatted {
    return '${expiryDate.month.toString().padLeft(2, '0')}/${expiryDate.year.toString().substring(2)}';
  }

  bool get isExpired {
    return DateTime.now().isAfter(expiryDate);
  }

  double get dailyLimitRemaining {
    return dailyLimit - currentDailySpent;
  }

  double get monthlyLimitRemaining {
    return monthlyLimit - currentMonthlySpent;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'type': type.toString().split('.').last,
      'network': network.toString().split('.').last,
      'expiryDate': expiryDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'dailyLimit': dailyLimit,
      'monthlyLimit': monthlyLimit,
      'currentDailySpent': currentDailySpent,
      'currentMonthlySpent': currentMonthlySpent,
      'isVirtual': isVirtual,
      'cardColor': cardColor.value,
      'isDefault': isDefault,
    };
  }

  factory BankCard.fromMap(Map<String, dynamic> map) {
    return BankCard(
      id: map['id'] as String,
      accountId: map['accountId'] as String,
      cardNumber: map['cardNumber'] as String,
      cardHolderName: map['cardHolderName'] as String,
      type: CardType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      network: CardNetwork.values.firstWhere(
        (e) => e.toString().split('.').last == map['network'],
      ),
      expiryDate: DateTime.parse(map['expiryDate'] as String),
      status: CardStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
      ),
      dailyLimit: (map['dailyLimit'] as num).toDouble(),
      monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      currentDailySpent: (map['currentDailySpent'] as num).toDouble(),
      currentMonthlySpent: (map['currentMonthlySpent'] as num).toDouble(),
      isVirtual: map['isVirtual'] as bool,
      cardColor: Color(map['cardColor'] as int),
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  BankCard copyWith({
    String? id,
    String? accountId,
    String? cardNumber,
    String? cardHolderName,
    CardType? type,
    CardNetwork? network,
    DateTime? expiryDate,
    CardStatus? status,
    double? dailyLimit,
    double? monthlyLimit,
    double? currentDailySpent,
    double? currentMonthlySpent,
    bool? isVirtual,
    Color? cardColor,
    bool? isDefault,
  }) {
    return BankCard(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      type: type ?? this.type,
      network: network ?? this.network,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currentDailySpent: currentDailySpent ?? this.currentDailySpent,
      currentMonthlySpent: currentMonthlySpent ?? this.currentMonthlySpent,
      isVirtual: isVirtual ?? this.isVirtual,
      cardColor: cardColor ?? this.cardColor,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  // Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'accountId': accountId,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'type': type.toString().split('.').last,
      'network': network.toString().split('.').last,
      'expiryDate': expiryDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'dailyLimit': dailyLimit,
      'monthlyLimit': monthlyLimit,
      'currentDailySpent': currentDailySpent,
      'currentMonthlySpent': currentMonthlySpent,
      'isVirtual': isVirtual,
      'cardColor': cardColor.value,
      'isDefault': isDefault,
    };
  }

  factory BankCard.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BankCard(
      id: doc.id,
      accountId: data['accountId'] as String,
      cardNumber: data['cardNumber'] as String,
      cardHolderName: data['cardHolderName'] as String,
      type: CardType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
      ),
      network: CardNetwork.values.firstWhere(
        (e) => e.toString().split('.').last == data['network'],
      ),
      expiryDate: DateTime.parse(data['expiryDate'] as String),
      status: CardStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
      ),
      dailyLimit: (data['dailyLimit'] as num).toDouble(),
      monthlyLimit: (data['monthlyLimit'] as num).toDouble(),
      currentDailySpent: (data['currentDailySpent'] as num).toDouble(),
      currentMonthlySpent: (data['currentMonthlySpent'] as num).toDouble(),
      isVirtual: data['isVirtual'] as bool,
      cardColor: Color(data['cardColor'] as int),
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }
}

// Type alias for backward compatibility
typedef CardModel = BankCard;
