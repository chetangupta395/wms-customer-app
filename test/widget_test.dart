import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_customer/api/session.dart';
import 'package:wms_customer/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('customer sign in is the first screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final session = CustomerSession();
    await session.load();

    await tester.pumpWidget(CustomerApp(session: session));

    expect(find.text('Fieldora'), findsOneWidget);
    expect(find.text('Your orders,\nalways within reach.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
