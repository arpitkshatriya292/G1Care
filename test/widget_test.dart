import 'package:flutter_test/flutter_test.dart';
import 'package:g1care/app.dart';
import 'package:g1care/widgets/g1care_logo.dart';

void main() {
  testWidgets('G1Care App loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const G1CareApp());
    expect(find.byType(G1CareLogo), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}

