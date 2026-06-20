// import 'package:flutter/material.dart';

// class PurpleGradientHeader extends StatelessWidget {
//   final String title;
//   final String? subtitle;
//   const PurpleGradientHeader({super.key, required this.title, this.subtitle});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(colors: [Color(0xFFFF1800), Color.fromARGB(255, 184, 66, 66)]),
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
//           if (subtitle != null) Text(subtitle!, style: const TextStyle(color: Colors.white70)),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class PurpleGradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final ImageProvider? logo; // 👈 added

  const PurpleGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.logo, // 👈 added
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFFF1800), Color.fromARGB(255, 184, 66, 66)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // 👈 changed to center
        children: [
          if (logo != null) // 👈 added logo block
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Image(
                image: logo!,
                height: 64,
                width: 64,
                fit: BoxFit.contain,
              ),
            ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w900,),
            ),
        ],
      ),
    );
  }
}