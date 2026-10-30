import 'package:fitness_web/state/load_status.dart';
import 'package:fitness_web/widgets/status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatusView shows loading indicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusView(status: LoadStatus.loading),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('StatusView shows empty title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusView(
            status: LoadStatus.empty,
            emptyTitle: 'Пусто здесь',
          ),
        ),
      ),
    );
    expect(find.text('Пусто здесь'), findsOneWidget);
  });

  testWidgets('StatusView error has retry button', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusView(
            status: LoadStatus.error,
            message: 'Сбой сети',
            onRetry: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('Сбой сети'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    expect(tapped, isTrue);
  });
}
