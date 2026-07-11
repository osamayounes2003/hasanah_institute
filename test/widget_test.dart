import 'package:flutter_test/flutter_test.dart';
import 'package:hasanah/app.dart';
import 'package:hasanah/core/utils/iso_date_time.dart';

void main() {
  testWidgets('shows the local sign-in screen', (tester) async {
    await tester.pumpWidget(const HasanahApp());

    expect(find.text('أهلاً بك في حسنة'), findsOneWidget);
  });

  test('serializes timestamps as UTC ISO-8601', () {
    final serialized = IsoDateTime.encode(DateTime.utc(2026, 7, 11, 9, 30));

    expect(serialized, '2026-07-11T09:30:00.000Z');
    expect(IsoDateTime.decode(serialized).isUtc, isTrue);
  });
}
