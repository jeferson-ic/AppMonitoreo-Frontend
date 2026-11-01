import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/auth_screen.dart';

void main() {
  Future<void> abrirRegistro(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
  }

  // Orden de los campos del registro: nombre, correo, contraseña, confirmación.
  Finder campo(int i) => find.byType(TextFormField).at(i);

  testWidgets('El login permite mostrar y ocultar la contraseña', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
  });

  testWidgets('El registro pide confirmar la contraseña', (tester) async {
    await abrirRegistro(tester);
    await tester.enterText(campo(0), 'Ana García');
    await tester.enterText(campo(1), 'ana@correo.com');
    await tester.enterText(campo(2), 'clave1234');
    await tester.enterText(campo(3), 'clave9999');
    await tester.ensureVisible(find.text('Registrarse'));
    await tester.tap(find.text('Registrarse'));
    await tester.pump();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });

  testWidgets('Los requisitos de la contraseña se marcan al escribir', (tester) async {
    await abrirRegistro(tester);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    await tester.enterText(campo(2), 'abc');
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.enterText(campo(2), 'abcdefg1');
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
  });
}
