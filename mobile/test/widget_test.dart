// Flutter widget test helpers.
import 'package:flutter_test/flutter_test.dart';

// App root widget.
import 'package:friend_finder/main.dart';

void main() {
  // Basic smoke test that confirms the app shell renders.
  testWidgets('renders Friend Finder app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Friend Finder'), findsOneWidget);
    expect(find.text('Stay connected with your world'), findsOneWidget);
  });
}
