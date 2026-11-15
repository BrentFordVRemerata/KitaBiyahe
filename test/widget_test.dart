import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitabiyahe/ui/theme.dart';
import 'package:kitabiyahe/ui/widgets.dart';

void main() {
  testWidgets('KitaBiyahe cards display actual rider instructions', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: kitaTheme(),
      home: const Scaffold(
        body: SoftCard(child: Text('Enter your shift earnings')),
      ),
    ));
    expect(find.text('Enter your shift earnings'), findsOneWidget);
  });
}
