import 'package:flutter/material.dart';
import 'purple_gradient_header.dart';

class AppShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? body;
  final Widget? child;
  final Widget? floating;
  const AppShell({super.key, required this.title, this.subtitle, this.body, this.child, this.floating});

  @override
  Widget build(BuildContext context) {
    final content = body ?? child ?? const SizedBox.shrink();
    return Scaffold(
      backgroundColor: const Color(0xFFE5E4E9),
      body: SafeArea(
        child: Column(children: [
          Stack(children: [
            PurpleGradientHeader(title: title, subtitle: subtitle),
            Positioned(left: 4, top: 2, child: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back, color: Colors.white))),
          ]),
          Expanded(child: content),
        ]),
      ),
      floatingActionButton: floating,
    );
  }
}
