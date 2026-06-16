import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../models/payment.dart';
import '../../services/firebase_service.dart';
import '../../shared/widgets/app_shell.dart';

class AdminPayment extends StatefulWidget {
  const AdminPayment({super.key});

  @override
  State<AdminPayment> createState() => _AdminPaymentState();
}

class _AdminPaymentState extends State<AdminPayment> {
  String _filter = 'All';

  List<PaymentModel> _applyFilter(List<PaymentModel> payments) {
    switch (_filter) {
      case 'Online':
        return payments.where((p) => p.paymentType == 'online').toList();
      case 'Physical':
        return payments.where((p) => p.paymentType == 'physical').toList();
      case 'Pending':
        return payments.where((p) => p.status == 'pending').toList();
      case 'Paid':
        return payments.where((p) => p.status == 'paid').toList();
      default:
        return payments;
    }
  }

  Future<void> _markPaid(PaymentModel payment) async {
    final admin = context.read<AuthProvider>().currentUser;
    final adminId = admin?.profileId;
    if (adminId == null) return;
    try {
      if (payment.payId.trim().isEmpty) throw Exception('Invalid payment id');
      await FirebaseService.instance.adminMarkPaymentPaid(
        payId: payment.payId,
        adminAId: adminId,
        enrId: payment.enrId,
        sId: payment.sId,
        subId: payment.subId,
        subName: payment.subName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment marked as paid!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking payment paid: $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Widget _filterChip(String label) {
    final selected = _filter == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Payments Overview',
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: Color(0xFFFF1800),
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'Pending Physical'),
                Tab(text: 'Payment History'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  StreamBuilder<List<PaymentModel>>(
                    stream: FirebaseService.instance.getPendingPhysicalPayments(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final payments = snapshot.data ?? [];
                      if (payments.isEmpty) {
                        return const Center(child: Text('No pending physical payments found.'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final payment = payments[index];
                          return Card(
                            child: ListTile(
                              isThreeLine: true,
                              title: Text(payment.sName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(payment.subName, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Amount: ${payment.amount} • ${payment.month == 'enrollment' ? 'Enrollment' : payment.month}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: payment.status == 'paid'
                                    ? null
                                    : () => _markPaid(payment),
                                child: const Text('Mark as Paid'),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  StreamBuilder<List<PaymentModel>>(
                    stream: FirebaseService.instance.getAllPayments(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final payments = _applyFilter(snapshot.data ?? []);
                      return Column(
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _filterChip('All'),
                                const SizedBox(width: 8),
                                _filterChip('Online'),
                                const SizedBox(width: 8),
                                _filterChip('Physical'),
                                const SizedBox(width: 8),
                                _filterChip('Pending'),
                                const SizedBox(width: 8),
                                _filterChip('Paid'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: payments.isEmpty
                                ? const Center(child: Text('No payments found for this filter.'))
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: payments.length,
                                    itemBuilder: (context, index) {
                                      final payment = payments[index];
                                      return Card(
                                        child: ListTile(
                                          title: Text('${payment.sName} • ${payment.subName}'),
                                          subtitle: Text('Amount: ${payment.amount} • ${payment.paymentType}'),
                                          trailing: Text(
                                            payment.status.toUpperCase(),
                                            style: TextStyle(
                                              color: payment.status == 'paid' ? Colors.green : Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
