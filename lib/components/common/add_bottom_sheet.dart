import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flowm/components/common/account_creation_bottom_sheet.dart';
import 'package:flowm/components/common/account_selector_bottom_sheet.dart';

class AddBottomSheet extends StatelessWidget {
  final int currentIndex;

  const AddBottomSheet({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.trending_down,
                      label: '添加支出',
                      color: Colors.red[600]!,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/add', extra: {'type': 'expense'});
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.trending_up,
                      label: '添加收入',
                      color: Colors.blue[600]!,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/add', extra: {'type': 'income'});
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.receipt_long,
                      label: '添加流水',
                      color: Colors.grey[600]!,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/add');
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.account_balance_wallet,
                      label: _getAccountButtonLabel(),
                      color: Colors.green,
                      onTap: () async {
                        Navigator.pop(context);
                        await AccountCreationBottomSheet.show(
                          context,
                          defaultAccountType: _getDefaultAccountType(),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAccountButtonLabel() {
    switch (currentIndex) {
      case 1: // 资产
        return '添加资产账户';
      case 2: // 支出
        return '添加支出分类(账户)';
      case 3: // 收入
        return '添加收入分类(账户)';
      case 4: // 负债
        return '添加负债账户';
      default:
        return '添加账户';
    }
  }

  AccountSelectorType _getDefaultAccountType() {
    switch (currentIndex) {
      case 1: // 资产
        return AccountSelectorType.asset;
      case 2: // 支出
        return AccountSelectorType.expense;
      case 3: // 收入
        return AccountSelectorType.income;
      case 4: // 负债
        return AccountSelectorType.liability;
      default:
        return AccountSelectorType.asset;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
