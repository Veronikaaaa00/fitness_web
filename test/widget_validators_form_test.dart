import 'package:fitness_web/core/permissions.dart';
import 'package:fitness_web/models/role.dart';
import 'package:fitness_web/validation/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('form shows email validation error', (tester) async {
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: key,
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              validator: Validators.email,
            ),
          ),
        ),
      ),
    );
    key.currentState!.validate();
    await tester.pump();
    expect(find.textContaining('обязательно'), findsOneWidget);
  });

  testWidgets('admin catalog permission hides for member', (tester) async {
    expect(Permissions.canManageCatalog(Role.member), isFalse);
    expect(Permissions.canManageCatalog(Role.admin), isTrue);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Permissions.canManageCatalog(Role.member)
              ? const Text('ADMIN_ONLY')
              : const Text('HIDDEN'),
        ),
      ),
    );
    expect(find.text('HIDDEN'), findsOneWidget);
    expect(find.text('ADMIN_ONLY'), findsNothing);
  });
}
