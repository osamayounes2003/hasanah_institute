import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/circle_session_entities.dart';
import '../../cubit/circle_session_cubit.dart';

class HonorBoardTab extends StatelessWidget {
  const HonorBoardTab({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CircleSessionCubit, CircleSessionState>(
      builder: (context, state) {
        final periodHint = switch (state.honorPeriod) {
          HonorPeriod.daily => state.session?.isOpen == true
              ? 'الترتيب حسب نقاط الجلسة المفتوحة فقط.'
              : 'لا توجد جلسة مفتوحة — ابدأ جلسة لعرض ترتيب اليوم.',
          HonorPeriod.weekly =>
            'ترتيب تراكمي لجميع جلسات هذا الأسبوع (توقيت سوريا).',
          HonorPeriod.monthly =>
            'ترتيب تراكمي لجميع جلسات هذا الشهر (توقيت سوريا).',
        };

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'لوحة الشرف',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              periodHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SegmentedButton<HonorPeriod>(
              segments: const [
                ButtonSegment(value: HonorPeriod.daily, label: Text('يومي')),
                ButtonSegment(value: HonorPeriod.weekly, label: Text('أسبوعي')),
                ButtonSegment(value: HonorPeriod.monthly, label: Text('شهري')),
              ],
              selected: {state.honorPeriod},
              onSelectionChanged: (value) {
                context.read<CircleSessionCubit>().loadHonorBoard(
                  circleId: circleId,
                  period: value.first,
                );
              },
            ),
            const SizedBox(height: 16),
            if (state.honorPeriod == HonorPeriod.daily &&
                state.honorBoard.isNotEmpty &&
                state.honorBoard.first.totalPoints > 0)
              Card(
                color: const Color(0xFFFFF8E1),
                child: ListTile(
                  leading: const Icon(
                    Icons.emoji_events,
                    color: HasanahColors.accent,
                  ),
                  title: const Text('بطل الجلسة'),
                  subtitle: Text(state.honorBoard.first.studentName),
                  trailing: Text('${state.honorBoard.first.totalPoints} نقطة'),
                ),
              ),
            for (final entry in state.honorBoard)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: HasanahColors.primary.withValues(alpha: 0.1),
                  child: Text('${entry.rank}'),
                ),
                title: Text(entry.studentName),
                trailing: Text('${entry.totalPoints} نقطة'),
              ),
            if (state.honorBoard.isEmpty ||
                state.honorBoard.every((e) => e.totalPoints == 0))
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('لا توجد نقاط مسجّلة لهذه الفترة.'),
              ),
          ],
        );
      },
    );
  }
}
