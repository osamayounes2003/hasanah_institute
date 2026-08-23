import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/entities/institute_entities.dart';
import '../cubit/circle_session_cubit.dart';
import '../cubit/teacher_bootstrap_cubit.dart';
import 'teacher_console.dart';

/// Entry point for teacher role: resolves circle via Cubit, then opens console.
class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({
    required this.teacher,
    required this.bootstrapCubit,
    required this.createWorkspaceCubit,
    required this.onSignOut,
    super.key,
  });

  final InstituteUser teacher;
  final TeacherBootstrapCubit bootstrapCubit;
  final CircleSessionCubit Function() createWorkspaceCubit;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bootstrapCubit..load(teacher.id),
      child: BlocBuilder<TeacherBootstrapCubit, TeacherBootstrapState>(
        builder: (context, state) {
          switch (state.status) {
            case TeacherBootstrapStatus.initial:
            case TeacherBootstrapStatus.loading:
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            case TeacherBootstrapStatus.failure:
            case TeacherBootstrapStatus.empty:
              return Scaffold(
                appBar: AppBar(
                  title: const Text('لوحة الشيخ'),
                  actions: [
                    IconButton(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout_outlined),
                    ),
                  ],
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.message ??
                          'لم تُسند إليك حلقة بعد. تواصل مع المدير لإضافة حلقة وربطها بحسابك.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            case TeacherBootstrapStatus.ready:
              final circle = state.circle!;
              return TeacherConsole(
                circleId: circle.id,
                circleName: circle.name,
                teacherId: teacher.id,
                teacherName: teacher.name,
                circleSessionCubit: createWorkspaceCubit(),
                onSignOut: onSignOut,
              );
          }
        },
      ),
    );
  }
}
