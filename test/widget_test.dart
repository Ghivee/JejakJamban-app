import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:jejak_jamban/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('home shows the JejakJamban dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: JejakJambanApp()));
    await tester.pumpAndSettle();

    expect(find.text('JejakJamban'), findsOneWidget);
    expect(find.text('Catat. Pahami. Menang.'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });
}
