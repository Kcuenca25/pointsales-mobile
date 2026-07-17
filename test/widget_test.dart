// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecomerce_app/main.dart';

// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecomerce_app/main.dart'; // Ajusta la ruta

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      FutureBuilder(
        future: initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          return buildMainApp();
        },
      ),
    );

    // Verifica que la app se carga
    await tester.pumpAndSettle();
    
    // Puedes verificar que se muestra algo
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}