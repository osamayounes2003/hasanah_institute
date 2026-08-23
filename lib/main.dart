import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/firebase/firestore_bootstrap.dart';
import 'core/presentation/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Never block the first Flutter frame on network/Firestore.
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  _BootPhase _phase = _BootPhase.loading;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _phase = _BootPhase.loading;
      _error = null;
    });

    // Keep splash visible long enough for the verse animation.
    final minSplash = Future<void>.delayed(const Duration(milliseconds: 2800));

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 12));
      }

      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      await FirestoreBootstrap(
        FirebaseFirestore.instance,
      ).ensureSeedData().timeout(const Duration(seconds: 12));

      await minSplash;
      if (!mounted) return;
      setState(() => _phase = _BootPhase.ready);
    } catch (error) {
      await minSplash;
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(error);
        _phase = _BootPhase.failed;
      });
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('PERMISSION_DENIED') ||
        text.contains('permission-denied')) {
      return 'صلاحيات قاعدة البيانات مرفوضة.\nراجع إعدادات الصلاحيات ثم أعد المحاولة.';
    }
    if (text.contains('DEVELOPER_ERROR')) {
      return 'خطأ في إعدادات التطبيق على أندرويد.\nتحقق من إعدادات المشروع ثم أعد المحاولة.';
    }
    if (text.contains('TimeoutException') || text.contains('timed out')) {
      return 'انتهت مهلة الاتصال بقاعدة البيانات.\nتأكد من وجود إنترنت ثم أعد المحاولة.';
    }
    return 'تعذر إكمال الاتصال بقاعدة البيانات.\n$text';
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _BootPhase.loading => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(
          statusMessage: 'جاري الاتصال بقاعدة البيانات...',
        ),
      ),
      _BootPhase.ready => const HasanahApp(),
      _BootPhase.failed => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 56),
                        const SizedBox(height: 20),
                        Text(
                          'تعذر إكمال التهيئة',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error ?? '',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: _bootstrap,
                          child: const Text('إعادة المحاولة'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              setState(() => _phase = _BootPhase.ready),
                          child: const Text('متابعة إلى شاشة الدخول'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    };
  }
}

enum _BootPhase { loading, ready, failed }
