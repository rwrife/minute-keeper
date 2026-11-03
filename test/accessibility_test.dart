import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minutekeeper/ledger.dart';
import 'package:minutekeeper/main.dart';

void main() {
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    testWidgets('$platform large text, labels and keyboard meeting selection', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      tester.view.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final store = _MemoryLedgerFile(File('unused-a11y-ledger.json'));
      store.current = Ledger([
        Meeting(
          id: newRecordId(),
          title: 'Board',
          date: '2026-11-02',
          agenda: [],
          decisions: [],
          actions: [],
        ),
      ]);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MinuteKeeperApp(platform: platform, store: store),
      );
      await tester.pumpAndSettle();
      final meeting = find.byKey(
        Key('meeting-${store.current.meetings.single.id}'),
      );
      expect(meeting, findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('new-meeting')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('field-Title')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      if (platform == TargetPlatform.windows) {
        expect(find.byType(fluent.Button), findsWidgets);
      }
      await tester.ensureVisible(meeting);
      await tester.tap(meeting);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('minutes-preview')), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}

class _MemoryLedgerFile extends LedgerFile {
  _MemoryLedgerFile(super.file);
  Ledger current = Ledger([]);
  @override
  Future<Ledger> load() async => current;
  @override
  Future<void> save(Ledger ledger) async => current = ledger;
}
