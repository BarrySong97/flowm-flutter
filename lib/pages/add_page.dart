import 'package:flutter/material.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  String fromAmount = "140.00";
  String toAmount = "1014.902";
  String fromCurrency = "USD";
  String toCurrency = "CNY";
  double exchangeRate = 7.2493;
  String fromBalance = "\$150.56";
  String toBalance = "¥246.63";

  void updateToAmount() {
    if (fromAmount.isEmpty) {
      setState(() {
        toAmount = "";
      });
      return;
    }

    try {
      double amount = double.parse(fromAmount);
      setState(() {
        toAmount = (amount * exchangeRate).toStringAsFixed(3);
      });
    } catch (e) {
      setState(() {
        toAmount = "";
      });
    }
  }

  void updateFromAmount() {
    if (toAmount.isEmpty) {
      setState(() {
        fromAmount = "";
      });
      return;
    }

    try {
      double amount = double.parse(toAmount);
      setState(() {
        fromAmount = (amount / exchangeRate).toStringAsFixed(2);
      });
    } catch (e) {
      setState(() {
        fromAmount = "";
      });
    }
  }

  void onKeypadPressed(String value) {
    setState(() {
      if (value == 'backspace') {
        if (fromAmount.isNotEmpty) {
          fromAmount = fromAmount.substring(0, fromAmount.length - 1);
          if (fromAmount.isEmpty) {
            fromAmount = "0";
          }
        }
      } else if (value == '.') {
        if (!fromAmount.contains('.')) {
          fromAmount = fromAmount + value;
        }
      } else {
        if (fromAmount == "0") {
          fromAmount = value;
        } else {
          fromAmount = fromAmount + value;
        }
      }
      updateToAmount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "新的流水",
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Exchange rate chip
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

            // Currency converters
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // From currency
                    _buildCurrencyInput(
                      amount: fromAmount,
                      balance: fromBalance,
                      currency: fromCurrency,
                      flag: '🇺🇸',
                    ),

                    // Exchange button
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.swap_vert,
                        color: Colors.white,
                      ),
                    ),

                    // To currency
                    _buildCurrencyInput(
                      amount: toAmount,
                      balance: toBalance,
                      currency: toCurrency,
                      flag: '🇨🇳',
                    ),
                  ],
                ),
              ),
            ),

            // Keypad
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  // Description text field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Description',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),

                  // Horizontal list of buttons
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        _buildQuickAmountButton('50'),
                        _buildQuickAmountButton('100'),
                        _buildQuickAmountButton('200'),
                        _buildQuickAmountButton('500'),
                        _buildQuickAmountButton('1000'),
                        _buildQuickAmountButton('Max'),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildKeypadButton('1'),
                      _buildKeypadButton('2'),
                      _buildKeypadButton('3'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildKeypadButton('4'),
                      _buildKeypadButton('5'),
                      _buildKeypadButton('6'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildKeypadButton('7'),
                      _buildKeypadButton('8'),
                      _buildKeypadButton('9'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildKeypadButton('.'),
                      _buildKeypadButton('0'),
                      _buildKeypadButton(
                        'backspace',
                        icon: const Icon(Icons.backspace_outlined,
                            color: Colors.black),
                      ),
                    ],
                  ),

                  // Continue button
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyInput({
    required String amount,
    required String balance,
    required String currency,
    required String flag,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Amount
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Balance: $balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Currency selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  currency,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String value, {Widget? icon}) {
    return Expanded(
      child: InkWell(
        onTap: () => onKeypadPressed(value),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: icon ??
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: OutlinedButton(
        onPressed: () {
          if (value == 'Max') {
            setState(() {
              fromAmount = "150.00";
              updateToAmount();
            });
          } else {
            setState(() {
              fromAmount = value;
              updateToAmount();
            });
          }
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          side: const BorderSide(color: Colors.black26),
        ),
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
