import 'package:flutter/material.dart';

class BottomInputToolbar extends StatelessWidget {
  final String date;
  final TextEditingController noteController;
  final VoidCallback onDateTap;

  const BottomInputToolbar({
    Key? key,
    required this.date,
    required this.noteController,
    required this.onDateTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 备注输入框
          Expanded(
            child: TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: '添加备注',
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 日期按钮
          TextButton(
            onPressed: onDateTap,
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
