import 'package:flutter/material.dart';

class MonthlyOverviewCard extends StatefulWidget {
  final String month;
  final String expense;
  final String income;
  final String balance;
  final VoidCallback? onTap;

  const MonthlyOverviewCard({
    super.key,
    required this.month,
    required this.expense,
    required this.income,
    required this.balance,
    this.onTap,
  });

  @override
  State<MonthlyOverviewCard> createState() => _MonthlyOverviewCardState();
}

class _MonthlyOverviewCardState extends State<MonthlyOverviewCard> {
  bool _isVisible = true;

  String _maskAmount(String amount) {
    if (_isVisible) return amount;
    return '****';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0ba360),
                Color(0xFF3cba92),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '${widget.month}支出',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isVisible = !_isVisible;
                          });
                        },
                        child: Icon(
                          _isVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  // if (widget.onTap != null)
                  // Row(
                  //   children: [
                  //     Text(
                  //       '查看详情',
                  //       style: const TextStyle(
                  //         fontSize: 12,
                  //         color: Colors.white70,
                  //       ),
                  //     ),
                  //     const SizedBox(width: 4),
                  //     Icon(
                  //       Icons.chevron_right,
                  //       color: Colors.white70,
                  //       size: 16,
                  //     ),
                  //   ],
                  // ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _maskAmount(widget.expense),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildMonthlyItem('本月收入', widget.income),
                  const SizedBox(width: 16),
                  _buildMonthlyItem('本月结余', widget.balance),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyItem(String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _maskAmount(amount),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
