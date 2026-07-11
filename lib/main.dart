import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.initialize();
  runApp(const HasanahApp());
}
