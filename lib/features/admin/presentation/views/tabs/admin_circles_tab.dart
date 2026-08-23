import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/domain/entities/institute_entities.dart';
import '../../cubit/admin_cubit.dart';
import '../../widgets/admin_confirm_dialog.dart';

class AdminCirclesTab extends StatelessWidget {
  const AdminCirclesTab({
    required this.onAddCircle,
    required this.onEditCircle,
    required this.onAddSheikh,
    required this.onEditSheikh,
    super.key,
  });

  final VoidCallback onAddCircle;
  final ValueChanged<Circle> onEditCircle;
  final VoidCallback onAddSheikh;
  final ValueChanged<InstituteUser> onEditSheikh;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onAddSheikh,
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('إضافة شيخ'),
                ),
                OutlinedButton.icon(
                  onPressed: onAddCircle,
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('إضافة حلقة'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('المشايخ', style: Theme.of(context).textTheme.titleMedium),
            if (state.teachers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('لا يوجد مشايخ بعد.'),
              )
            else
              for (final teacher in state.teachers)
                Card(
                  child: ListTile(
                    title: Text(teacher.name),
                    subtitle: const Text('شيخ حلقة'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'تعديل',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => onEditSheikh(teacher),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await confirmAdminDelete(
                              context,
                              'حذف الشيخ ${teacher.name}؟',
                            );
                            if (ok && context.mounted) {
                              context.read<AdminCubit>().deleteTeacher(
                                teacher.id,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            Text('الحلقات', style: Theme.of(context).textTheme.titleMedium),
            if (state.circles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('لا توجد حلقات بعد.'),
              )
            else
              for (final circle in state.circles) ...[
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        title: Text(circle.name),
                        subtitle: Text(
                          'الشيخ: ${circle.teacherName ?? _teacherName(state, circle.teacherId)}',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Wrap(
                          spacing: 4,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  _assignStudent(context, state, circle.id),
                              icon: const Icon(Icons.person_add_alt),
                              label: const Text('إسناد'),
                            ),
                            TextButton.icon(
                              onPressed: () => onEditCircle(circle),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('تعديل'),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final ok = await confirmAdminDelete(
                                  context,
                                  'حذف الحلقة ${circle.name}؟',
                                );
                                if (ok && context.mounted) {
                                  context.read<AdminCubit>().deleteCircle(
                                    circle.id,
                                  );
                                }
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('حذف'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      for (final student
                          in state.circleMembers[circle.id] ?? const [])
                        ListTile(
                          title: Text(student.name),
                          trailing: IconButton(
                            tooltip: 'إزالة من الحلقة',
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () async {
                              final ok = await confirmAdminDelete(
                                context,
                                'إزالة ${student.name} من الحلقة؟',
                              );
                              if (ok && context.mounted) {
                                context
                                    .read<AdminCubit>()
                                    .removeStudentFromCircle(
                                      circleId: circle.id,
                                      studentId: student.id,
                                    );
                              }
                            },
                          ),
                        ),
                      if ((state.circleMembers[circle.id] ?? const []).isEmpty)
                        const ListTile(title: Text('لا طلاب في هذه الحلقة.')),
                    ],
                  ),
                ),
              ],
          ],
        );
      },
    );
  }

  String _teacherName(AdminState state, String teacherId) {
    for (final teacher in state.teachers) {
      if (teacher.id == teacherId) return teacher.name;
    }
    return 'غير معيّن';
  }

  Future<void> _assignStudent(
    BuildContext context,
    AdminState state,
    String circleId,
  ) async {
    if (state.students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف طلاباً أولاً.')),
      );
      return;
    }
    String studentId = state.students.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إسناد طالب للحلقة'),
        content: DropdownButtonFormField<String>(
          initialValue: studentId,
          items: [
            for (final s in state.students)
              DropdownMenuItem(value: s.id, child: Text(s.name)),
          ],
          onChanged: (v) => studentId = v ?? studentId,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إسناد'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AdminCubit>().assignStudent(
        circleId: circleId,
        studentId: studentId,
      );
    }
  }
}
