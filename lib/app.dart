import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/app_dependencies.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/views/admin_dashboard.dart';
import 'features/auth/presentation/cubit/session_cubit.dart';
import 'features/auth/presentation/views/auth_gate_screen.dart';
import 'features/auth/presentation/views/login_screen.dart';
import 'features/teacher/presentation/views/teacher_home_page.dart';

class HasanahApp extends StatefulWidget {
  const HasanahApp({super.key});

  @override
  State<HasanahApp> createState() => _HasanahAppState();
}

class _HasanahAppState extends State<HasanahApp> {
  late final AppDependencies _dependencies;
  late final SessionCubit _sessionCubit;

  @override
  void initState() {
    super.initState();
    _dependencies = AppDependencies.create();
    _sessionCubit = _dependencies.sessionCubit;
    _sessionCubit.restore();
  }

  @override
  void dispose() {
    _sessionCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _sessionCubit,
      child: MaterialApp(
        title: 'حَسَنَة',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AuthGateScreen(
          sessionCubit: _sessionCubit,
          loginBuilder: (_) => LoginScreen(sessionCubit: _sessionCubit),
          adminBuilder: (_) => AdminDashboard(
            adminCubit: _dependencies.createAdminCubit(),
            onSignOut: () => _sessionCubit.signOut(),
          ),
          teacherBuilder: (_) {
            final user = _sessionCubit.state!;
            return TeacherHomePage(
              teacher: user,
              bootstrapCubit: _dependencies.createTeacherBootstrapCubit(),
              createWorkspaceCubit: _dependencies.createTeacherWorkspaceCubit,
              onSignOut: () => _sessionCubit.signOut(),
            );
          },
          unauthorizedBuilder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('غير مصرح'),
              actions: [
                IconButton(
                  onPressed: () => _sessionCubit.signOut(),
                  icon: const Icon(Icons.logout_outlined),
                ),
              ],
            ),
            body: const Center(
              child: Text(
                'التطبيق متاح حالياً للمدير والشيخ فقط.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
