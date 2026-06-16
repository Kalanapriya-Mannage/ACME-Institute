// import 'package:flutter/material.dart';
// import '../../core/router/app_router.dart';
// import '../../shared/widgets/purple_gradient_header.dart';

// class RoleSelectionScreen extends StatelessWidget {
//   const RoleSelectionScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(children: [
//         const PurpleGradientHeader(title: 'ACME Institute', subtitle: 'Select your role'),
//         const SizedBox(height: 24),
//         for (final role in ['student', 'teacher', 'admin'])
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () => Navigator.pushNamed(context, AppRouter.login, arguments: role),
//                 child: Text('Login as ${role[0].toUpperCase()}${role.substring(1)}'),
//               ),
//             ),
//           ),
//       ]),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/purple_gradient_header.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const _roles = [
    {
      'key': 'student',
      'label': 'Student',
      'subtitle': 'Access classes, timetable & results',
      'icon': Icons.school_outlined,
    },
    {
      'key': 'teacher',
      'label': 'Teacher',
      'subtitle': 'Manage classes, students & attendance',
      'icon': Icons.cast_for_education_outlined,
    },
    {
      'key': 'admin',
      'label': 'Admin',
      'subtitle': 'Institute management & settings',
      'icon': Icons.verified_user_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 249, 245, 245), // light grey background
      body: Column(
        children: [
          const PurpleGradientHeader(
            title: 'ACME Institute',
            subtitle: 'Select your portal',
            logo: AssetImage('assets/images/logo.png'),
          ),
          const SizedBox(height: 24),
          for (final role in _roles)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.login,
                  arguments: role['key'],
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon badge
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E4E9), // light purple circle
                          shape: BoxShape.circle,         // ← circle not rounded square
                        ),
                        child: Icon(
                          role['icon'] as IconData,
                          color: Color.fromARGB(255, 204, 58, 58),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role['label'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}