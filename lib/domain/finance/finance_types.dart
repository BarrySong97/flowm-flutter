import 'package:flowm/db/tables/account_table.dart' show AccountType;

enum CashflowType { expense, income }

enum NetWorthType { asset, liability }

class TimeRangeSpec {
  const TimeRangeSpec({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;
}

extension CashflowTypeAccountType on CashflowType {
  AccountType get accountType {
    switch (this) {
      case CashflowType.expense:
        return AccountType.EXPENSE;
      case CashflowType.income:
        return AccountType.INCOME;
    }
  }

  bool get usesNegativePostings => this == CashflowType.income;
}

extension NetWorthTypeAccountType on NetWorthType {
  AccountType get accountType {
    switch (this) {
      case NetWorthType.asset:
        return AccountType.ASSET;
      case NetWorthType.liability:
        return AccountType.LIABILITY;
    }
  }
}
