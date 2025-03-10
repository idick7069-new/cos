import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text("管理")),
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0), child: Column(
            children: [

            ],
          ))),
    );
  }
}
