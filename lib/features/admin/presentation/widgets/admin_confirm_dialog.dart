import 'package:flutter/material.dart';

import '../../../../core/presentation/hasanah_request_dialog.dart';

Future<bool> confirmAdminDelete(BuildContext context, String message) {
  return HasanahRequestDialog.confirm(
    context,
    title: 'تأكيد الحذف',
    message: message,
    okText: 'حذف',
  );
}
