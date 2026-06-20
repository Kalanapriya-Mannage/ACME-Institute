import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Logout',
      onPressed: () {
        context.read<AuthProvider>().logout();
        Navigator.pushNamedAndRemoveUntil(context, AppRouter.roleSelection, (_) => false);
      },
      icon: const Icon(Icons.logout),
    );
  }
}
