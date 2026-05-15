import 'package:flowm/db/app_database.dart' show Account;

class FinanceFlow {
  const FinanceFlow({
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.transactionDate,
    this.description,
  });

  final Account fromAccount;
  final Account toAccount;
  final double amount;
  final DateTime transactionDate;
  final String? description;
}

class FinanceFlowData<Node, Link> {
  const FinanceFlowData({
    required this.nodes,
    required this.links,
  });

  final List<Node> nodes;
  final List<Link> links;
}
