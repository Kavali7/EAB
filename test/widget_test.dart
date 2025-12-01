import 'package:eab/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ChurchApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
