import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/circle_session_entities.dart';
import '../../cubit/circle_session_cubit.dart';

class PointsTab extends StatelessWidget {
  const PointsTab({
    required this.circleId,
    required this.pointsController,
    required this.selectedStudentId,
    required this.onStudentChanged,
    super.key,
  });

  final String circleId;
  final TextEditingController pointsController;
  final String? selectedStudentId;
  final ValueChanged<String?> onStudentChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CircleSessionCubit, CircleSessionState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'إدارة النقاط',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('اختر طالباً ثم أسند له عدداً من النقاط داخل الجلسة المفتوحة.'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedStudentId,
              decoration: const InputDecoration(labelText: 'الطالب'),
              items: [
                for (final student in state.students)
                  DropdownMenuItem(
                    value: student.id,
                    child: Text(
                      '${student.name} (${state.studentPoints[student.id] ?? 0})',
                    ),
                  ),
              ],
              onChanged: onStudentChanged,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد النقاط'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                final points = int.tryParse(pointsController.text.trim()) ?? 0;
                final studentId = selectedStudentId;
                if (studentId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('اختر طالباً أولاً.')),
                  );
                  return;
                }
                context.read<CircleSessionCubit>().awardPointsToStudent(
                  circleId: circleId,
                  studentId: studentId,
                  points: points,
                  reason: PointReason.award,
                  note: 'تقدير الشيخ',
                );
              },
              icon: const Icon(Icons.stars_rounded),
              label: const Text('إسناد النقاط'),
            ),
          ],
        );
      },
    );
  }
}
