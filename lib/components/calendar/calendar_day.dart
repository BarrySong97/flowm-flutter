import 'package:flutter/material.dart';

class CalendarDay extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;

  const CalendarDay({
    super.key,
    required this.day,
    this.isToday = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.green[200] : null,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isToday)
              Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 2,
                      height: 2,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(100)),
                          color: Colors.red),
                      child: Center(child: Text("")),
                    ),
                  )),
          ],
        ));
  }
}
