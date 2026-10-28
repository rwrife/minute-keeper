import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';
import 'package:minutekeeper/main.dart';

void main() {
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    testWidgets('$platform uses native shell', (tester) async {
      await tester.pumpWidget(MinuteKeeperApp(platform: platform));
      expect(find.text('Your private meeting space'), findsOneWidget);
      switch (platform) {
        case TargetPlatform.iOS:
          expect(find.byType(CupertinoApp), findsOneWidget);
          expect(find.byType(material.MaterialApp), findsNothing);
          expect(find.byType(fluent.FluentApp), findsNothing);
        case TargetPlatform.android:
          expect(find.byType(material.MaterialApp), findsOneWidget);
          expect(find.byType(CupertinoApp), findsNothing);
          expect(find.byType(fluent.FluentApp), findsNothing);
        case TargetPlatform.windows:
          expect(find.byType(fluent.FluentApp), findsOneWidget);
          expect(find.byType(material.MaterialApp), findsNothing);
          expect(find.byType(CupertinoApp), findsNothing);
        default:
          fail('Unsupported platform');
      }
      expect(tester.takeException(), isNull);
    });
  }
}
