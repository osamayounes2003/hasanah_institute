import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/syria_time.dart';
import '../../../shared/domain/entities/institute_entities.dart';
import '../../domain/entities/circle_session_entities.dart';
import '../cubit/circle_session_cubit.dart';

class SessionsManagementTab extends StatefulWidget {
  const SessionsManagementTab({required this.circleId, super.key});

  final String circleId;

  @override
  State<SessionsManagementTab> createState() => _SessionsManagementTabState();
}

class _SessionsManagementTabState extends State<SessionsManagementTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CircleSessionCubit>().ensureSessionReports(widget.circleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final circleId = widget.circleId;
    return BlocBuilder<CircleSessionCubit, CircleSessionState>(
      builder: (context, state) {
        final reports = state.sessionReports;
        return RefreshIndicator(
          onRefresh: () =>
              context.read<CircleSessionCubit>().loadSessionReports(circleId),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'إدارة الجلسات',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'اضغط «تعديل» لتحديد بداية ونهاية الجلسة والدرس ونسبة النجاح، ثم «حفظ».',
              ),
              const SizedBox(height: 12),
              if (reports.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('لا توجد جلسات مسجّلة بعد.')),
                )
              else
                for (final report in reports)
                  _SessionReportCard(circleId: circleId, report: report),
            ],
          ),
        );
      },
    );
  }
}

class _SessionReportCard extends StatelessWidget {
  const _SessionReportCard({required this.circleId, required this.report});

  final String circleId;
  final SessionReport report;

  @override
  Widget build(BuildContext context) {
    final session = report.session;
    final present = report.presentStudents;
    final lesson = (session.lessonTitle == null || session.lessonTitle!.isEmpty)
        ? 'غير محدد'
        : session.lessonTitle!;
    final rate = session.successRate.clamp(0, 100);
    final startLabel = _dateLabel(session.startedAt);
    final endLabel = session.endedAt == null || session.endedAt!.isEmpty
        ? 'غير محدد'
        : _dateLabel(session.endedAt!);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'جلسة ${SyriaTime.display(session.startedAt)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(session.isOpen ? 'مفتوحة' : 'منتهية'),
                  backgroundColor: session.isOpen
                      ? HasanahColors.success.withValues(alpha: 0.15)
                      : Colors.grey.shade200,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('البداية: $startLabel'),
            const SizedBox(height: 4),
            Text('النهاية: $endLabel'),
            const SizedBox(height: 4),
            Text('الدرس: $lesson'),
            const SizedBox(height: 4),
            Text('نسبة النجاح: $rate%'),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => _editSession(context),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل'),
              ),
            ),
            const Divider(),
            Text(
              'الحاضرون (${present.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (present.isEmpty)
              const Text('لا يوجد حضور مسجّل.')
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in present)
                    Chip(
                      avatar: const Icon(Icons.check_circle, size: 16),
                      label: Text(a.studentName),
                    ),
                ],
              ),
            if (report.attendees.any(
              (a) => a.status != AttendanceStatus.present,
            )) ...[
              const SizedBox(height: 8),
              Text(
                'الغائبون',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in report.attendees.where(
                    (x) => x.status != AttendanceStatus.present,
                  ))
                    Chip(
                      avatar: const Icon(Icons.cancel_outlined, size: 16),
                      label: Text(a.studentName),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'عداد النقاط',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (report.studentPointTotals.isEmpty)
              const Text('لا طلاب في هذه الجلسة بعد.')
            else
              for (final row in report.studentPointTotals)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(row.studentName),
                  trailing: Text(
                    '${row.points}',
                    style: const TextStyle(
                      color: HasanahColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(String raw) => SyriaTime.display(raw);

  DateTime _parseDate(String? raw, {DateTime? fallback}) {
    final base = fallback ?? DateTime.now();
    if (raw == null || raw.isEmpty) return DateTime(base.year, base.month, base.day);
    try {
      final parsed = DateTime.parse(raw);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      if (raw.length >= 10) {
        try {
          final parsed = DateTime.parse(raw.substring(0, 10));
          return DateTime(parsed.year, parsed.month, parsed.day);
        } catch (_) {}
      }
      return DateTime(base.year, base.month, base.day);
    }
  }

  String _encodeDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _editSession(BuildContext context) async {
    final session = report.session;
    final lessonController = TextEditingController(
      text: session.lessonTitle ?? '',
    );
    var rate = session.successRate.clamp(0, 100).toDouble();
    var startDate = _parseDate(session.startedAt.isNotEmpty
        ? session.startedAt
        : session.sessionDate);
    DateTime? endDate = session.endedAt == null || session.endedAt!.isEmpty
        ? null
        : _parseDate(session.endedAt);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Future<void> pickStart() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: startDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              helpText: 'تاريخ بداية الجلسة',
              cancelText: 'إلغاء',
              confirmText: 'اختيار',
            );
            if (picked == null) return;
            setLocal(() {
              startDate = DateTime(picked.year, picked.month, picked.day);
              if (endDate != null && endDate!.isBefore(startDate)) {
                endDate = startDate;
              }
            });
          }

          Future<void> pickEnd() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: endDate ?? startDate,
              firstDate: startDate,
              lastDate: DateTime(2100),
              helpText: 'تاريخ نهاية الجلسة',
              cancelText: 'إلغاء',
              confirmText: 'اختيار',
            );
            if (picked == null) return;
            setLocal(() {
              endDate = DateTime(picked.year, picked.month, picked.day);
            });
          }

          return AlertDialog(
            title: Text('تعديل جلسة ${SyriaTime.display(session.startedAt)}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تاريخ البداية'),
                    subtitle: Text(_encodeDate(startDate)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: pickStart,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تاريخ النهاية'),
                    subtitle: Text(
                      endDate == null ? 'غير محدد' : _encodeDate(endDate!),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (endDate != null)
                          IconButton(
                            tooltip: 'مسح النهاية',
                            onPressed: () => setLocal(() => endDate = null),
                            icon: const Icon(Icons.clear),
                          ),
                        const Icon(Icons.event_outlined),
                      ],
                    ),
                    onTap: pickEnd,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: lessonController,
                    decoration: const InputDecoration(
                      labelText: 'الدرس الذي أُعطي في الجلسة',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('نسبة النجاح: ${rate.round()}%'),
                  ),
                  Slider(
                    value: rate,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${rate.round()}%',
                    onChanged: (v) => setLocal(() => rate = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (endDate != null && endDate!.isBefore(startDate)) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تاريخ النهاية يجب أن يكون بعد البداية أو مساوياً له.',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );

    if (ok == true && context.mounted) {
      await context.read<CircleSessionCubit>().updateSessionMeta(
        circleId: circleId,
        sessionId: session.id,
        lessonTitle: lessonController.text.trim(),
        successRate: rate.round(),
        startedAt: _encodeDate(startDate),
        endedAt: endDate == null ? null : _encodeDate(endDate!),
      );
    }
    lessonController.dispose();
  }
}
