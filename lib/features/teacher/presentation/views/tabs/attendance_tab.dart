import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../cubit/circle_session_cubit.dart';

class AttendanceTab extends StatelessWidget {
  const AttendanceTab({
    required this.circleId,
    required this.presentIds,
    required this.onToggle,
    super.key,
  });

  final String circleId;
  final Set<String> presentIds;
  final void Function(String studentId, bool present) onToggle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CircleSessionCubit, CircleSessionState>(
      builder: (context, state) {
        final isOpen = state.session?.isOpen == true;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('الحضور', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'حدد الحاضرين ثم احفظ مرة واحدة في اليوم. كل حاضر يحصل على نقطة واحدة.',
            ),
            const SizedBox(height: 12),
            if (!isOpen)
              const Card(
                color: Color(0xFFFFF7ED),
                child: ListTile(
                  leading: Icon(Icons.info_outline, color: HasanahColors.warning),
                  title: Text('الجلسة منتهية'),
                  subtitle: Text('أعد فتح جلسة من قائمة الجلسات لتسجيل الحضور.'),
                ),
              ),
            ...state.students.map(
              (student) => CheckboxListTile(
                value: presentIds.contains(student.id),
                onChanged: isOpen
                    ? (checked) => onToggle(student.id, checked ?? false)
                    : null,
                title: Text(student.name),
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isOpen
                  ? () => context.read<CircleSessionCubit>().saveAttendance(
                        circleId: circleId,
                        presentStudentIds: presentIds,
                      )
                  : null,
              child: const Text('حفظ الحضور لليوم'),
            ),
          ],
        );
      },
    );
  }
}
