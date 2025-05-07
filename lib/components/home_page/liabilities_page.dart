import 'package:flutter/material.dart';

class LiabilitiesPage extends StatelessWidget {
  const LiabilitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.credit_card_outlined, size: 48),
          const SizedBox(height: 16),
          Text(
            '负债',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}
