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
    Key? key,
    required this.onKeyPressed,
  }) : super(key: key);

  Widget _buildKeypadButton(String value,
      {bool isRed = false, IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => onKeyPressed(value),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, size: 24, color: isRed ? Colors.red : Colors.black87)
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isRed ? Colors.red : Colors.black87,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FB),
      ),
      child: LayoutGrid(
        columnGap: 2,
        rowGap: 0,
        areas: '''
          1 2 3 b
          4 5 6 +
          7 8 9 -
          0 0 p s 
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
          // Column 1
          gridArea('1').containing(_buildKeypadButton('1')),
          gridArea('4').containing(_buildKeypadButton('4')),
          gridArea('7').containing(_buildKeypadButton('7')),
          gridArea('0').containing(_buildKeypadButton('0')),
          // Column 2
          gridArea('2').containing(_buildKeypadButton('2')),
          gridArea('5').containing(_buildKeypadButton('5')),
          gridArea('8').containing(_buildKeypadButton('8')),
          gridArea('9').containing(_buildKeypadButton('.')),
          // Column 3
          gridArea('3').containing(_buildKeypadButton('3')),
          gridArea('6').containing(_buildKeypadButton('6')),
          gridArea('9').containing(_buildKeypadButton('9')),
          gridArea('p').containing(_buildKeypadButton('.')),
          // column 4
          gridArea('b').containing(
              _buildKeypadButton('backspace', icon: Icons.backspace_outlined)),
          gridArea('+').containing(_buildKeypadButton('+', icon: Icons.add)),
          gridArea('-').containing(_buildKeypadButton('-', icon: Icons.remove)),
          gridArea('s').containing(_buildKeypadButton('确定')),
        ],
      ),
    );
  }
}
