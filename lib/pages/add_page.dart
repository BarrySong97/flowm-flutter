import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/common/bottom_input_toolbar.dart';
import 'package:flowm/components/common/number_keypad.dart';
import 'package:flowm/components/common/account_selector_field.dart';
import 'package:flowm/components/common/account_selector_bottom_sheet.dart';
import 'package:flowm/components/account/account_item.dart';
import 'package:flowm/utils/transaction_type_map.dart';
import 'package:flowm/utils/account_transaction_validator.dart';
import 'package:flowm/pages/account_transaction_guide_screen.dart';
import 'package:flowm/state/transaction/transaction_repository.dart';
import 'package:flowm/state/transaction/frequent_descriptions_provider.dart';
import 'package:flowm/db/dao/transaction_dao.dart' show TransactionWithAmount;
import 'package:flowm/db/app_database.dart' as db;
import 'package:flowm/db/tables/account_table.dart' show AccountType;
import 'package:flowm/state/add_page_params_provider.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/state/home_page/overview_page_providers.dart';
import 'package:flowm/state/expense/expense_providers.dart';
import 'package:flowm/state/icome/income_providers.dart';
import 'package:flowm/state/home_page/assets_page_providers.dart';
import 'package:flowm/state/liabilities/liabilities_repository.dart';
import 'package:flowm/utils/provider_invalidator.dart';

class AddPage extends ConsumerStatefulWidget {
  final int? transactionId;
  final String? transactionType;
  const AddPage({super.key, this.transactionId, this.transactionType});

  @override
  ConsumerState<AddPage> createState() => _AddPageState();
}

class _AddPageState extends ConsumerState<AddPage>
    with SingleTickerProviderStateMixin {
  String amount = "0.00";
  String _currentExpression = ""; // 存储当前的运算表达式
  late TabController _tabController;
  final List<String> _tabs = TransactionType.getAllDisplayNames();
  final TextEditingController _noteController = TextEditingController();
  DateTime _currentDateTime = DateTime.now();

  bool _isEditMode = false;

  // 新增的账户选择状态
  Account? _fromAccount;
  Account? _toAccount;
  String _transactionFlowType = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    if (widget.transactionId != null) {
      _isEditMode = true;
      _loadTransactionData();
    } else {
      // 如果不是编辑模式，检查是否有深度链接参数
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final params = ref.read(addPageParamsProvider);
        if (params != null && !params.isEmpty) {
          // 有URL参数，只加载深度链接参数，不执行默认账户初始化
          _loadDeepLinkParams();
        } else {
          // 没有URL参数，执行默认账户初始化
          _handleTransactionType();
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactionData() async {
    final transaction = await ref
        .read(transactionRepositoryProvider)
        .getTransactionWithAmountById(widget.transactionId!);

    if (transaction != null) {
      final db.Account? dbFromAccount = transaction.fromAccount;
      final db.Account? dbToAccount = transaction.toAccount;

      setState(() {
        amount = transaction.amount.toStringAsFixed(2);
        _noteController.text = transaction.transaction.description ?? '';
        _currentDateTime = transaction.transaction.transactionDate;
        if (dbFromAccount != null) {
          _fromAccount = Account(
            id: dbFromAccount.accountId,
            name: dbFromAccount.accountName,
            amount: 0,
            type: dbFromAccount.accountType,
          );
        }
        if (dbToAccount != null) {
          _toAccount = Account(
            id: dbToAccount.accountId,
            name: dbToAccount.accountName,
            amount: 0,
            type: dbToAccount.accountType,
          );
        }
        _transactionFlowType = _calculateTransactionFlowType();
      });
    }
  }

  /// 处理交易类型参数
  Future<void> _handleTransactionType() async {
    if (widget.transactionType == null) return;

    try {
      final selectedLedger = await ref.read(selectedLedgerProvider.future);

      if (selectedLedger == null) return;

      if (widget.transactionType == 'expense') {
        // 支出：只填充默认资产账户作为从账户，让用户自己选择支出分类账户
        final defaultAssetAccount = await ref
            .read(accountRepositoryProvider)
            .getDefaultAssetAccount(selectedLedger.ledgerId);

        if (defaultAssetAccount != null) {
          final fromAccountBalance = await ref
              .read(accountRepositoryProvider)
              .getAccountBalance(defaultAssetAccount.accountId);

          if (mounted) {
            setState(() {
              _fromAccount = Account(
                id: defaultAssetAccount.accountId,
                name: defaultAssetAccount.accountName,
                amount: fromAccountBalance,
                type: defaultAssetAccount.accountType,
              );
              _transactionFlowType = _calculateTransactionFlowType();
            });
          }
        }
      } else if (widget.transactionType == 'income') {
        // 收入：只填充默认资产账户作为到账户，让用户自己选择收入分类账户
        final defaultAssetAccount = await ref
            .read(accountRepositoryProvider)
            .getDefaultAssetAccount(selectedLedger.ledgerId);

        if (defaultAssetAccount != null) {
          final toAccountBalance = await ref
              .read(accountRepositoryProvider)
              .getAccountBalance(defaultAssetAccount.accountId);

          if (mounted) {
            setState(() {
              _toAccount = Account(
                id: defaultAssetAccount.accountId,
                name: defaultAssetAccount.accountName,
                amount: toAccountBalance,
                type: defaultAssetAccount.accountType,
              );
              _transactionFlowType = _calculateTransactionFlowType();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[AddPage] 处理交易类型参数失败: $e');
    }
  }

  /// 加载深度链接参数
  Future<void> _loadDeepLinkParams() async {
    final params = ref.read(addPageParamsProvider);
    if (params == null || params.isEmpty) return;

    try {
      debugPrint('[AddPage] 开始加载深度链接参数: $params');

      // 设置金额
      if (params.amount != null) {
        setState(() {
          amount = params.amount!.toStringAsFixed(2);
        });
      }

      // 设置备注
      if (params.description != null) {
        setState(() {
          _noteController.text = params.description!;
        });
      }

      // 设置日期
      if (params.date != null) {
        try {
          final dateTime = DateTime.now();
          setState(() {
            _currentDateTime = dateTime;
          });
        } catch (e) {
          debugPrint('[AddPage] 日期解析失败: ${params.date}, 错误: $e');
        }
      }

      // 获取所有账户
      final accounts =
          await ref.read(accountRepositoryProvider).getAllAccounts();

      // 设置从账户
      if (params.fromAccountId != null) {
        final fromAccount = accounts.firstWhere(
          (account) => account.accountId == params.fromAccountId,
          orElse: () => throw Exception('找不到指定的从账户'),
        );
        // 查询账户的真实余额
        final fromAccountBalance = await ref
            .read(accountRepositoryProvider)
            .getAccountBalance(fromAccount.accountId);
        setState(() {
          _fromAccount = Account(
            id: fromAccount.accountId,
            name: fromAccount.accountName,
            amount: fromAccountBalance,
            type: fromAccount.accountType,
          );
        });
      }

      // 设置到账户
      if (params.toAccountId != null) {
        final toAccount = accounts.firstWhere(
          (account) => account.accountId == params.toAccountId,
          orElse: () => throw Exception('找不到指定的到账户'),
        );
        // 查询账户的真实余额
        final toAccountBalance = await ref
            .read(accountRepositoryProvider)
            .getAccountBalance(toAccount.accountId);
        setState(() {
          _toAccount = Account(
            id: toAccount.accountId,
            name: toAccount.accountName,
            amount: toAccountBalance,
            type: toAccount.accountType,
          );
          _transactionFlowType = _calculateTransactionFlowType();
        });
      }

      // 清空参数，避免重复使用
      ref.read(addPageParamsProvider.notifier).state = null;

      debugPrint('[AddPage] 深度链接参数加载完成');
    } catch (e) {
      debugPrint('[AddPage] 加载深度链接参数失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载深度链接参数失败: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _swapAccounts() {
    setState(() {
      final tempAccount = _fromAccount;
      _fromAccount = _toAccount;
      _toAccount = tempAccount;
      _transactionFlowType = _calculateTransactionFlowType();
    });
  }

  String _calculateTransactionFlowType() {
    if (_fromAccount != null && _toAccount != null) {
      return getTransactionFlowType(
        _fromAccount!.type,
        _toAccount!.type,
      );
    }
    return '';
  }

  String _formatDateTime(DateTime dateTime) {
    final date = dateTime.toString().split(' ')[0];
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  Widget _buildTransactionValidationIndicator() {
    if (_fromAccount == null || _toAccount == null) {
      return const SizedBox.shrink();
    }

    final validationResult = AccountTransactionValidator.validateTransaction(
      fromAccountType: _fromAccount!.type,
      toAccountType: _toAccount!.type,
    );

    IconData icon;
    Color color;
    String tooltip;

    switch (validationResult.level) {
      case TransactionValidationLevel.normal:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        tooltip = '正常交易';
        break;
      case TransactionValidationLevel.uncommon:
        icon = Icons.warning_amber_outlined;
        color = Colors.orange;
        tooltip = validationResult.warningMessage ?? '不常见交易';
        break;
      case TransactionValidationLevel.abnormal:
        icon = Icons.error_outline;
        color = Colors.red;
        tooltip = validationResult.warningMessage ?? '异常交易';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildTransactionValidationCard() {
    if (_fromAccount == null || _toAccount == null) {
      return const SizedBox.shrink();
    }

    final validationResult = AccountTransactionValidator.validateTransaction(
      fromAccountType: _fromAccount!.type,
      toAccountType: _toAccount!.type,
    );

    // 正常交易不显示提示卡片
    if (validationResult.level == TransactionValidationLevel.normal) {
      return const SizedBox(height: 12);
    }

    IconData icon;
    Color backgroundColor;
    Color iconColor;
    Color textColor;

    switch (validationResult.level) {
      case TransactionValidationLevel.normal:
        return const SizedBox(height: 12);
      case TransactionValidationLevel.uncommon:
        icon = Icons.warning_amber_outlined;
        backgroundColor = Colors.orange.shade50;
        iconColor = Colors.orange.shade600;
        textColor = Colors.orange.shade700;
        break;
      case TransactionValidationLevel.abnormal:
        icon = Icons.error_outline;
        backgroundColor = Colors.red.shade50;
        iconColor = Colors.red.shade600;
        textColor = Colors.red.shade700;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              validationResult.warningMessage ??
                  (validationResult.level == TransactionValidationLevel.uncommon
                      ? '这是一笔不常见的交易类型，请确认账户选择是否正确'
                      : '这种账户组合可能不合理，请检查账户选择'),
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建高频备注快速选择列表
  Widget _buildFrequentDescriptionsBadges() {
    return Consumer(
      builder: (context, ref, _) {
        final frequentDescriptions = ref.watch(frequentDescriptionsProvider);

        return frequentDescriptions.when(
          data: (descriptions) {
            if (descriptions.isEmpty) return const SizedBox.shrink();

            return Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: descriptions.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _noteController.text = item.description;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F1F1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.description,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Future<TimeOfDay?> _showTimeInputDialog() async {
    return await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return _TimeInputDialog(
          initialHour: _currentDateTime.hour,
          initialMinute: _currentDateTime.minute,
        );
      },
    );
  }

  void _handleDateTap() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _currentDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.green,
            colorScheme: const ColorScheme.light(primary: Colors.green),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            datePickerTheme: DatePickerThemeData(
              dividerColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              headerBackgroundColor: Colors.green[400],
              headerForegroundColor: Colors.white,
              dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.green[200];
                }
                return Colors.transparent;
              }),
              dayForegroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.disabled)) {
                  return Colors.grey[400];
                }
                if (states.contains(MaterialState.selected)) {
                  return Colors.black87;
                }
                return Colors.black87;
              }),
              dayOverlayColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.green[200];
                }
                if (states.contains(MaterialState.hovered) ||
                    states.contains(MaterialState.pressed)) {
                  return Colors.green[100];
                }
                return Colors.transparent;
              }),
              dayShape: MaterialStateProperty.resolveWith((states) {
                return RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                );
              }),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      // 直接使用键盘输入时间
      TimeOfDay? selectedTime;
      if (mounted) {
        selectedTime = await _showTimeInputDialog();
      }

      if (selectedTime != null) {
        final time = selectedTime;
        setState(() {
          _currentDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            time.hour,
            time.minute,
          );
        });
      } else {
        // 如果用户取消了时间选择，只更新日期部分，保持原有时间
        setState(() {
          _currentDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            _currentDateTime.hour,
            _currentDateTime.minute,
            _currentDateTime.second,
          );
        });
      }
    }
  }

  void onKeypadPressed(String value) {
    setState(() {
      if (value == '⌫') {
        // 删除逻辑
        if (_currentExpression.isNotEmpty) {
          _currentExpression =
              _currentExpression.substring(0, _currentExpression.length - 1);
          if (_currentExpression.isEmpty) {
            amount = "0.00";
          } else {
            _updateAmountFromExpression();
          }
        } else if (amount.isNotEmpty && amount != "0.00") {
          if (amount.length == 1) {
            amount = "0.00";
          } else {
            amount = amount.substring(0, amount.length - 1);
          }
        }
      } else if (value == '确定') {
        // 如果有表达式，先计算结果
        if (_currentExpression.isNotEmpty) {
          _calculateExpression();
        }
        _saveTransaction();
      } else if (value == '=') {
        // 等号按钮只计算表达式，不保存
        if (_currentExpression.isNotEmpty) {
          _calculateExpression();
        }
      } else if (value == '+' || value == '-') {
        // 运算符逻辑
        if (amount != "0.00" && amount.isNotEmpty) {
          if (_currentExpression.isEmpty) {
            _currentExpression = amount;
          }
          // 如果表达式的最后一个字符不是运算符，则添加运算符
          if (_currentExpression.isNotEmpty &&
              !_currentExpression.endsWith('+') &&
              !_currentExpression.endsWith('-')) {
            _currentExpression += value;
          } else if (_currentExpression.endsWith('+') ||
              _currentExpression.endsWith('-')) {
            // 如果最后一个字符是运算符，替换它
            _currentExpression =
                _currentExpression.substring(0, _currentExpression.length - 1) +
                    value;
          }
        }
      } else if (value == '.') {
        // 小数点逻辑
        if (_currentExpression.isNotEmpty) {
          // 如果在输入表达式中，检查当前数字是否已有小数点
          List<String> parts = _currentExpression.split(RegExp(r'[+\-]'));
          String currentNumber = parts.last;
          if (!currentNumber.contains('.')) {
            _currentExpression += value;
          }
        } else if (!amount.contains('.')) {
          if (amount == "0.00") {
            amount = "0.";
          } else {
            amount = amount + value;
          }
        }
      } else if (RegExp(r'^\d$').hasMatch(value)) {
        // 数字逻辑
        if (_currentExpression.isNotEmpty) {
          _currentExpression += value;
          _updateAmountFromExpression();
        } else {
          if (amount == "0.00") {
            amount = value;
          } else {
            amount = amount + value;
          }
        }
      }
    });
  }

  void _updateAmountFromExpression() {
    // 从表达式中提取当前正在输入的数字
    if (_currentExpression.isNotEmpty) {
      List<String> parts = _currentExpression.split(RegExp(r'[+\-]'));
      if (parts.isNotEmpty) {
        String currentNumber = parts.last;
        if (currentNumber.isNotEmpty) {
          amount = currentNumber;
        }
      }
    }
  }

  void _calculateExpression() {
    if (_currentExpression.isEmpty) return;

    try {
      // 简单的表达式计算
      List<String> numbers = [];
      List<String> operators = [];

      String currentNumber = '';
      for (int i = 0; i < _currentExpression.length; i++) {
        String char = _currentExpression[i];
        if (char == '+' || char == '-') {
          if (currentNumber.isNotEmpty) {
            numbers.add(currentNumber);
            currentNumber = '';
          }
          operators.add(char);
        } else {
          currentNumber += char;
        }
      }
      if (currentNumber.isNotEmpty) {
        numbers.add(currentNumber);
      }

      if (numbers.length > 1) {
        double result = double.parse(numbers[0]);
        for (int i = 0; i < operators.length; i++) {
          if (operators[i] == '+') {
            result += double.parse(numbers[i + 1]);
          } else if (operators[i] == '-') {
            result -= double.parse(numbers[i + 1]);
          }
        }

        // 保留两位小数
        amount = result.toStringAsFixed(2);
        _currentExpression = '';
      }
    } catch (e) {
      // 计算错误时保持原值
      _currentExpression = '';
    }
  }

  void _clearForm() {
    setState(() {
      amount = "0.00";
      _currentExpression = "";
      _noteController.clear();
      _fromAccount = null;
      _toAccount = null;
      _transactionFlowType = '';
      _currentDateTime = DateTime.now();
    });
  }

  void _saveTransaction() async {
    if (_fromAccount == null || _toAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择从账户和到账户'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_fromAccount!.id == _toAccount!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('"从账户"和"到账户"不能相同'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final transactionAmount = double.tryParse(amount);
    if (transactionAmount == null || transactionAmount == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入有效金额'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('备注不能为空'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 检查交易是否异常，如果异常则阻止创建
    final validationResult = AccountTransactionValidator.validateTransaction(
      fromAccountType: _fromAccount!.type,
      toAccountType: _toAccount!.type,
    );

    if (validationResult.level == TransactionValidationLevel.abnormal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationResult.warningMessage ?? '此交易类型不被允许'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (_isEditMode) {
        // 更新逻辑
        await ref
            .read(transactionRepositoryProvider)
            .updateTransactionWithPostings(
              transactionId: widget.transactionId!,
              fromAccountId: _fromAccount!.id,
              toAccountId: _toAccount!.id,
              amount: transactionAmount,
              transactionDate: _currentDateTime,
              description: _noteController.text,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('交易已更新'),
            backgroundColor: Colors.green,
          ),
        );
        if (mounted) {
          // revalidate providers (在清空表单前调用)
          invalidateProvidersForTransaction(
            ref,
            fromAccountType: _fromAccount!.type,
            toAccountType: _toAccount!.type,
          );
          _clearForm();
          Navigator.of(context).pop();
        }
      } else {
        // 创建逻辑
        await ref
            .read(transactionRepositoryProvider)
            .createTransactionWithPostings(
              fromAccountId: _fromAccount!.id,
              toAccountId: _toAccount!.id,
              amount: transactionAmount,
              transactionDate: _currentDateTime,
              description: _noteController.text,
            );

        // revalidate providers
        invalidateProvidersForTransaction(
          ref,
          fromAccountType: _fromAccount!.type,
          toAccountType: _toAccount!.type,
        );

        // 显示成功消息并返回
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('交易已保存'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionAmountValue = double.tryParse(amount) ?? 0.0;

    // 监听深度链接参数变化
    ref.listen(addPageParamsProvider, (previous, next) {
      if (next != null && !next.isEmpty && !_isEditMode) {
        debugPrint('[AddPage] 检测到新的深度链接参数: $next');
        _loadDeepLinkParams();
      }
    });
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          _isEditMode ? '编辑模式' : '添加',
          style: const TextStyle(color: Colors.black87, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AccountTransactionGuideScreen(),
                ),
              );
            },
          ),
        ],
        titleSpacing: 0,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 金额显示区域
            Container(
              padding: const EdgeInsets.only(
                  top: 0, left: 16, right: 16, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_currentExpression.isNotEmpty) ...[
                        Text(
                          _currentExpression,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final selectedLedger =
                          ref.watch(selectedLedgerProvider).value;
                      return Text(
                        '${selectedLedger?.currencySymbol ?? '¥'}$amount',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w300,
                          color: Colors.black87,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 表单区域
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // 从账户选择器
                    AccountSelectorField(
                      label: '从账户',
                      selectedAccount: _fromAccount,
                      onAccountChanged: (account) {
                        setState(() {
                          if (account != null && _toAccount?.id == account.id) {
                            _toAccount = null;
                          }
                          _fromAccount = account;
                          _transactionFlowType =
                              _calculateTransactionFlowType();
                        });
                      },
                      hintText: '选择资金来源',
                      defaultAccountType: AccountSelectorType.asset,
                      transactionAmount: transactionAmountValue,
                      isFromAccount: true,
                      fromAccountType: _fromAccount?.type,
                      toAccountType: _toAccount?.type,
                      isEditMode: _isEditMode,
                    ),
                    const SizedBox(height: 12),

                    // 转账箭头
                    GestureDetector(
                      onTap: _swapAccounts,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swap_vert,
                              color: Colors.grey[400],
                              size: 28,
                            ),
                            if (_transactionFlowType.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                _transactionFlowType,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            // 显示交易验证状态
                            if (_fromAccount != null && _toAccount != null) ...[
                              const SizedBox(width: 8),
                              _buildTransactionValidationIndicator(),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // 到账户选择器
                    AccountSelectorField(
                      label: '到账户',
                      selectedAccount: _toAccount,
                      onAccountChanged: (account) {
                        setState(() {
                          if (account != null &&
                              _fromAccount?.id == account.id) {
                            _fromAccount = null;
                          }
                          _toAccount = account;
                          _transactionFlowType =
                              _calculateTransactionFlowType();
                        });
                      },
                      hintText: '选择资金去向',
                      defaultAccountType: AccountSelectorType.expense,
                      transactionAmount: transactionAmountValue,
                      isFromAccount: false,
                      fromAccountType: _fromAccount?.type,
                      toAccountType: _toAccount?.type,
                      isEditMode: _isEditMode,
                    ),

                    // 交易验证提示区域
                    _buildTransactionValidationCard(),

                    const Spacer(),
                  ],
                ),
              ),
            ),

            // 高频备注快速选择
            _buildFrequentDescriptionsBadges(),

            // 底部输入工具栏
            BottomInputToolbar(
              date: _formatDateTime(_currentDateTime),
              noteController: _noteController,
              onDateTap: _handleDateTap,
            ),

            // 数字键盘
            NumberKeypad(
              onKeyPressed: onKeypadPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeInputDialog extends StatefulWidget {
  final int initialHour;
  final int initialMinute;

  const _TimeInputDialog({
    required this.initialHour,
    required this.initialMinute,
  });

  @override
  State<_TimeInputDialog> createState() => _TimeInputDialogState();
}

class _TimeInputDialogState extends State<_TimeInputDialog> {
  late TextEditingController hourController;
  late TextEditingController minuteController;

  @override
  void initState() {
    super.initState();
    hourController = TextEditingController();
    minuteController = TextEditingController();

    // 设置初始值
    hourController.text = widget.initialHour.toString().padLeft(2, '0');
    minuteController.text = widget.initialMinute.toString().padLeft(2, '0');
  }

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('输入时间'),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            child: TextField(
              controller: hourController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 2,
              decoration: const InputDecoration(
                counterText: '',
                labelText: '时',
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(':', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          SizedBox(
            width: 60,
            child: TextField(
              controller: minuteController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 2,
              decoration: const InputDecoration(
                counterText: '',
                labelText: '分',
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final hour = int.tryParse(hourController.text) ?? 0;
            final minute = int.tryParse(minuteController.text) ?? 0;

            if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
              Navigator.of(context).pop(TimeOfDay(hour: hour, minute: minute));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('请输入有效时间（小时：0-23，分钟：0-59）'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
