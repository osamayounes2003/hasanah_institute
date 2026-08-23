import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/entities/institute_entities.dart';
import '../cubit/session_cubit.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({
    required this.sessionCubit,
    required this.adminBuilder,
    required this.teacherBuilder,
    required this.loginBuilder,
    required this.unauthorizedBuilder,
    super.key,
  });

  final SessionCubit sessionCubit;
  final WidgetBuilder adminBuilder;
  final WidgetBuilder teacherBuilder;
  final WidgetBuilder loginBuilder;
  final WidgetBuilder unauthorizedBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sessionCubit,
      child: BlocBuilder<SessionCubit, InstituteUser?>(
        builder: (context, user) {
          if (user == null) return loginBuilder(context);
          return switch (user.role) {
            UserRole.admin => adminBuilder(context),
            UserRole.teacher => teacherBuilder(context),
            UserRole.student || UserRole.parent => unauthorizedBuilder(context),
          };
        },
      ),
    );
  }
}
