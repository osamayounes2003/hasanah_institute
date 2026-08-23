import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/admin_cubit.dart';

class AdminPendingRequestsTab extends StatelessWidget {
  const AdminPendingRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        final requests = state.pendingRequests;
        if (requests.isEmpty) {
          return const Center(
            child: Text('لا توجد طلبات إضافة طلاب بانتظار الموافقة.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return Card(
              child: ListTile(
                title: Text(req.studentName),
                subtitle: Text(
                  'الحلقة: ${req.circleName ?? req.circleId}\n'
                  'الشيخ: ${req.teacherName ?? req.teacherId}',
                ),
                isThreeLine: true,
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'موافقة',
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => context
                          .read<AdminCubit>()
                          .approveStudentRequest(req.id),
                    ),
                    IconButton(
                      tooltip: 'رفض',
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => context
                          .read<AdminCubit>()
                          .rejectStudentRequest(req.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
