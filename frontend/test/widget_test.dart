// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:actually_here/main.dart';

void main() {
  testWidgets('App loads ProximityTestScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ActuallyHereApp());

    // Verifica se a app iniciou e está na tela de Teste de Presença
    expect(find.text('Teste de Presença'), findsOneWidget);
  });
}
