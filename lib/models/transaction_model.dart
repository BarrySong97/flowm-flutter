import 'package:flutter/material.dart';

class Transaction {
  final String title;
  final String subtitle;
  final String amount;
  final String type;
  final Color statusColor;
  final bool isExpense;

  Transaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    required this.statusColor,
    required this.isExpense,
  });

  static List<Transaction> getSampleData() {
    return [
      Transaction(
        title: 'Transaction 1',
        subtitle: '微信 -> 饮食',
        amount: '¥6272',
        type: '支出',
        statusColor: const Color(0xFF34C759),
        isExpense: true,
      ),
      Transaction(
        title: 'Transaction 2',
        subtitle: '支付宝 -> 购物',
        amount: '¥1580',
        type: '支出',
        statusColor: const Color(0xFF34C759),
        isExpense: true,
      ),
      Transaction(
        title: 'Transaction 3',
        subtitle: '工资收入',
        amount: '¥15000',
        type: '收入',
        statusColor: const Color(0xFF007AFF),
        isExpense: false,
      ),
      Transaction(
        title: 'Transaction 4',
        subtitle: '微信 -> 交通',
        amount: '¥35',
        type: '支出',
        statusColor: const Color(0xFF34C759),
        isExpense: true,
      ),
      Transaction(
        title: 'Transaction 5',
        subtitle: '支付宝 -> 娱乐',
        amount: '¥288',
        type: '支出',
        statusColor: const Color(0xFF34C759),
        isExpense: true,
      ),
      Transaction(
        title: 'Transaction 6',
        subtitle: '投资收益',
        amount: '¥2500',
        type: '收入',
        statusColor: const Color(0xFF007AFF),
        isExpense: false,
      ),
      Transaction(
        title: 'Transaction 7',
        subtitle: '微信 -> 医疗',
        amount: '¥456',
        type: '支出',
        statusColor: const Color(0xFF34C759),
        isExpense: true,
      ),
      Transaction(
        title: 'Transaction 8',
        subtitle: '红包收入',
        amount: '¥200',
        type: '收入',
        statusColor: const Color(0xFF007AFF),
        isExpense: false,
      ),
      Transaction(
        title: 'Transaction 9',
        subtitle: '支付宝 -> 教育',
        amount: '¥3999',
        type: '支出',
        statusColor: const Color(0xFF34C759),
        isExpense: true,
      ),
      Transaction(
        title: 'Transaction 10',
        subtitle: '微信 -> 住房',
        amount: '¥2800',
        type: '支出',
        statusColor: const Color(0xFF34C759),
        isExpense: true,
      ),
    ];
  }
}
