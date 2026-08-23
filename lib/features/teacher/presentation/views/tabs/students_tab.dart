import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/circle_session_entities.dart';
import '../../cubit/circle_session_cubit.dart';

class StudentsTab extends StatelessWidget {
  const StudentsTab({
    required this.circleId,
    required this.circleName,
    required this.teacherId,
    required this.teacherName,
    super.key,
  });

  final String circleId;
  final String circleName;
  final String teacherId;
  final String teacherName;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CircleSessionCubit, CircleSessionState>(
      builder: (context, state) {
        if (state.status == CircleSessionUiStatus.loading &&
            state.students.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final pending = state.studentRequests
            .where((r) => r.status == StudentRequestStatus.pending)
            .toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: () => _requestStudent(context),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('طلب إضافة طالب'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'يُرسل الطلب للمدير، ولا يُضاف الطالب إلا بعد الموافقة.',
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'طلبات بانتظار الموافقة',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final req in pending)
                Card(
                  color: const Color(0xFFFFF8E1),
                  child: ListTile(
                    title: Text(req.studentName),
                    subtitle: const Text('بانتظار موافقة المدير'),
                    leading: const Icon(Icons.hourglass_top),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Text(
              'طلاب الحلقة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (state.students.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('لا يوجد طلاب في هذه الحلقة.'),
              )
            else
              for (final student in state.students)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          HasanahColors.primary.withValues(alpha: 0.12),
                      foregroundColor: HasanahColors.primary,
                      child: Text(
                        student.name.isEmpty ? '?' : student.name[0],
                      ),
                    ),
                    title: Text(
                      student.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${state.studentPoints[student.id] ?? 0} نقطة',
                    ),
                    trailing: IconButton(
                      tooltip: 'إزالة من الحلقة',
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('تأكيد'),
                            content: Text('إزالة ${student.name} من الحلقة؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('إلغاء'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('إزالة'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          context
                              .read<CircleSessionCubit>()
                              .removeStudentFromCircle(
                                circleId: circleId,
                                studentId: student.id,
                              );
                        }
                      },
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Future<void> _requestStudent(BuildContext context) async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('طلب إضافة طالب'),
        content: TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'الاسم الثلاثي'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إرسال للمدير'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<CircleSessionCubit>().requestAddStudent(
      circleId: circleId,
      circleName: circleName,
      teacherId: teacherId,
      teacherName: teacherName,
      studentName: name.text,
    );
  }
}
