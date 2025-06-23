import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/ledger/ledger_repository.dart';
import '../../db/app_database.dart';
import '../ledger/create_ledger_dialog.dart';

class PageHeader extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PageHeader({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titles = ['总览', '资产', '支出', '收入', '负债'];
    final selectedLedgerAsync = ref.watch(selectedLedgerProvider);

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 账本选择器
          Container(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                selectedLedgerAsync.when(
                  data: (ledger) => LedgerSelector(selectedLedger: ledger),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Text('加载账本失败'),
                ),
              ],
            ),
          ),
          // 页面标题栏
          Expanded(
              child: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                titles.length,
                (index) => GestureDetector(
                  onTap: () => onTap(index),
                  child: Container(
                    alignment: Alignment.center,
                    width: 60,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: currentIndex == index ? 24 : 16,
                        fontWeight: currentIndex == index
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: currentIndex == index
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                      child: Text(
                        titles[index],
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ))
        ],
      ),
    );
  }
}

// 账本选择器组件
class LedgerSelector extends ConsumerWidget {
  final Ledger? selectedLedger;

  const LedgerSelector({
    super.key,
    required this.selectedLedger,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allLedgersAsync = ref.watch(watchAllLedgersProvider);

    return allLedgersAsync.when(
      data: (ledgers) {
        if (ledgers.isEmpty) {
          return const Text('没有账本，请创建');
        }

        return GestureDetector(
          onTap: () => _showLedgerSelection(context, ref, ledgers),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedLedger?.name ?? '选择账本',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Text('加载账本失败'),
    );
  }

  void _showLedgerSelection(
      BuildContext context, WidgetRef ref, List<Ledger> ledgers) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '选择账本',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  itemCount: ledgers.length,
                  itemBuilder: (context, index) {
                    final ledger = ledgers[index];
                    final isSelected =
                        selectedLedger?.ledgerId == ledger.ledgerId;

                    return InkWell(
                      onTap: () {
                        ref
                            .read(ledgerRepositoryProvider)
                            .setLedgerAsSelected(ledger.ledgerId);
                        Navigator.pop(context);
                      },
                      onLongPress: () {
                        Navigator.pop(
                            context); // Close the selection sheet first
                        showDialog(
                          context: context,
                          builder: (_) => CreateLedgerDialog(ledger: ledger),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, top: 16.0, bottom: 0.0),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: isSelected
                                    ? Colors.blue[100]
                                    : Colors.grey[200],
                              ),
                              child: Text(
                                ledger.name.substring(0, 1),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.blue[800]
                                      : Colors.grey[800],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ledger.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ledger.description ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Visibility(
                              visible: isSelected,
                              maintainAnimation: true,
                              maintainState: true,
                              maintainSize: true,
                              child: const Icon(Icons.check_circle,
                                  color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    // 显示创建账本的对话框
                    showDialog<bool>(
                      context: context,
                      builder: (context) => const CreateLedgerDialog(),
                    ).then((created) {
                      if (created == true && context.mounted) {
                        Navigator.pop(context);
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '创建新账本',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
