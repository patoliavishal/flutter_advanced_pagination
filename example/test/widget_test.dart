// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_pagination_example/main.dart';

void main() {
  testWidgets('Showcase app loads demo list', (WidgetTester tester) async {
    await tester.pumpWidget(const PaginationShowcaseApp());

    expect(find.text('Advanced Pagination Demos'), findsOneWidget);
    expect(find.text('Basic Pagination'), findsOneWidget);
    expect(find.text('Scroll Prefetch'), findsOneWidget);
  });
}
