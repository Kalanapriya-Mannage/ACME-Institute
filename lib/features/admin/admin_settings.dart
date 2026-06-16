import 'package:flutter/material.dart';
import '../../shared/widgets/app_shell.dart';

class AdminSettings extends StatelessWidget {
  const AdminSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Admin settings will appear here. You can manage app preferences, account options, and notification settings from this screen.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
