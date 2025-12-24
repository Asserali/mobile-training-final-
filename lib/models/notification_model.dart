import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final String category;
  final Map<String, dynamic>? metadata;

  NotificationItem({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    required this.category,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'icon': icon.codePoint,
      'iconColor': iconColor.value,
      'title': title,
      'message': message,
      'time': time.toIso8601String(),
      'isRead': isRead,
      'category': category,
      'metadata': metadata,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as String,
      icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
      iconColor: Color(map['iconColor'] as int),
      title: map['title'] as String,
      message: map['message'] as String,
      time: DateTime.parse(map['time'] as String),
      isRead: map['isRead'] as bool? ?? false,
      category: map['category'] as String,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}
