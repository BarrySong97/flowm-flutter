import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PageHeader({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titles = ['总览', '资产', '支出', '收入', '负债'];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
                  color:
                      currentIndex == index ? Colors.black : Colors.grey[600],
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
    );
  }
}
