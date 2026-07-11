import 'package:flutter/material.dart';

import '../../../shared/domain/entities/institute_entities.dart';
import '../cubit/session_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.sessionCubit, super.key});

  final SessionCubit sessionCubit;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController(text: 'demo-admin');
  UserRole _selectedRole = UserRole.admin;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            size: 56,
                            color: Color(0xFFD4AF37),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'أهلاً بك في حسنة',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'سجّل دخولك للوصول إلى مساحة العمل المناسبة.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _userIdController,
                            decoration: const InputDecoration(
                              labelText: 'معرّف المستخدم',
                              prefixIcon: Icon(Icons.person_outline),
                              helperText:
                                  'للمعاينة: demo-admin أو demo-teacher',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'أدخل معرّف المستخدم.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<UserRole>(
                            initialValue: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'نوع الحساب',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            items: [
                              for (final role in UserRole.values)
                                DropdownMenuItem(
                                  value: role,
                                  child: Text(_roleLabel(role)),
                                ),
                            ],
                            onChanged: (role) {
                              if (role != null) {
                                setState(() => _selectedRole = role);
                              }
                            },
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _isSubmitting ? null : _signIn,
                            child: _isSubmitting
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('دخول'),
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
      ),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.sessionCubit.signIn(_userIdController.text.trim());
      final user = widget.sessionCubit.state;
      if (user == null || user.role != _selectedRole) {
        await widget.sessionCubit.signOut();
        throw StateError('نوع الحساب لا يطابق بيانات المستخدم.');
      }
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message.toString());
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'تعذر تسجيل الدخول محلياً.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.admin => 'مدير',
      UserRole.teacher => 'معلّم',
      UserRole.student => 'طالب',
      UserRole.parent => 'ولي أمر',
    };
  }
}
