import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/domain/entities/institute_entities.dart';
import '../cubit/admin_cubit.dart';
import '../services/admin_export_service.dart';
import 'tabs/admin_circles_tab.dart';
import 'tabs/admin_export_tab.dart';
import 'tabs/admin_pending_requests_tab.dart';
import 'tabs/admin_stats_tab.dart';
import 'tabs/admin_students_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    required this.adminCubit,
    this.onSignOut,
    super.key,
  });

  final AdminCubit adminCubit;
  final VoidCallback? onSignOut;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _export = const AdminExportService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    widget.adminCubit.loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    widget.adminCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.adminCubit,
      child: BlocListener<AdminCubit, AdminState>(
        listenWhen: (p, n) => p.message != n.message && n.message != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message!)));
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('لوحة المدير'),
            actions: [
              IconButton(
                tooltip: 'تحديث',
                onPressed: () => widget.adminCubit.loadAll(),
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'تسجيل الخروج',
                onPressed: widget.onSignOut,
                icon: const Icon(Icons.logout_outlined),
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabs: const [
                Tab(text: 'الطلاب'),
                Tab(text: 'طلبات الإضافة'),
                Tab(text: 'الحلقات'),
                Tab(text: 'الإحصائيات'),
                Tab(text: 'استيراد/تصدير'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              AdminStudentsTab(
                onAdd: () => _showStudentDialog(context),
                onEdit: (s) => _showStudentDialog(context, existing: s),
              ),
              const AdminPendingRequestsTab(),
              AdminCirclesTab(
                onAddCircle: () => _showCircleDialog(context),
                onEditCircle: (c) => _showCircleDialog(context, existing: c),
                onAddSheikh: () => _showSheikhDialog(context),
                onEditSheikh: (t) => _showSheikhDialog(context, existing: t),
              ),
              const AdminStatsTab(),
              AdminExportTab(
                onExportExcel: _exportExcel,
                onExportPdf: _exportPdf,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showStudentDialog(
    BuildContext context, {
    InstituteUser? existing,
  }) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'إضافة طالب' : 'تعديل طالب'),
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
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final now = DateTime.now().toUtc();
    await widget.adminCubit.saveStudent(
      InstituteUser(
        id: existing?.id ?? 'student-${now.millisecondsSinceEpoch}',
        name: name.text.trim(),
        role: UserRole.student,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        totalPoints: existing?.totalPoints ?? 0,
      ),
    );
  }

  Future<void> _showSheikhDialog(
    BuildContext context, {
    InstituteUser? existing,
  }) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final password = TextEditingController(text: existing?.password ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'إضافة شيخ' : 'تعديل شيخ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'اسم الشيخ'),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (name.text.trim().isEmpty || password.text.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل اسم الشيخ وكلمة المرور.')),
      );
      return;
    }
    final now = DateTime.now().toUtc();
    await widget.adminCubit.saveTeacher(
      InstituteUser(
        id: existing?.id ?? 'teacher-${now.millisecondsSinceEpoch}',
        name: name.text.trim(),
        password: password.text,
        role: UserRole.teacher,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _showCircleDialog(
    BuildContext context, {
    Circle? existing,
  }) async {
    final state = widget.adminCubit.state;
    if (state.teachers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف شيخاً أولاً قبل إنشاء حلقة.')),
      );
      return;
    }
    final name = TextEditingController(text: existing?.name ?? '');
    var teacherId = existing?.teacherId ?? state.teachers.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'إضافة حلقة' : 'تعديل حلقة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'اسم الحلقة'),
            ),
            DropdownButtonFormField<String>(
              initialValue: teacherId,
              items: [
                for (final t in state.teachers)
                  DropdownMenuItem(value: t.id, child: Text(t.name)),
              ],
              onChanged: (v) => teacherId = v ?? teacherId,
              decoration: const InputDecoration(labelText: 'الشيخ'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final now = DateTime.now().toUtc();
    await widget.adminCubit.saveCircle(
      Circle(
        id: existing?.id ?? 'circle-${now.millisecondsSinceEpoch}',
        name: name.text.trim(),
        teacherId: teacherId,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _exportExcel() async {
    final rows = widget.adminCubit.state.stats;
    final bytes = _export.exportStudentsExcel(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/hasanah_stats.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );
  }

  Future<void> _exportPdf() async {
    final bytes = await _export.exportStatsPdf(widget.adminCubit.state.stats);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}
