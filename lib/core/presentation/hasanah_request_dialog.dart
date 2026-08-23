import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Unified Awesome Dialogs for every in-app request (loading / success / error).
abstract final class HasanahRequestDialog {
  static bool _loadingOpen = false;
  static Timer? _showTimer;
  static int _token = 0;

  static void showLoading(
    BuildContext context, {
    String message = 'جارٍ تنفيذ الطلب...',
  }) {
    if (_loadingOpen || _showTimer != null || !context.mounted) return;
    final token = ++_token;
    _showTimer = Timer(const Duration(milliseconds: 280), () {
      _showTimer = null;
      if (!context.mounted || token != _token || _loadingOpen) return;
      _loadingOpen = true;
      AwesomeDialog(
        context: context,
        dialogType: DialogType.noHeader,
        animType: AnimType.scale,
        useRootNavigator: true,
        dismissOnTouchOutside: false,
        dismissOnBackKeyPress: false,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          child: Column(
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ).show().whenComplete(() {
        if (token == _token) _loadingOpen = false;
      });
      if (token != _token) {
        hide(context);
      }
    });
  }

  static void hide(BuildContext context) {
    _token++;
    _showTimer?.cancel();
    _showTimer = null;
    if (!_loadingOpen) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) navigator.pop();
    _loadingOpen = false;
  }

  static Future<void> success(BuildContext context, String message) {
    if (!context.mounted) return Future.value();
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.bottomSlide,
      useRootNavigator: true,
      title: 'تم بنجاح',
      desc: message,
      btnOkText: 'حسناً',
      btnOkColor: HasanahColors.primary,
      btnOkOnPress: () {},
    ).show();
  }

  static Future<void> error(BuildContext context, String message) {
    if (!context.mounted) return Future.value();
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.bottomSlide,
      useRootNavigator: true,
      title: 'تعذر التنفيذ',
      desc: message,
      btnOkText: 'حسناً',
      btnOkColor: HasanahColors.danger,
      btnOkOnPress: () {},
    ).show();
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String okText = 'تأكيد',
    String cancelText = 'إلغاء',
  }) async {
    var accepted = false;
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      useRootNavigator: true,
      title: title,
      desc: message,
      btnCancelText: cancelText,
      btnOkText: okText,
      btnCancelOnPress: () {},
      btnOkOnPress: () => accepted = true,
    ).show();
    return accepted;
  }
}
