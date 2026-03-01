import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/main.dart';

void main() {
  testWidgets('App loads Login Page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OpenEarableApp()));
    await tester.pumpAndSettle();

    expect(find.text('Log into\nyour account'), findsOneWidget);
  });
}