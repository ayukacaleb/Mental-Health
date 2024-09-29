import 'package:flutter/material.dart';

class LocalSupportGroups extends StatelessWidget {
  const LocalSupportGroups({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Support Groups')),
      body: const Center(child: Text('List of Local Support Groups')),
    );
  }
}
