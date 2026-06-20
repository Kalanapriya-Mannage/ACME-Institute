import 'package:flutter/material.dart';

class StudentAvatar extends StatelessWidget {
  final String sId;
  final double radius;

  const StudentAvatar({super.key, required this.sId, this.radius = 24});

  String get _assetPath => 'assets/students/$sId.png';

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFD4D5D7),
      child: ClipOval(
        child: Image.asset(
          _assetPath,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
