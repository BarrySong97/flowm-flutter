import '../db/tables/account_table.dart';

/// 账户交易验证级别
enum TransactionValidationLevel {
  /// 正常交易，无需特殊提示
  normal('正常'),
  /// 不常见但合理的交易，建议用户确认
  uncommon('不常见'),
  /// 异常交易，建议用户检查或阻止
  abnormal('异常');

  const TransactionValidationLevel(this.displayName);
  final String displayName;
}

/// 账户余额变化信息
class AccountBalanceChange {
  /// 余额变化方向：1表示增加，-1表示减少，0表示无变化
  final int direction;
  /// 显示给用户的符号
  final String symbol;
  /// 变化说明
  final String description;

  const AccountBalanceChange({
    required this.direction,
    required this.symbol,
    required this.description,
  });

  /// 是否为增加
  bool get isIncrease => direction > 0;
  /// 是否为减少
  bool get isDecrease => direction < 0;
}

/// 交易验证结果
class TransactionValidationResult {
  /// 验证级别
  final TransactionValidationLevel level;
  /// 从账户余额变化
  final AccountBalanceChange fromAccountChange;
  /// 到账户余额变化
  final AccountBalanceChange toAccountChange;
  /// 交易类型描述
  final String transactionDescription;
  /// 给用户的提示信息
  final String? warningMessage;

  const TransactionValidationResult({
    required this.level,
    required this.fromAccountChange,
    required this.toAccountChange,
    required this.transactionDescription,
    this.warningMessage,
  });
}

/// 账户交易验证工具类
class AccountTransactionValidator {
  /// 验证账户交易并返回详细信息
  static TransactionValidationResult validateTransaction({
    required AccountType fromAccountType,
    required AccountType toAccountType,
  }) {
    final fromChange = _getAccountBalanceChange(
      fromAccountType, 
      isSource: true, 
      counterpartType: toAccountType,
    );
    final toChange = _getAccountBalanceChange(
      toAccountType, 
      isSource: false, 
      counterpartType: fromAccountType,
    );
    
    final validationInfo = _getTransactionValidationInfo(fromAccountType, toAccountType);
    
    return TransactionValidationResult(
      level: validationInfo.level,
      fromAccountChange: fromChange,
      toAccountChange: toChange,
      transactionDescription: validationInfo.description,
      warningMessage: validationInfo.warningMessage,
    );
  }

  /// 获取账户余额变化信息
  static AccountBalanceChange _getAccountBalanceChange(
    AccountType accountType, {
    required bool isSource,
    AccountType? counterpartType,
  }) {
    if (isSource) {
      // 作为资金来源（从账户）
      switch (accountType) {
        case AccountType.INCOME:
          // 收入账户特殊处理：用户理解层面应该显示 '+' 号
          return const AccountBalanceChange(
            direction: -1, // 复式记账规则：从账户减少
            symbol: '+',   // 用户理解：获得收入
            description: '获得收入',
          );
        case AccountType.LIABILITY:
          // 负债账户需要根据对手方判断
          if (counterpartType == AccountType.LIABILITY) {
            // 负债→负债：债务转移，该债务减少
            return const AccountBalanceChange(
              direction: -1, // 复式记账规则：从账户减少
              symbol: '-',   // 用户理解：该债务减少
              description: '债务转移',
            );
          } else {
            // 负债→其他：借款使用，债务增加
            return const AccountBalanceChange(
              direction: -1, // 复式记账规则：从账户减少
              symbol: '+',   // 用户理解：债务增加
              description: '借款使用',
            );
          }
        default:
          // 其他账户：从账户金额减少，显示 '-' 号
          return const AccountBalanceChange(
            direction: -1,
            symbol: '-',
            description: '从账户减少',
          );
      }
    } else {
      // 作为资金去向（到账户）- 复式记账规则：到账户金额一定增加  
      switch (accountType) {
        case AccountType.INCOME:
          // 收入账户作为到账户：收入冲减，显示 '-' 号
          return const AccountBalanceChange(
            direction: 1,  // 复式记账规则：到账户增加
            symbol: '-',   // 用户理解：收入减少
            description: '收入减少',
          );
        case AccountType.LIABILITY:
          // 负债账户需要根据对手方判断
          if (counterpartType == AccountType.LIABILITY) {
            // 负债→负债：债务转移，该债务增加
            return const AccountBalanceChange(
              direction: 1,  // 复式记账规则：到账户增加
              symbol: '+',   // 用户理解：该债务增加
              description: '承接债务',
            );
          } else {
            // 其他→负债：偿还债务，债务减少
            return const AccountBalanceChange(
              direction: 1,  // 复式记账规则：到账户增加
              symbol: '-',   // 用户理解：债务减少
              description: '偿还债务',
            );
          }
        default:
          // 其他账户：到账户增加，显示 '+' 号
          return const AccountBalanceChange(
            direction: 1,
            symbol: '+',
            description: '到账户增加',
          );
      }
    }
  }

  /// 获取交易验证信息
  static _TransactionValidationInfo _getTransactionValidationInfo(
    AccountType fromType,
    AccountType toType,
  ) {
    // 正常交易场景
    final normalTransactions = {
      // 资产相关的常见交易
      (AccountType.ASSET, AccountType.ASSET): _TransactionValidationInfo(
        level: TransactionValidationLevel.normal,
        description: '资产转移',
      ),
      (AccountType.ASSET, AccountType.LIABILITY): _TransactionValidationInfo(
        level: TransactionValidationLevel.normal,
        description: '偿还债务',
      ),
      (AccountType.ASSET, AccountType.EXPENSE): _TransactionValidationInfo(
        level: TransactionValidationLevel.normal,
        description: '日常支出',
      ),
      
      // 负债相关的常见交易
      (AccountType.LIABILITY, AccountType.ASSET): _TransactionValidationInfo(
        level: TransactionValidationLevel.normal,
        description: '借款入账',
      ),
      (AccountType.LIABILITY, AccountType.EXPENSE): _TransactionValidationInfo(
        level: TransactionValidationLevel.normal,
        description: '借款消费',
      ),
      
      // 收入相关的常见交易
      (AccountType.INCOME, AccountType.ASSET): _TransactionValidationInfo(
        level: TransactionValidationLevel.normal,
        description: '收入入账',
      ),
    };

    // 不常见但合理的交易
    final uncommonTransactions = {
      (AccountType.ASSET, AccountType.EQUITY): _TransactionValidationInfo(
        level: TransactionValidationLevel.uncommon,
        description: '投资增资',
        warningMessage: '这是一笔投资或增资交易，请确认金额和账户是否正确',
      ),
      (AccountType.EQUITY, AccountType.ASSET): _TransactionValidationInfo(
        level: TransactionValidationLevel.uncommon,
        description: '提取投资',
        warningMessage: '这是一笔投资提取交易，请确认金额和账户是否正确',
      ),
      (AccountType.LIABILITY, AccountType.LIABILITY): _TransactionValidationInfo(
        level: TransactionValidationLevel.uncommon,
        description: '债务转移',
        warningMessage: '这是一笔债务转移交易，请确认是否为以债还债',
      ),
      (AccountType.INCOME, AccountType.LIABILITY): _TransactionValidationInfo(
        level: TransactionValidationLevel.uncommon,
        description: '收入还债',
        warningMessage: '收入直接用于还债，请确认是否正确',
      ),
      (AccountType.INCOME, AccountType.EQUITY): _TransactionValidationInfo(
        level: TransactionValidationLevel.uncommon,
        description: '收入转投资',
        warningMessage: '收入直接转为投资，请确认是否正确',
      ),
      (AccountType.EXPENSE, AccountType.ASSET): _TransactionValidationInfo(
        level: TransactionValidationLevel.uncommon,
        description: '费用退款',
        warningMessage: '这是一笔费用退款，请确认退款金额和账户',
      ),
    };

    // 异常交易场景
    final abnormalTransactions = {
      (AccountType.ASSET, AccountType.INCOME): _TransactionValidationInfo(
        level: TransactionValidationLevel.abnormal,
        description: '异常交易',
        warningMessage: '资产转入收入账户通常不合理，请检查账户选择是否正确',
      ),
      (AccountType.LIABILITY, AccountType.INCOME): _TransactionValidationInfo(
        level: TransactionValidationLevel.abnormal,
        description: '异常交易',
        warningMessage: '债务转入收入账户不合理，请检查账户选择是否正确',
      ),
      (AccountType.EQUITY, AccountType.LIABILITY): _TransactionValidationInfo(
        level: TransactionValidationLevel.abnormal,
        description: '异常交易',
        warningMessage: '权益转入债务账户通常不合理，请检查账户选择是否正确',
      ),
      (AccountType.EQUITY, AccountType.EQUITY): _TransactionValidationInfo(
        level: TransactionValidationLevel.abnormal,
        description: '异常交易',
        warningMessage: '权益账户内部转移通常不适用于个人记账，请检查账户选择',
      ),
      (AccountType.EQUITY, AccountType.INCOME): _TransactionValidationInfo(
        level: TransactionValidationLevel.abnormal,
        description: '异常交易',
        warningMessage: '权益转入收入账户不合理，请检查账户选择是否正确',
      ),
      (AccountType.EQUITY, AccountType.EXPENSE): _TransactionValidationInfo(
        level: TransactionValidationLevel.abnormal,
        description: '异常交易',
        warningMessage: '权益直接转入费用账户不合理，请检查账户选择是否正确',
      ),
      (AccountType.INCOME, AccountType.INCOME): _TransactionValidationInfo(
        level: TransactionValidationLevel.abnormal,
        description: '异常交易',
        warningMessage: '收入账户内部转移通常不适用于个人记账，建议重新选择账户',
      ),
      (AccountType.INCOME, AccountType.EXPENSE): _TransactionValidationInfo(
        level: TransactionValidationLevel.abnormal,
        description: '异常交易',
        warningMessage: '收入直接转入费用账户不合理，请检查账户选择是否正确',
      ),
      (AccountType.EXPENSE, AccountType.LIABILITY): _TransactionValidationInfo(
        level: TransactionValidationLevel.abnormal,
        description: '异常交易',
        warningMessage: '费用转入债务账户不合理，请检查账户选择是否正确',
      ),
      (AccountType.EXPENSE, AccountType.EQUITY): _TransactionValidationInfo(
        level: TransactionValidationLevel.abnormal,
        description: '异常交易',
        warningMessage: '费用转入权益账户不合理，请检查账户选择是否正确',
      ),
      (AccountType.EXPENSE, AccountType.INCOME): _TransactionValidationInfo(
        level: TransactionValidationLevel.abnormal,
        description: '异常交易',
        warningMessage: '费用转入收入账户不合理，请检查账户选择是否正确',
      ),
      (AccountType.EXPENSE, AccountType.EXPENSE): _TransactionValidationInfo(
        level: TransactionValidationLevel.abnormal,
        description: '异常交易',
        warningMessage: '费用账户内部转移通常不适用于个人记账，建议重新选择账户',
      ),
    };

    final key = (fromType, toType);
    
    if (normalTransactions.containsKey(key)) {
      return normalTransactions[key]!;
    } else if (uncommonTransactions.containsKey(key)) {
      return uncommonTransactions[key]!;
    } else if (abnormalTransactions.containsKey(key)) {
      return abnormalTransactions[key]!;
    }

    // 默认返回异常情况
    return _TransactionValidationInfo(
      level: TransactionValidationLevel.abnormal,
      description: '未知交易类型',
      warningMessage: '这种账户组合不常见，请检查账户选择是否正确',
    );
  }

  /// 检查交易是否应该被阻止
  static bool shouldBlockTransaction(AccountType fromType, AccountType toType) {
    final result = validateTransaction(
      fromAccountType: fromType,
      toAccountType: toType,
    );
    return result.level == TransactionValidationLevel.abnormal;
  }

  /// 获取账户显示的加减号
  static String getAccountSymbol({
    required AccountType accountType,
    required bool isFromAccount,
    AccountType? counterpartAccountType,
  }) {
    final change = _getAccountBalanceChange(
      accountType, 
      isSource: isFromAccount,
      counterpartType: counterpartAccountType,
    );
    return change.symbol;
  }

  /// 获取账户变化描述
  static String getAccountChangeDescription({
    required AccountType accountType,
    required bool isFromAccount,
    AccountType? counterpartAccountType,
  }) {
    final change = _getAccountBalanceChange(
      accountType, 
      isSource: isFromAccount,
      counterpartType: counterpartAccountType,
    );
    return change.description;
  }
}

/// 内部使用的交易验证信息类
class _TransactionValidationInfo {
  final TransactionValidationLevel level;
  final String description;
  final String? warningMessage;

  const _TransactionValidationInfo({
    required this.level,
    required this.description,
    this.warningMessage,
  });
}