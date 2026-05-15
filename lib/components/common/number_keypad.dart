import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';

const cellRed = Color(0xffc73232);
const cellMustard = Color(0xffd7aa22);
const cellGrey = Color(0xffcfd4e0);
const cellBlue = Color(0xff1553be);
const background = Color(0xff242830);

class NumberKeypad extends StatelessWidget {
  final Function(String) onKeyPressed;

  const NumberKeypad({
    super.key,
    required this.onKeyPressed,
  });

  Widget _buildKeypadButton(
    String value, {
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final bgColor = backgroundColor ?? Colors.white;
    final fgColor = foregroundColor ?? Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => onKeyPressed(value),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, size: 24, color: fgColor)
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: fgColor,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FB),
      ),
      child: LayoutGrid(
        columnGap: 6,
        rowGap: 6,
        areas: '''
          1 2 3 b
          4 5 6 +
          7 8 9 -
          0 d = s
        ''',
        // A number of extension methods are provided for concise track sizing
        columnSizes: [1.0.fr, 1.0.fr, 1.0.fr, 1.0.fr],
        rowSizes: [
          1.0.fr,
          1.0.fr,
          1.0.fr,
          1.0.fr,
        ],
        children: [
          // Row 1
          gridArea('1').containing(_buildKeypadButton('1')),
          gridArea('2').containing(_buildKeypadButton('2')),
          gridArea('3').containing(_buildKeypadButton('3')),
          gridArea('b').containing(_buildKeypadButton('⌫',
              icon: Icons.backspace_outlined,
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87)),

          // Row 2
          gridArea('4').containing(_buildKeypadButton('4')),
          gridArea('5').containing(_buildKeypadButton('5')),
          gridArea('6').containing(_buildKeypadButton('6')),
          gridArea('+').containing(_buildKeypadButton('+',
              icon: Icons.add,
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87)),

          // Row 3
          gridArea('7').containing(_buildKeypadButton('7')),
          gridArea('8').containing(_buildKeypadButton('8')),
          gridArea('9').containing(_buildKeypadButton('9')),
          gridArea('-').containing(_buildKeypadButton('-',
              icon: Icons.remove,
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87)),

          // Row 4
          gridArea('0').containing(_buildKeypadButton('0')),
          gridArea('d').containing(_buildKeypadButton('.')),
          gridArea('=').containing(_buildKeypadButton('=',
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87)),
          gridArea('s').containing(_buildKeypadButton('确定',
              backgroundColor: Colors.green, foregroundColor: Colors.white)),
        ],
      ),
    );
  }
}
