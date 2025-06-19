import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/common/bottom_input_toolbar.dart';
import 'package:flowm/components/common/number_keypad.dart';
import 'package:flowm/components/common/account_selector_field.dart';
import 'package:flowm/components/common/account_selector_bottom_sheet.dart';
import 'package:flowm/components/account/account_item.dart';
import 'package:flowm/utils/transaction_type_map.dart';
import 'package:flowm/state/transaction/transaction_repository.dart';
import 'package:flowm/db/dao/transaction_dao.dart' show TransactionWithAmount;
import 'package:flowm/db/app_database.dart' as db;
import 'package:flowm/state/add_page_params_provider.dart';
import 'package:flowm/state/account/account_repository.dart';

class AddPage extends ConsumerStatefulWidget {
  final int? transactionId;
  const AddPage({super.key, this.transactionId});

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
  String _currentDate = DateTime.now().toString().split(' ')[0];

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
        _loadDeepLinkParams();
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
        _currentDate =
            transaction.transaction.transactionDate.toString().split(' ')[0];
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
          final dateTime = DateTime.parse(params.date!);
          setState(() {
            _currentDate = dateTime.toString().split(' ')[0];
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

  void _handleDateTap() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            datePickerTheme: DatePickerThemeData(
              dividerColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              headerBackgroundColor: Colors.blue[600],
              headerForegroundColor: Colors.white,
              dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.blue[400];
                }
                return Colors.transparent;
              }),
              dayForegroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.disabled)) {
                  return Colors.grey[400];
                }
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return Colors.black87;
              }),
              dayOverlayColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.blue[400];
                }
                if (states.contains(MaterialState.hovered) ||
                    states.contains(MaterialState.pressed)) {
                  return Colors.blue[100];
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
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          _currentDate = selectedDate.toString().split(' ')[0];
        });
      }
    });
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
      _currentDate = DateTime.now().toString().split(' ')[0];
    });
  }

  void _saveTransaction() async {
    // TODO: 实现保存逻辑
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
              transactionDate: DateTime.parse(_currentDate),
              description: _noteController.text,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('交易已更新'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
        if (mounted) {
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
              transactionDate: DateTime.parse(_currentDate),
              description: _noteController.text,
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
      appBar: _isEditMode
          ? AppBar(
              backgroundColor: Colors.white,
              title: const Text(
                '编辑模式',
                style: TextStyle(color: Colors.black87, fontSize: 18),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
              elevation: 0,
            )
          : null,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 金额显示区域
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 显示运算表达式（如果有的话）
                      const Text(
                        '金额',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
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
                  Text(
                    '¥$amount',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      color: Colors.black87,
                    ),
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

                    const Spacer(),
                  ],
                ),
              ),
            ),

            // 底部输入工具栏
            BottomInputToolbar(
              date: _currentDate,
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
