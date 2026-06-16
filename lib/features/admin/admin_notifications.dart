import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../models/notification.dart';
import '../../shared/widgets/app_shell.dart';

class AdminNotifications extends StatefulWidget {
  const AdminNotifications({super.key});
  @override
  State<AdminNotifications> createState() => _AdminNotificationsState();
}

class _AdminNotificationsState extends State<AdminNotifications> {
  String? selectedId;

  Future<void> _confirmDelete(BuildContext context, String nId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete notification'),
        content:
            const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await FirebaseService.instance.deleteNotification(nId);
        setState(() => selectedId = null);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting notification: $e')),
        );
      }
    }
  }

  void compose() {
    final title = TextEditingController();
    final message = TextEditingController();
    String audience = 'all';
    String category = 'Special Event';

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => StatefulBuilder(
            builder: (ctx, setM) => Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Compose Announcement',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      TextField(
                          controller: title,
                          decoration:
                              const InputDecoration(labelText: 'Title')),
                      TextField(
                          controller: message,
                          maxLines: 4,
                          decoration:
                              const InputDecoration(labelText: 'Message')),
                      DropdownButtonFormField<String>(
                          value: audience,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('all')),
                            DropdownMenuItem(
                                value: 'students', child: Text('students')),
                            DropdownMenuItem(
                                value: 'teachers', child: Text('teachers'))
                          ],
                          onChanged: (v) => setM(() => audience = v ?? 'all'),
                          decoration: const InputDecoration(
                              labelText: 'Target Audience')),
                      DropdownButtonFormField<String>(
                          value: category,
                          items: const [
                            DropdownMenuItem(
                                value: 'Special Event',
                                child: Text('Special Event')),
                            DropdownMenuItem(
                                value: 'Payment', child: Text('Payment')),
                            DropdownMenuItem(
                                value: 'Class Update',
                                child: Text('Class Update'))
                          ],
                          onChanged: (v) =>
                              setM(() => category = v ?? 'Special Event'),
                          decoration:
                              const InputDecoration(labelText: 'Category')),
                      const SizedBox(height: 8),
                      ElevatedButton(
                          onPressed: () async {
                            if (title.text.trim().isEmpty ||
                                message.text.trim().isEmpty) return;
                            try {
                              await FirebaseService.instance.sendNotification(
                                title: title.text.trim(),
                                message: message.text.trim(),
                                category: category,
                                targetAudience: audience,
                                sentBy: 'admin', // You might want to get the actual admin ID
                              );
                              Navigator.pop(context);
                              setState(() {});
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error sending notification: $e')),
                              );
                            }
                          },
                          child: const Text('Send Announcement'))
                    ]),
                  ),
                )));
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Announcements',
      subtitle: 'Manage and send notifications',
      floating: FloatingActionButton(
          onPressed: compose,
          backgroundColor: const Color(0xFFFF1800),
          child: const Icon(Icons.add)),
      body: StreamBuilder<List<NotificationModel>>(
        stream: FirebaseService.instance.getAllNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;
          final selected = notifications.where((n) => n.nId == selectedId).isEmpty
              ? null
              : notifications.firstWhere((n) => n.nId == selectedId);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: selected != null
                ? SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: Card(
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () =>
                                        setState(() => selectedId = null),
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Back to list'),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () {
                                      if (selected != null) {
                                        _confirmDelete(context, selected.nId);
                                      }
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Delete notification',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(selected.category,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(selected.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 22)),
                              const SizedBox(height: 12),
                              Text(selected.message,
                                  style:
                                      const TextStyle(fontSize: 16, height: 1.5)),
                              const SizedBox(height: 12),
                              Text('To: ${selected.targetAudience}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: notifications.length,
                    itemBuilder: (_, i) {
                      final notification = notifications[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const Icon(Icons.notifications),
                          title: Text(notification.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification.message,
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(
                                  'To: ${notification.targetAudience} | ${notification.category}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          onTap: () => setState(() => selectedId = notification.nId),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
