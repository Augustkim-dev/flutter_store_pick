import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_store_pick/main.dart';

void main() {
  testWidgets('App starts with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BalletShopApp());

    // Verify that splash screen is shown with app name
    expect(find.text('발레 용품점 찾기'), findsOneWidget);
    expect(find.text('Ballet Shop Finder'), findsOneWidget);
    
    // Verify store icon is shown
    expect(find.byIcon(Icons.storefront), findsOneWidget);
  });
}
