import 'package:flutter_riverpod/flutter_riverpod.dart';

// 深度链接参数模型
class AddPageParams {
  final String? description;
  final String? date;
  final int? fromAccountId;
  final int? toAccountId;
  final double? amount;

  const AddPageParams({
    this.description,
    this.date,
    this.fromAccountId,
    this.toAccountId,
    this.amount,
  });

  factory AddPageParams.fromMap(Map<String, String> params) {
    return AddPageParams(
      description: params['description'],
      date: params['date'],
      fromAccountId: int.tryParse(params['fromAccountId'] ?? ''),
      toAccountId: int.tryParse(params['toAccountId'] ?? ''),
      amount: double.tryParse(params['amount'] ?? ''),
    );
  }

  bool get isEmpty =>
      description == null &&
      date == null &&
      fromAccountId == null &&
      toAccountId == null &&
      amount == null;

  @override
  String toString() {
    return 'AddPageParams(description: $description, date: $date, fromAccountId: $fromAccountId, toAccountId: $toAccountId, amount: $amount)';
  }
}

// Provider来存储添加页面的参数
final addPageParamsProvider = StateProvider<AddPageParams?>((ref) => null);
