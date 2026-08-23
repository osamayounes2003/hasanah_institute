import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/domain/entities/institute_entities.dart';
import '../../cubit/admin_cubit.dart';
import '../../widgets/admin_confirm_dialog.dart';

class AdminStudentsTab extends StatelessWidget {
  const AdminStudentsTab({
    required this.onAdd,
    required this.onEdit,
    super.key,
  });

  final VoidCallback onAdd;
  final ValueChanged<InstituteUser> onEdit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('إضافة طالب'),
              ),
            ),
            const SizedBox(height: 12),
            if (state.students.isEmpty)
              const Text('لا يوجد طلاب بعد.')
            else
              for (final student in state.students)
                Card(
                  child: ListTile(
                    title: Text(student.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'تعديل',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => onEdit(student),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await confirmAdminDelete(
                              context,
                              'حذف الطالب ${student.name}؟',
                            );
                            if (ok && context.mounted) {
                              context.read<AdminCubit>().deleteStudent(
                                student.id,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
