import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Prefer the local persistence cache, then refresh from the server in the
/// background so the next read is already warm.
Future<QuerySnapshot<Map<String, dynamic>>> getQueryPreferCache(
  Query<Map<String, dynamic>> query,
) async {
  try {
    final local = await query.get(const GetOptions(source: Source.cache));
    if (local.docs.isNotEmpty) {
      unawaited(query.get().then((_) {}, onError: (_) {}));
      return local;
    }
  } catch (_) {}
  return query.get();
}

Future<DocumentSnapshot<Map<String, dynamic>>> getDocPreferCache(
  DocumentReference<Map<String, dynamic>> ref,
) async {
  try {
    final local = await ref.get(const GetOptions(source: Source.cache));
    if (local.exists) {
      unawaited(ref.get().then((_) {}, onError: (_) {}));
      return local;
    }
  } catch (_) {}
  return ref.get();
}
