// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _parentAccountIdMeta =
      const VerificationMeta('parentAccountId');
  @override
  late final GeneratedColumn<int> parentAccountId = GeneratedColumn<int>(
      'parent_account_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES accounts (account_id)'));
  static const VerificationMeta _accountNameMeta =
      const VerificationMeta('accountName');
  @override
  late final GeneratedColumn<String> accountName = GeneratedColumn<String>(
      'account_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fullPathMeta =
      const VerificationMeta('fullPath');
  @override
  late final GeneratedColumn<String> fullPath = GeneratedColumn<String>(
      'full_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<AccountType, String> accountType =
      GeneratedColumn<String>('account_type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<AccountType>($AccountsTable.$converteraccountType);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        accountId,
        parentAccountId,
        accountName,
        fullPath,
        accountType,
        isActive,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    if (data.containsKey('parent_account_id')) {
      context.handle(
          _parentAccountIdMeta,
          parentAccountId.isAcceptableOrUnknown(
              data['parent_account_id']!, _parentAccountIdMeta));
    }
    if (data.containsKey('account_name')) {
      context.handle(
          _accountNameMeta,
          accountName.isAcceptableOrUnknown(
              data['account_name']!, _accountNameMeta));
    } else if (isInserting) {
      context.missing(_accountNameMeta);
    }
    if (data.containsKey('full_path')) {
      context.handle(_fullPathMeta,
          fullPath.isAcceptableOrUnknown(data['full_path']!, _fullPathMeta));
    } else if (isInserting) {
      context.missing(_fullPathMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
      parentAccountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parent_account_id']),
      accountName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_name'])!,
      fullPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_path'])!,
      accountType: $AccountsTable.$converteraccountType.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_type'])!),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountType, String, String> $converteraccountType =
      const EnumNameConverter<AccountType>(AccountType.values);
}

class Account extends DataClass implements Insertable<Account> {
  final int accountId;
  final int? parentAccountId;
  final String accountName;
  final String fullPath;
  final AccountType accountType;
  final bool isActive;
  final DateTime createdAt;
  const Account(
      {required this.accountId,
      this.parentAccountId,
      required this.accountName,
      required this.fullPath,
      required this.accountType,
      required this.isActive,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<int>(accountId);
    if (!nullToAbsent || parentAccountId != null) {
      map['parent_account_id'] = Variable<int>(parentAccountId);
    }
    map['account_name'] = Variable<String>(accountName);
    map['full_path'] = Variable<String>(fullPath);
    {
      map['account_type'] = Variable<String>(
          $AccountsTable.$converteraccountType.toSql(accountType));
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      accountId: Value(accountId),
      parentAccountId: parentAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentAccountId),
      accountName: Value(accountName),
      fullPath: Value(fullPath),
      accountType: Value(accountType),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      accountId: serializer.fromJson<int>(json['accountId']),
      parentAccountId: serializer.fromJson<int?>(json['parentAccountId']),
      accountName: serializer.fromJson<String>(json['accountName']),
      fullPath: serializer.fromJson<String>(json['fullPath']),
      accountType: $AccountsTable.$converteraccountType
          .fromJson(serializer.fromJson<String>(json['accountType'])),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<int>(accountId),
      'parentAccountId': serializer.toJson<int?>(parentAccountId),
      'accountName': serializer.toJson<String>(accountName),
      'fullPath': serializer.toJson<String>(fullPath),
      'accountType': serializer.toJson<String>(
          $AccountsTable.$converteraccountType.toJson(accountType)),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Account copyWith(
          {int? accountId,
          Value<int?> parentAccountId = const Value.absent(),
          String? accountName,
          String? fullPath,
          AccountType? accountType,
          bool? isActive,
          DateTime? createdAt}) =>
      Account(
        accountId: accountId ?? this.accountId,
        parentAccountId: parentAccountId.present
            ? parentAccountId.value
            : this.parentAccountId,
        accountName: accountName ?? this.accountName,
        fullPath: fullPath ?? this.fullPath,
        accountType: accountType ?? this.accountType,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      parentAccountId: data.parentAccountId.present
          ? data.parentAccountId.value
          : this.parentAccountId,
      accountName:
          data.accountName.present ? data.accountName.value : this.accountName,
      fullPath: data.fullPath.present ? data.fullPath.value : this.fullPath,
      accountType:
          data.accountType.present ? data.accountType.value : this.accountType,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('accountId: $accountId, ')
          ..write('parentAccountId: $parentAccountId, ')
          ..write('accountName: $accountName, ')
          ..write('fullPath: $fullPath, ')
          ..write('accountType: $accountType, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, parentAccountId, accountName,
      fullPath, accountType, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.accountId == this.accountId &&
          other.parentAccountId == this.parentAccountId &&
          other.accountName == this.accountName &&
          other.fullPath == this.fullPath &&
          other.accountType == this.accountType &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> accountId;
  final Value<int?> parentAccountId;
  final Value<String> accountName;
  final Value<String> fullPath;
  final Value<AccountType> accountType;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  const AccountsCompanion({
    this.accountId = const Value.absent(),
    this.parentAccountId = const Value.absent(),
    this.accountName = const Value.absent(),
    this.fullPath = const Value.absent(),
    this.accountType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.accountId = const Value.absent(),
    this.parentAccountId = const Value.absent(),
    required String accountName,
    required String fullPath,
    required AccountType accountType,
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : accountName = Value(accountName),
        fullPath = Value(fullPath),
        accountType = Value(accountType);
  static Insertable<Account> custom({
    Expression<int>? accountId,
    Expression<int>? parentAccountId,
    Expression<String>? accountName,
    Expression<String>? fullPath,
    Expression<String>? accountType,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (parentAccountId != null) 'parent_account_id': parentAccountId,
      if (accountName != null) 'account_name': accountName,
      if (fullPath != null) 'full_path': fullPath,
      if (accountType != null) 'account_type': accountType,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AccountsCompanion copyWith(
      {Value<int>? accountId,
      Value<int?>? parentAccountId,
      Value<String>? accountName,
      Value<String>? fullPath,
      Value<AccountType>? accountType,
      Value<bool>? isActive,
      Value<DateTime>? createdAt}) {
    return AccountsCompanion(
      accountId: accountId ?? this.accountId,
      parentAccountId: parentAccountId ?? this.parentAccountId,
      accountName: accountName ?? this.accountName,
      fullPath: fullPath ?? this.fullPath,
      accountType: accountType ?? this.accountType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (parentAccountId.present) {
      map['parent_account_id'] = Variable<int>(parentAccountId.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String>(accountName.value);
    }
    if (fullPath.present) {
      map['full_path'] = Variable<String>(fullPath.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(
          $AccountsTable.$converteraccountType.toSql(accountType.value));
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('parentAccountId: $parentAccountId, ')
          ..write('accountName: $accountName, ')
          ..write('fullPath: $fullPath, ')
          ..write('accountType: $accountType, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
      'transaction_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _transactionDateMeta =
      const VerificationMeta('transactionDate');
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>('transaction_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isRecurringMeta =
      const VerificationMeta('isRecurring');
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
      'is_recurring', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_recurring" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [transactionId, transactionDate, description, isRecurring, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
          _transactionDateMeta,
          transactionDate.isAcceptableOrUnknown(
              data['transaction_date']!, _transactionDateMeta));
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
          _isRecurringMeta,
          isRecurring.isAcceptableOrUnknown(
              data['is_recurring']!, _isRecurringMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transactionId};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}transaction_id'])!,
      transactionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}transaction_date'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      isRecurring: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_recurring'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int transactionId;
  final DateTime transactionDate;
  final String? description;
  final bool isRecurring;
  final DateTime createdAt;
  const Transaction(
      {required this.transactionId,
      required this.transactionDate,
      this.description,
      required this.isRecurring,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transaction_id'] = Variable<int>(transactionId);
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_recurring'] = Variable<bool>(isRecurring);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      transactionId: Value(transactionId),
      transactionDate: Value(transactionDate),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isRecurring: Value(isRecurring),
      createdAt: Value(createdAt),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      transactionId: serializer.fromJson<int>(json['transactionId']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
      description: serializer.fromJson<String?>(json['description']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transactionId': serializer.toJson<int>(transactionId),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
      'description': serializer.toJson<String?>(description),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Transaction copyWith(
          {int? transactionId,
          DateTime? transactionDate,
          Value<String?> description = const Value.absent(),
          bool? isRecurring,
          DateTime? createdAt}) =>
      Transaction(
        transactionId: transactionId ?? this.transactionId,
        transactionDate: transactionDate ?? this.transactionDate,
        description: description.present ? description.value : this.description,
        isRecurring: isRecurring ?? this.isRecurring,
        createdAt: createdAt ?? this.createdAt,
      );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      description:
          data.description.present ? data.description.value : this.description,
      isRecurring:
          data.isRecurring.present ? data.isRecurring.value : this.isRecurring,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('transactionId: $transactionId, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('description: $description, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      transactionId, transactionDate, description, isRecurring, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.transactionId == this.transactionId &&
          other.transactionDate == this.transactionDate &&
          other.description == this.description &&
          other.isRecurring == this.isRecurring &&
          other.createdAt == this.createdAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> transactionId;
  final Value<DateTime> transactionDate;
  final Value<String?> description;
  final Value<bool> isRecurring;
  final Value<DateTime> createdAt;
  const TransactionsCompanion({
    this.transactionId = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.description = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.transactionId = const Value.absent(),
    required DateTime transactionDate,
    this.description = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : transactionDate = Value(transactionDate);
  static Insertable<Transaction> custom({
    Expression<int>? transactionId,
    Expression<DateTime>? transactionDate,
    Expression<String>? description,
    Expression<bool>? isRecurring,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (transactionId != null) 'transaction_id': transactionId,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (description != null) 'description': description,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TransactionsCompanion copyWith(
      {Value<int>? transactionId,
      Value<DateTime>? transactionDate,
      Value<String?>? description,
      Value<bool>? isRecurring,
      Value<DateTime>? createdAt}) {
    return TransactionsCompanion(
      transactionId: transactionId ?? this.transactionId,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('transactionId: $transactionId, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('description: $description, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PostingsTable extends Postings with TableInfo<$PostingsTable, Posting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _postingIdMeta =
      const VerificationMeta('postingId');
  @override
  late final GeneratedColumn<int> postingId = GeneratedColumn<int>(
      'posting_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
      'transaction_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES transactions (transaction_id)'));
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES accounts (account_id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _postingTagMeta =
      const VerificationMeta('postingTag');
  @override
  late final GeneratedColumn<String> postingTag = GeneratedColumn<String>(
      'posting_tag', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [postingId, transactionId, accountId, amount, postingTag, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'postings';
  @override
  VerificationContext validateIntegrity(Insertable<Posting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('posting_id')) {
      context.handle(_postingIdMeta,
          postingId.isAcceptableOrUnknown(data['posting_id']!, _postingIdMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('posting_tag')) {
      context.handle(
          _postingTagMeta,
          postingTag.isAcceptableOrUnknown(
              data['posting_tag']!, _postingTagMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {postingId};
  @override
  Posting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Posting(
      postingId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}posting_id'])!,
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}transaction_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      postingTag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}posting_tag']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PostingsTable createAlias(String alias) {
    return $PostingsTable(attachedDatabase, alias);
  }
}

class Posting extends DataClass implements Insertable<Posting> {
  final int postingId;
  final int transactionId;
  final int accountId;
  final double amount;
  final String? postingTag;
  final DateTime createdAt;
  const Posting(
      {required this.postingId,
      required this.transactionId,
      required this.accountId,
      required this.amount,
      this.postingTag,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['posting_id'] = Variable<int>(postingId);
    map['transaction_id'] = Variable<int>(transactionId);
    map['account_id'] = Variable<int>(accountId);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || postingTag != null) {
      map['posting_tag'] = Variable<String>(postingTag);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PostingsCompanion toCompanion(bool nullToAbsent) {
    return PostingsCompanion(
      postingId: Value(postingId),
      transactionId: Value(transactionId),
      accountId: Value(accountId),
      amount: Value(amount),
      postingTag: postingTag == null && nullToAbsent
          ? const Value.absent()
          : Value(postingTag),
      createdAt: Value(createdAt),
    );
  }

  factory Posting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Posting(
      postingId: serializer.fromJson<int>(json['postingId']),
      transactionId: serializer.fromJson<int>(json['transactionId']),
      accountId: serializer.fromJson<int>(json['accountId']),
      amount: serializer.fromJson<double>(json['amount']),
      postingTag: serializer.fromJson<String?>(json['postingTag']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'postingId': serializer.toJson<int>(postingId),
      'transactionId': serializer.toJson<int>(transactionId),
      'accountId': serializer.toJson<int>(accountId),
      'amount': serializer.toJson<double>(amount),
      'postingTag': serializer.toJson<String?>(postingTag),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Posting copyWith(
          {int? postingId,
          int? transactionId,
          int? accountId,
          double? amount,
          Value<String?> postingTag = const Value.absent(),
          DateTime? createdAt}) =>
      Posting(
        postingId: postingId ?? this.postingId,
        transactionId: transactionId ?? this.transactionId,
        accountId: accountId ?? this.accountId,
        amount: amount ?? this.amount,
        postingTag: postingTag.present ? postingTag.value : this.postingTag,
        createdAt: createdAt ?? this.createdAt,
      );
  Posting copyWithCompanion(PostingsCompanion data) {
    return Posting(
      postingId: data.postingId.present ? data.postingId.value : this.postingId,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      amount: data.amount.present ? data.amount.value : this.amount,
      postingTag:
          data.postingTag.present ? data.postingTag.value : this.postingTag,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Posting(')
          ..write('postingId: $postingId, ')
          ..write('transactionId: $transactionId, ')
          ..write('accountId: $accountId, ')
          ..write('amount: $amount, ')
          ..write('postingTag: $postingTag, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      postingId, transactionId, accountId, amount, postingTag, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Posting &&
          other.postingId == this.postingId &&
          other.transactionId == this.transactionId &&
          other.accountId == this.accountId &&
          other.amount == this.amount &&
          other.postingTag == this.postingTag &&
          other.createdAt == this.createdAt);
}

class PostingsCompanion extends UpdateCompanion<Posting> {
  final Value<int> postingId;
  final Value<int> transactionId;
  final Value<int> accountId;
  final Value<double> amount;
  final Value<String?> postingTag;
  final Value<DateTime> createdAt;
  const PostingsCompanion({
    this.postingId = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.amount = const Value.absent(),
    this.postingTag = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PostingsCompanion.insert({
    this.postingId = const Value.absent(),
    required int transactionId,
    required int accountId,
    required double amount,
    this.postingTag = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : transactionId = Value(transactionId),
        accountId = Value(accountId),
        amount = Value(amount);
  static Insertable<Posting> custom({
    Expression<int>? postingId,
    Expression<int>? transactionId,
    Expression<int>? accountId,
    Expression<double>? amount,
    Expression<String>? postingTag,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (postingId != null) 'posting_id': postingId,
      if (transactionId != null) 'transaction_id': transactionId,
      if (accountId != null) 'account_id': accountId,
      if (amount != null) 'amount': amount,
      if (postingTag != null) 'posting_tag': postingTag,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PostingsCompanion copyWith(
      {Value<int>? postingId,
      Value<int>? transactionId,
      Value<int>? accountId,
      Value<double>? amount,
      Value<String?>? postingTag,
      Value<DateTime>? createdAt}) {
    return PostingsCompanion(
      postingId: postingId ?? this.postingId,
      transactionId: transactionId ?? this.transactionId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      postingTag: postingTag ?? this.postingTag,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (postingId.present) {
      map['posting_id'] = Variable<int>(postingId.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (postingTag.present) {
      map['posting_tag'] = Variable<String>(postingTag.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostingsCompanion(')
          ..write('postingId: $postingId, ')
          ..write('transactionId: $transactionId, ')
          ..write('accountId: $accountId, ')
          ..write('amount: $amount, ')
          ..write('postingTag: $postingTag, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
      'tag_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tagNameMeta =
      const VerificationMeta('tagName');
  @override
  late final GeneratedColumn<String> tagName = GeneratedColumn<String>(
      'tag_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _displayColorMeta =
      const VerificationMeta('displayColor');
  @override
  late final GeneratedColumn<String> displayColor = GeneratedColumn<String>(
      'display_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [tagId, tagName, displayColor, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(Insertable<Tag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    }
    if (data.containsKey('tag_name')) {
      context.handle(_tagNameMeta,
          tagName.isAcceptableOrUnknown(data['tag_name']!, _tagNameMeta));
    } else if (isInserting) {
      context.missing(_tagNameMeta);
    }
    if (data.containsKey('display_color')) {
      context.handle(
          _displayColorMeta,
          displayColor.isAcceptableOrUnknown(
              data['display_color']!, _displayColorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tagId};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tag_id'])!,
      tagName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag_name'])!,
      displayColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_color']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int tagId;
  final String tagName;
  final String? displayColor;
  final DateTime createdAt;
  const Tag(
      {required this.tagId,
      required this.tagName,
      this.displayColor,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tag_id'] = Variable<int>(tagId);
    map['tag_name'] = Variable<String>(tagName);
    if (!nullToAbsent || displayColor != null) {
      map['display_color'] = Variable<String>(displayColor);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      tagId: Value(tagId),
      tagName: Value(tagName),
      displayColor: displayColor == null && nullToAbsent
          ? const Value.absent()
          : Value(displayColor),
      createdAt: Value(createdAt),
    );
  }

  factory Tag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      tagId: serializer.fromJson<int>(json['tagId']),
      tagName: serializer.fromJson<String>(json['tagName']),
      displayColor: serializer.fromJson<String?>(json['displayColor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tagId': serializer.toJson<int>(tagId),
      'tagName': serializer.toJson<String>(tagName),
      'displayColor': serializer.toJson<String?>(displayColor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Tag copyWith(
          {int? tagId,
          String? tagName,
          Value<String?> displayColor = const Value.absent(),
          DateTime? createdAt}) =>
      Tag(
        tagId: tagId ?? this.tagId,
        tagName: tagName ?? this.tagName,
        displayColor:
            displayColor.present ? displayColor.value : this.displayColor,
        createdAt: createdAt ?? this.createdAt,
      );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      tagName: data.tagName.present ? data.tagName.value : this.tagName,
      displayColor: data.displayColor.present
          ? data.displayColor.value
          : this.displayColor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('tagId: $tagId, ')
          ..write('tagName: $tagName, ')
          ..write('displayColor: $displayColor, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tagId, tagName, displayColor, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.tagId == this.tagId &&
          other.tagName == this.tagName &&
          other.displayColor == this.displayColor &&
          other.createdAt == this.createdAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> tagId;
  final Value<String> tagName;
  final Value<String?> displayColor;
  final Value<DateTime> createdAt;
  const TagsCompanion({
    this.tagId = const Value.absent(),
    this.tagName = const Value.absent(),
    this.displayColor = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TagsCompanion.insert({
    this.tagId = const Value.absent(),
    required String tagName,
    this.displayColor = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : tagName = Value(tagName);
  static Insertable<Tag> custom({
    Expression<int>? tagId,
    Expression<String>? tagName,
    Expression<String>? displayColor,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (tagId != null) 'tag_id': tagId,
      if (tagName != null) 'tag_name': tagName,
      if (displayColor != null) 'display_color': displayColor,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TagsCompanion copyWith(
      {Value<int>? tagId,
      Value<String>? tagName,
      Value<String?>? displayColor,
      Value<DateTime>? createdAt}) {
    return TagsCompanion(
      tagId: tagId ?? this.tagId,
      tagName: tagName ?? this.tagName,
      displayColor: displayColor ?? this.displayColor,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (tagName.present) {
      map['tag_name'] = Variable<String>(tagName.value);
    }
    if (displayColor.present) {
      map['display_color'] = Variable<String>(displayColor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('tagId: $tagId, ')
          ..write('tagName: $tagName, ')
          ..write('displayColor: $displayColor, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionTagsTable extends TransactionTags
    with TableInfo<$TransactionTagsTable, TransactionTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
      'transaction_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES transactions (transaction_id)'));
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
      'tag_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tags (tag_id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [transactionId, tagId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_tags';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionTag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transactionId, tagId};
  @override
  TransactionTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionTag(
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}transaction_id'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tag_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TransactionTagsTable createAlias(String alias) {
    return $TransactionTagsTable(attachedDatabase, alias);
  }
}

class TransactionTag extends DataClass implements Insertable<TransactionTag> {
  final int transactionId;
  final int tagId;
  final DateTime createdAt;
  const TransactionTag(
      {required this.transactionId,
      required this.tagId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transaction_id'] = Variable<int>(transactionId);
    map['tag_id'] = Variable<int>(tagId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransactionTagsCompanion toCompanion(bool nullToAbsent) {
    return TransactionTagsCompanion(
      transactionId: Value(transactionId),
      tagId: Value(tagId),
      createdAt: Value(createdAt),
    );
  }

  factory TransactionTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionTag(
      transactionId: serializer.fromJson<int>(json['transactionId']),
      tagId: serializer.fromJson<int>(json['tagId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transactionId': serializer.toJson<int>(transactionId),
      'tagId': serializer.toJson<int>(tagId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TransactionTag copyWith(
          {int? transactionId, int? tagId, DateTime? createdAt}) =>
      TransactionTag(
        transactionId: transactionId ?? this.transactionId,
        tagId: tagId ?? this.tagId,
        createdAt: createdAt ?? this.createdAt,
      );
  TransactionTag copyWithCompanion(TransactionTagsCompanion data) {
    return TransactionTag(
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionTag(')
          ..write('transactionId: $transactionId, ')
          ..write('tagId: $tagId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(transactionId, tagId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionTag &&
          other.transactionId == this.transactionId &&
          other.tagId == this.tagId &&
          other.createdAt == this.createdAt);
}

class TransactionTagsCompanion extends UpdateCompanion<TransactionTag> {
  final Value<int> transactionId;
  final Value<int> tagId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TransactionTagsCompanion({
    this.transactionId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionTagsCompanion.insert({
    required int transactionId,
    required int tagId,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : transactionId = Value(transactionId),
        tagId = Value(tagId);
  static Insertable<TransactionTag> custom({
    Expression<int>? transactionId,
    Expression<int>? tagId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (transactionId != null) 'transaction_id': transactionId,
      if (tagId != null) 'tag_id': tagId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionTagsCompanion copyWith(
      {Value<int>? transactionId,
      Value<int>? tagId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TransactionTagsCompanion(
      transactionId: transactionId ?? this.transactionId,
      tagId: tagId ?? this.tagId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionTagsCompanion(')
          ..write('transactionId: $transactionId, ')
          ..write('tagId: $tagId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $PostingsTable postings = $PostingsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $TransactionTagsTable transactionTags =
      $TransactionTagsTable(this);
  late final AccountDao accountDao = AccountDao(this as AppDatabase);
  late final TransactionDao transactionDao =
      TransactionDao(this as AppDatabase);
  late final PostingDao postingDao = PostingDao(this as AppDatabase);
  late final TagDao tagDao = TagDao(this as AppDatabase);
  late final TransactionTagDao transactionTagDao =
      TransactionTagDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [accounts, transactions, postings, tags, transactionTags];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<int> accountId,
  Value<int?> parentAccountId,
  required String accountName,
  required String fullPath,
  required AccountType accountType,
  Value<bool> isActive,
  Value<DateTime> createdAt,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<int> accountId,
  Value<int?> parentAccountId,
  Value<String> accountName,
  Value<String> fullPath,
  Value<AccountType> accountType,
  Value<bool> isActive,
  Value<DateTime> createdAt,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _parentAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias($_aliasNameGenerator(
          db.accounts.parentAccountId, db.accounts.accountId));

  $$AccountsTableProcessedTableManager? get parentAccountId {
    final $_column = $_itemColumn<int>('parent_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.accountId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PostingsTable, List<Posting>> _postingsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.postings,
          aliasName: $_aliasNameGenerator(
              db.accounts.accountId, db.postings.accountId));

  $$PostingsTableProcessedTableManager get postingsRefs {
    final manager = $$PostingsTableTableManager($_db, $_db.postings).filter(
        (f) =>
            f.accountId.accountId.sqlEquals($_itemColumn<int>('account_id')!));

    final cache = $_typedResult.readTableOrNull(_postingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountName => $composableBuilder(
      column: $table.accountName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fullPath => $composableBuilder(
      column: $table.fullPath, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<AccountType, AccountType, String>
      get accountType => $composableBuilder(
          column: $table.accountType,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get parentAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> postingsRefs(
      Expression<bool> Function($$PostingsTableFilterComposer f) f) {
    final $$PostingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.postings,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PostingsTableFilterComposer(
              $db: $db,
              $table: $db.postings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountName => $composableBuilder(
      column: $table.accountName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fullPath => $composableBuilder(
      column: $table.fullPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get parentAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get accountName => $composableBuilder(
      column: $table.accountName, builder: (column) => column);

  GeneratedColumn<String> get fullPath =>
      $composableBuilder(column: $table.fullPath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountType, String> get accountType =>
      $composableBuilder(
          column: $table.accountType, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get parentAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> postingsRefs<T extends Object>(
      Expression<T> Function($$PostingsTableAnnotationComposer a) f) {
    final $$PostingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.postings,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PostingsTableAnnotationComposer(
              $db: $db,
              $table: $db.postings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, $$AccountsTableReferences),
    Account,
    PrefetchHooks Function({bool parentAccountId, bool postingsRefs})> {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> accountId = const Value.absent(),
            Value<int?> parentAccountId = const Value.absent(),
            Value<String> accountName = const Value.absent(),
            Value<String> fullPath = const Value.absent(),
            Value<AccountType> accountType = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AccountsCompanion(
            accountId: accountId,
            parentAccountId: parentAccountId,
            accountName: accountName,
            fullPath: fullPath,
            accountType: accountType,
            isActive: isActive,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> accountId = const Value.absent(),
            Value<int?> parentAccountId = const Value.absent(),
            required String accountName,
            required String fullPath,
            required AccountType accountType,
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AccountsCompanion.insert(
            accountId: accountId,
            parentAccountId: parentAccountId,
            accountName: accountName,
            fullPath: fullPath,
            accountType: accountType,
            isActive: isActive,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AccountsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {parentAccountId = false, postingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (postingsRefs) db.postings],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (parentAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.parentAccountId,
                    referencedTable:
                        $$AccountsTableReferences._parentAccountIdTable(db),
                    referencedColumn: $$AccountsTableReferences
                        ._parentAccountIdTable(db)
                        .accountId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (postingsRefs)
                    await $_getPrefetchedData<Account, $AccountsTable, Posting>(
                        currentTable: table,
                        referencedTable:
                            $$AccountsTableReferences._postingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .postingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.accountId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, $$AccountsTableReferences),
    Account,
    PrefetchHooks Function({bool parentAccountId, bool postingsRefs})>;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> transactionId,
  required DateTime transactionDate,
  Value<String?> description,
  Value<bool> isRecurring,
  Value<DateTime> createdAt,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> transactionId,
  Value<DateTime> transactionDate,
  Value<String?> description,
  Value<bool> isRecurring,
  Value<DateTime> createdAt,
});

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PostingsTable, List<Posting>> _postingsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.postings,
          aliasName: $_aliasNameGenerator(
              db.transactions.transactionId, db.postings.transactionId));

  $$PostingsTableProcessedTableManager get postingsRefs {
    final manager = $$PostingsTableTableManager($_db, $_db.postings).filter(
        (f) => f.transactionId.transactionId
            .sqlEquals($_itemColumn<int>('transaction_id')!));

    final cache = $_typedResult.readTableOrNull(_postingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionTagsTable, List<TransactionTag>>
      _transactionTagsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactionTags,
              aliasName: $_aliasNameGenerator(db.transactions.transactionId,
                  db.transactionTags.transactionId));

  $$TransactionTagsTableProcessedTableManager get transactionTagsRefs {
    final manager =
        $$TransactionTagsTableTableManager($_db, $_db.transactionTags).filter(
            (f) => f.transactionId.transactionId
                .sqlEquals($_itemColumn<int>('transaction_id')!));

    final cache =
        $_typedResult.readTableOrNull(_transactionTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
      column: $table.transactionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> postingsRefs(
      Expression<bool> Function($$PostingsTableFilterComposer f) f) {
    final $$PostingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.postings,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PostingsTableFilterComposer(
              $db: $db,
              $table: $db.postings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionTagsRefs(
      Expression<bool> Function($$TransactionTagsTableFilterComposer f) f) {
    final $$TransactionTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactionTags,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionTagsTableFilterComposer(
              $db: $db,
              $table: $db.transactionTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get transactionId => $composableBuilder(
      column: $table.transactionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
      column: $table.transactionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => column);

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
      column: $table.transactionDate, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> postingsRefs<T extends Object>(
      Expression<T> Function($$PostingsTableAnnotationComposer a) f) {
    final $$PostingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.postings,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PostingsTableAnnotationComposer(
              $db: $db,
              $table: $db.postings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionTagsRefs<T extends Object>(
      Expression<T> Function($$TransactionTagsTableAnnotationComposer a) f) {
    final $$TransactionTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactionTags,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactionTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function({bool postingsRefs, bool transactionTagsRefs})> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> transactionId = const Value.absent(),
            Value<DateTime> transactionDate = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<bool> isRecurring = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TransactionsCompanion(
            transactionId: transactionId,
            transactionDate: transactionDate,
            description: description,
            isRecurring: isRecurring,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> transactionId = const Value.absent(),
            required DateTime transactionDate,
            Value<String?> description = const Value.absent(),
            Value<bool> isRecurring = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            transactionId: transactionId,
            transactionDate: transactionDate,
            description: description,
            isRecurring: isRecurring,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {postingsRefs = false, transactionTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (postingsRefs) db.postings,
                if (transactionTagsRefs) db.transactionTags
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (postingsRefs)
                    await $_getPrefetchedData<Transaction, $TransactionsTable,
                            Posting>(
                        currentTable: table,
                        referencedTable: $$TransactionsTableReferences
                            ._postingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TransactionsTableReferences(db, table, p0)
                                .postingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionId == item.transactionId),
                        typedResults: items),
                  if (transactionTagsRefs)
                    await $_getPrefetchedData<Transaction, $TransactionsTable,
                            TransactionTag>(
                        currentTable: table,
                        referencedTable: $$TransactionsTableReferences
                            ._transactionTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TransactionsTableReferences(db, table, p0)
                                .transactionTagsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionId == item.transactionId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function({bool postingsRefs, bool transactionTagsRefs})>;
typedef $$PostingsTableCreateCompanionBuilder = PostingsCompanion Function({
  Value<int> postingId,
  required int transactionId,
  required int accountId,
  required double amount,
  Value<String?> postingTag,
  Value<DateTime> createdAt,
});
typedef $$PostingsTableUpdateCompanionBuilder = PostingsCompanion Function({
  Value<int> postingId,
  Value<int> transactionId,
  Value<int> accountId,
  Value<double> amount,
  Value<String?> postingTag,
  Value<DateTime> createdAt,
});

final class $$PostingsTableReferences
    extends BaseReferences<_$AppDatabase, $PostingsTable, Posting> {
  $$PostingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) =>
      db.transactions.createAlias($_aliasNameGenerator(
          db.postings.transactionId, db.transactions.transactionId));

  $$TransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<int>('transaction_id')!;

    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.transactionId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.postings.accountId, db.accounts.accountId));

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.accountId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PostingsTableFilterComposer
    extends Composer<_$AppDatabase, $PostingsTable> {
  $$PostingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get postingId => $composableBuilder(
      column: $table.postingId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get postingTag => $composableBuilder(
      column: $table.postingTag, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PostingsTableOrderingComposer
    extends Composer<_$AppDatabase, $PostingsTable> {
  $$PostingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get postingId => $composableBuilder(
      column: $table.postingId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get postingTag => $composableBuilder(
      column: $table.postingTag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableOrderingComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PostingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PostingsTable> {
  $$PostingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get postingId =>
      $composableBuilder(column: $table.postingId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get postingTag => $composableBuilder(
      column: $table.postingTag, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PostingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PostingsTable,
    Posting,
    $$PostingsTableFilterComposer,
    $$PostingsTableOrderingComposer,
    $$PostingsTableAnnotationComposer,
    $$PostingsTableCreateCompanionBuilder,
    $$PostingsTableUpdateCompanionBuilder,
    (Posting, $$PostingsTableReferences),
    Posting,
    PrefetchHooks Function({bool transactionId, bool accountId})> {
  $$PostingsTableTableManager(_$AppDatabase db, $PostingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PostingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PostingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PostingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> postingId = const Value.absent(),
            Value<int> transactionId = const Value.absent(),
            Value<int> accountId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String?> postingTag = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PostingsCompanion(
            postingId: postingId,
            transactionId: transactionId,
            accountId: accountId,
            amount: amount,
            postingTag: postingTag,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> postingId = const Value.absent(),
            required int transactionId,
            required int accountId,
            required double amount,
            Value<String?> postingTag = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PostingsCompanion.insert(
            postingId: postingId,
            transactionId: transactionId,
            accountId: accountId,
            amount: amount,
            postingTag: postingTag,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PostingsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({transactionId = false, accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (transactionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.transactionId,
                    referencedTable:
                        $$PostingsTableReferences._transactionIdTable(db),
                    referencedColumn: $$PostingsTableReferences
                        ._transactionIdTable(db)
                        .transactionId,
                  ) as T;
                }
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$PostingsTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$PostingsTableReferences._accountIdTable(db).accountId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PostingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PostingsTable,
    Posting,
    $$PostingsTableFilterComposer,
    $$PostingsTableOrderingComposer,
    $$PostingsTableAnnotationComposer,
    $$PostingsTableCreateCompanionBuilder,
    $$PostingsTableUpdateCompanionBuilder,
    (Posting, $$PostingsTableReferences),
    Posting,
    PrefetchHooks Function({bool transactionId, bool accountId})>;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  Value<int> tagId,
  required String tagName,
  Value<String?> displayColor,
  Value<DateTime> createdAt,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<int> tagId,
  Value<String> tagName,
  Value<String?> displayColor,
  Value<DateTime> createdAt,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionTagsTable, List<TransactionTag>>
      _transactionTagsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactionTags,
              aliasName: $_aliasNameGenerator(
                  db.tags.tagId, db.transactionTags.tagId));

  $$TransactionTagsTableProcessedTableManager get transactionTagsRefs {
    final manager = $$TransactionTagsTableTableManager(
            $_db, $_db.transactionTags)
        .filter((f) => f.tagId.tagId.sqlEquals($_itemColumn<int>('tag_id')!));

    final cache =
        $_typedResult.readTableOrNull(_transactionTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tagId => $composableBuilder(
      column: $table.tagId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagName => $composableBuilder(
      column: $table.tagName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayColor => $composableBuilder(
      column: $table.displayColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> transactionTagsRefs(
      Expression<bool> Function($$TransactionTagsTableFilterComposer f) f) {
    final $$TransactionTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.transactionTags,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionTagsTableFilterComposer(
              $db: $db,
              $table: $db.transactionTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tagId => $composableBuilder(
      column: $table.tagId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagName => $composableBuilder(
      column: $table.tagName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayColor => $composableBuilder(
      column: $table.displayColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);

  GeneratedColumn<String> get tagName =>
      $composableBuilder(column: $table.tagName, builder: (column) => column);

  GeneratedColumn<String> get displayColor => $composableBuilder(
      column: $table.displayColor, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> transactionTagsRefs<T extends Object>(
      Expression<T> Function($$TransactionTagsTableAnnotationComposer a) f) {
    final $$TransactionTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.transactionTags,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactionTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TagsTable,
    Tag,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableAnnotationComposer,
    $$TagsTableCreateCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder,
    (Tag, $$TagsTableReferences),
    Tag,
    PrefetchHooks Function({bool transactionTagsRefs})> {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> tagId = const Value.absent(),
            Value<String> tagName = const Value.absent(),
            Value<String?> displayColor = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TagsCompanion(
            tagId: tagId,
            tagName: tagName,
            displayColor: displayColor,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> tagId = const Value.absent(),
            required String tagName,
            Value<String?> displayColor = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TagsCompanion.insert(
            tagId: tagId,
            tagName: tagName,
            displayColor: displayColor,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TagsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({transactionTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transactionTagsRefs) db.transactionTags
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, TransactionTag>(
                        currentTable: table,
                        referencedTable:
                            $$TagsTableReferences._transactionTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TagsTableReferences(db, table, p0)
                                .transactionTagsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tagId == item.tagId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TagsTable,
    Tag,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableAnnotationComposer,
    $$TagsTableCreateCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder,
    (Tag, $$TagsTableReferences),
    Tag,
    PrefetchHooks Function({bool transactionTagsRefs})>;
typedef $$TransactionTagsTableCreateCompanionBuilder = TransactionTagsCompanion
    Function({
  required int transactionId,
  required int tagId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$TransactionTagsTableUpdateCompanionBuilder = TransactionTagsCompanion
    Function({
  Value<int> transactionId,
  Value<int> tagId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$TransactionTagsTableReferences extends BaseReferences<
    _$AppDatabase, $TransactionTagsTable, TransactionTag> {
  $$TransactionTagsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) =>
      db.transactions.createAlias($_aliasNameGenerator(
          db.transactionTags.transactionId, db.transactions.transactionId));

  $$TransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<int>('transaction_id')!;

    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.transactionId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) => db.tags.createAlias(
      $_aliasNameGenerator(db.transactionTags.tagId, db.tags.tagId));

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager($_db, $_db.tags)
        .filter((f) => f.tagId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionTagsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionTagsTable> {
  $$TransactionTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableFilterComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionTagsTable> {
  $$TransactionTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableOrderingComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableOrderingComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionTagsTable> {
  $$TransactionTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableAnnotationComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionTagsTable,
    TransactionTag,
    $$TransactionTagsTableFilterComposer,
    $$TransactionTagsTableOrderingComposer,
    $$TransactionTagsTableAnnotationComposer,
    $$TransactionTagsTableCreateCompanionBuilder,
    $$TransactionTagsTableUpdateCompanionBuilder,
    (TransactionTag, $$TransactionTagsTableReferences),
    TransactionTag,
    PrefetchHooks Function({bool transactionId, bool tagId})> {
  $$TransactionTagsTableTableManager(
      _$AppDatabase db, $TransactionTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> transactionId = const Value.absent(),
            Value<int> tagId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionTagsCompanion(
            transactionId: transactionId,
            tagId: tagId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int transactionId,
            required int tagId,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionTagsCompanion.insert(
            transactionId: transactionId,
            tagId: tagId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionTagsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({transactionId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (transactionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.transactionId,
                    referencedTable: $$TransactionTagsTableReferences
                        ._transactionIdTable(db),
                    referencedColumn: $$TransactionTagsTableReferences
                        ._transactionIdTable(db)
                        .transactionId,
                  ) as T;
                }
                if (tagId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tagId,
                    referencedTable:
                        $$TransactionTagsTableReferences._tagIdTable(db),
                    referencedColumn:
                        $$TransactionTagsTableReferences._tagIdTable(db).tagId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TransactionTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionTagsTable,
    TransactionTag,
    $$TransactionTagsTableFilterComposer,
    $$TransactionTagsTableOrderingComposer,
    $$TransactionTagsTableAnnotationComposer,
    $$TransactionTagsTableCreateCompanionBuilder,
    $$TransactionTagsTableUpdateCompanionBuilder,
    (TransactionTag, $$TransactionTagsTableReferences),
    TransactionTag,
    PrefetchHooks Function({bool transactionId, bool tagId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$PostingsTableTableManager get postings =>
      $$PostingsTableTableManager(_db, _db.postings);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$TransactionTagsTableTableManager get transactionTags =>
      $$TransactionTagsTableTableManager(_db, _db.transactionTags);
}
