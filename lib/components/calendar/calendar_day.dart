import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For NumberFormat
import '../../config/app_constants.dart';

class CalendarDay extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final double? income;
  final double? expense;
  final String currencySymbol;

  const CalendarDay({
    super.key,
    required this.day,
    this.isToday = false,
    this.isSelected = false,
    this.income,
    this.expense,
    this.currencySymbol = AppConstants.currencySymbol,
  });

  String _formatCompactCurrency(double value) {
    if (value == 0) return '${currencySymbol}0';
    return NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '',
      decimalDigits: 2,
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
              const SizedBox(
                  height:
                      2), // Spacing between day and amounts, now unconditional
              Visibility(
                visible: hasIncome,
                maintainSize: true,
                maintainState: true,
                maintainAnimation: true,
                child: Text(
                  // Ensure income is not null before calling _formatCompactCurrency
                  // hasIncome already checks income != null
                  hasIncome ? '+' + _formatCompactCurrency(income!) : '',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Visibility(
                visible: hasExpense,
                maintainSize: true,
                maintainState: true,
                maintainAnimation: true,
                child: Text(
                  // Ensure expense is not null before calling _formatCompactCurrency
                  // hasExpense already checks expense != null
                  hasExpense ? '-' + _formatCompactCurrency(expense!) : '',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Removed conditional SizedBox for balancing single income/expense

              // Indicator for 'today' - a small dot below everything if not selected
              // if (isToday && !isSelected)
              //   Expanded(
              //     child: Align(
              //       alignment: Alignment.bottomCenter,
              //       child: Container(
              //         width: 4,
              //         height: 4,
              //         margin: const EdgeInsets.only(bottom: 2),
              //         decoration: const BoxDecoration(
              //           color: Colors.red,
              //           shape: BoxShape.circle,
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          ),
        ));
  }
}
