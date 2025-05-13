import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../db/app_database.dart';
import '../state/transaction/transaction_repository.dart';

/// 交易列表页面
class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用transactionRepositoryProvider获取仓库
    final transactionRepository = ref.watch(transactionRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('交易列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTransactionDialog(context, ref),
          ),
        ],
      ),
      body: StreamBuilder<List<Transaction>>(
        // 使用仓库监听交易变化
        stream: transactionRepository.watchAllTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('错误: ${snapshot.error}'));
          }

          final transactions = snapshot.data ?? [];
          if (transactions.isEmpty) {
            return const Center(child: Text('暂无交易数据，请添加新交易'));
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return TransactionListTile(transaction: transaction);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 显示过滤选项
  void _showFilterOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text('今日交易'),
                onTap: () {
                  Navigator.pop(context);
                  _filterTransactions(context, ref, 'today');
                },
              ),
              ListTile(
                leading: const Icon(Icons.view_week),
                title: const Text('本周交易'),
                onTap: () {
                  Navigator.pop(context);
                  _filterTransactions(context, ref, 'week');
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('本月交易'),
                onTap: () {
                  Navigator.pop(context);
                  _filterTransactions(context, ref, 'month');
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('自定义日期范围'),
                onTap: () {
                  Navigator.pop(context);
                  _showDateRangePicker(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('显示所有交易'),
                onTap: () {
                  Navigator.pop(context);
                  _filterTransactions(context, ref, 'all');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 过滤交易
  void _filterTransactions(BuildContext context, WidgetRef ref, String filter) {
    // 此处只是演示，实际上应该改变UI的状态使其显示不同的StreamBuilder
    String message = '';
    switch (filter) {
      case 'today':
        message = '显示今日交易';
        break;
      case 'week':
        message = '显示本周交易';
        break;
      case 'month':
        message = '显示本月交易';
        break;
      case 'all':
        message = '显示所有交易';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 显示日期范围选择器
  void _showDateRangePicker(BuildContext context, WidgetRef ref) async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (dateRange != null) {
      // 这里可以使用仓库的watchTransactionsByDateRange方法
      final formatter = DateFormat('yyyy-MM-dd');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '显示${formatter.format(dateRange.start)}至${formatter.format(dateRange.end)}的交易')),
      );
    }
  }

  // 添加交易对话框
  void _showAddTransactionDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    String description = '';
    bool isRecurring = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加新交易'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: '交易日期',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      dateController.text =
                          DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: '描述'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入交易描述';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    description = value ?? '';
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('是否周期性交易'),
                  value: isRecurring,
                  onChanged: (value) {
                    isRecurring = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();

                  // 使用仓库添加交易
                  final repository = ref.read(transactionRepositoryProvider);
                  final date =
                      DateFormat('yyyy-MM-dd').parse(dateController.text);

                  repository
                      .createTransaction(
                    date: date,
                    description: description,
                    isRecurring: isRecurring,
                  )
                      .then((_) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('交易创建成功')),
                    );
                  }).catchError((error) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('交易创建失败: $error')),
                    );
                  });
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
}

/// 交易列表项组件
class TransactionListTile extends ConsumerWidget {
  final Transaction transaction;

  const TransactionListTile({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return ListTile(
      title: Text(transaction.description ?? '无描述'),
      subtitle: Text(dateFormat.format(transaction.transactionDate)),
      leading: const Icon(Icons.receipt_long),
      trailing: transaction.isRecurring
          ? const Icon(Icons.repeat, color: Colors.blue)
          : null,
      onTap: () {
        // 查看交易详情
      },
      onLongPress: () {
        _showTransactionOptions(context, ref);
      },
    );
  }

  // 显示交易操作选项
  void _showTransactionOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑交易'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditTransactionDialog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_copy),
                title: const Text('复制交易'),
                onTap: () {
                  Navigator.pop(context);
                  _duplicateTransaction(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除交易'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteTransaction(context, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 显示编辑交易对话框
  void _showEditTransactionDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(transaction.transactionDate));
    String description = transaction.description ?? '';
    bool isRecurring = transaction.isRecurring;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑交易'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: '交易日期',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: transaction.transactionDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      dateController.text =
                          DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(labelText: '描述'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入交易描述';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    description = value ?? '';
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('是否周期性交易'),
                  value: isRecurring,
                  onChanged: (value) {
                    isRecurring = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();

                  // 使用仓库更新交易
                  final repository = ref.read(transactionRepositoryProvider);
                  final date =
                      DateFormat('yyyy-MM-dd').parse(dateController.text);

                  repository
                      .updateTransaction(
                    id: transaction.transactionId,
                    date: date,
                    description: description,
                    isRecurring: isRecurring,
                  )
                      .then((_) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('交易更新成功')),
                    );
                  }).catchError((error) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('交易更新失败: $error')),
                    );
                  });
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // 复制交易
  void _duplicateTransaction(BuildContext context, WidgetRef ref) {
    final repository = ref.read(transactionRepositoryProvider);
    repository.duplicateTransaction(transaction).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('交易复制成功')),
      );
    });
  }

  // 确认删除交易
  void _confirmDeleteTransaction(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除这条交易记录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                // 使用仓库删除交易
                final repository = ref.read(transactionRepositoryProvider);
                repository
                    .deleteTransaction(transaction.transactionId)
                    .then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('交易删除成功')),
                  );
                });
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}
