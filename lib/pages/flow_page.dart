import 'package:flutter/material.dart';

class FlowPage extends StatelessWidget {
  const FlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('流水'),
      ),
      body: const Center(
        child: Text('Flow Page Content'),
      ),
    );
  }
}
