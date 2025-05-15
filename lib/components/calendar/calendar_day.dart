import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For NumberFormat

class CalendarDay extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final double? income;
  final double? expense;

  const CalendarDay({
    super.key,
    required this.day,
    this.isToday = false,
    this.isSelected = false,
    this.income,
    this.expense,
  });

  String _formatCompactCurrency(double value) {
    if (value == 0) return '¥0';
    return NumberFormat.compactCurrency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: 0, // No decimal places for compact view
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasIncome = income != null && income! > 0;
    final bool hasExpense = expense != null && expense! > 0;

    return Container(
        margin: const EdgeInsets.all(2.0), // Reduced margin for more space
        width: 50,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(4.0),
          border: isSelected
              ? Border.all(color: Colors.green[300]!, width: 1.5)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.0), // Padding inside the cell
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.green[700]
                      : (isToday ? Colors.blue[700] : Colors.black87),
                ),
              ),
              if (hasIncome || hasExpense)
                const SizedBox(height: 2), // Spacing between day and amounts
              if (hasIncome)
                Text(
                  '+' + _formatCompactCurrency(income!),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              if (hasExpense)
                Text(
                  '-' + _formatCompactCurrency(expense!),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              // Spacer to push content up if only one of income/expense is present
              if ((hasIncome && !hasExpense) || (!hasIncome && hasExpense))
                const SizedBox(
                    height: 10.5), // Height of one text line + padding

              // Indicator for 'today' - a small dot below everything if not selected
              if (isToday && !isSelected)
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ));
  }
}
