import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/admin_cubit.dart';

class AdminStatsTab extends StatelessWidget {
  const AdminStatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        if (state.stats.isEmpty) {
          return const Center(child: Text('لا توجد إحصائيات نقاط بعد.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.stats.length,
          itemBuilder: (_, i) {
            final row = state.stats[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text('${row['name']}'),
                trailing: Text('${row['points']} نقطة'),
              ),
            );
          },
        );
      },
    );
  }
}
