import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../models/admin.dart';
import '../../services/firebase_service.dart';
import '../../shared/widgets/app_shell.dart';

class AdminProfile extends StatelessWidget {
  const AdminProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profileId = auth.currentUser?.profileId;

    return FutureBuilder<Admin?>(
      future: profileId == null ? Future.value(null) : FirebaseService.instance.getAdminById(profileId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final admin = snapshot.data;
        if (admin == null) return const Scaffold(body: Center(child: Text('Admin not found')));

        return AppShell(
          title: 'Admin Profile',
          body: ListView(padding: const EdgeInsets.all(16), children: [
            const Center(child: CircleAvatar(radius: 56, backgroundColor: Color(0xFFD4D5D7), child: Text('AD', style: TextStyle(color: Color(0xFFFF1800), fontWeight: FontWeight.bold, fontSize: 28)))),
            const SizedBox(height: 8),
            Center(child: Text(admin.aName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22))),
            const SizedBox(height: 10),
            Card(child: ListTile(title: const Text('Email'), trailing: Text(admin.aEmail))),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.pushNamedAndRemoveUntil(context, AppRouter.roleSelection, (_) => false);
              },
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              child: const Padding(padding: EdgeInsets.all(12), child: Text('Log Out', style: TextStyle(color: Colors.red))),
            )
          ]),
        );
      },
    );
  }
}
