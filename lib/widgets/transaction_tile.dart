import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart' as models;
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const TransactionTile({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final category = appState.getCategoryById(transaction.category);
    final isIncome = transaction.type == TransactionType.income;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    // derive icon and color if category is missing
    IconData icon = category?.icon ?? Icons.help_outline;
    Color iconColor = category?.color ?? Colors.grey;

    if (category == null) {
      final title = transaction.title.toLowerCase();
      if (title.contains('sent') || title.contains('transfer') || title.contains('to')) {
        icon = Icons.swap_horiz;
        iconColor = Colors.green;
      } else if (title.contains('received') || title.contains('from')) {
        icon = Icons.arrow_downward;
        iconColor = Colors.blue;
      } else if (title.contains('shopping') || title.contains('amazon')) {
        icon = Icons.shopping_bag;
        iconColor = Colors.pink;
      } else if (title.contains('food') || title.contains('restaurant')) {
        icon = Icons.restaurant;
        iconColor = Colors.orange;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, h:mm a').format(transaction.date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncome ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
            style: TextStyle(
              color: isIncome ? const Color(0xFF00E676) : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
