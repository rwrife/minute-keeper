import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';
import 'package:minutekeeper/ledger.dart';
import 'package:minutekeeper/main.dart';

void main() {
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    testWidgets('$platform create, edit, reopen, agenda, decision, action', (
      tester,
    ) async {
      final store = _MemoryLedgerFile(File('unused-test-ledger.json'));
      Future<void> start() async {
        await tester.pumpWidget(
          MinuteKeeperApp(key: UniqueKey(), platform: platform, store: store),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      await start();
      switch (platform) {
        case TargetPlatform.iOS:
          expect(find.byType(CupertinoApp), findsOneWidget);
          expect(find.byType(material.MaterialApp), findsNothing);
        case TargetPlatform.android:
          expect(find.byType(material.MaterialApp), findsOneWidget);
          expect(find.byType(CupertinoApp), findsNothing);
        case TargetPlatform.windows:
          expect(find.byType(fluent.FluentApp), findsOneWidget);
          expect(find.byType(material.MaterialApp), findsNothing);
        default:
          fail('Unsupported platform');
      }
      expect(find.text('Your private meeting space'), findsOneWidget);
      await tester.tap(find.byKey(const Key('new-meeting')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(
        find.byKey(const Key('field-Title')),
        'Club planning',
      );
      await tester.tap(find.text('Save').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect((await store.load()).meetings.single.title, 'Club planning');
      await tester.tap(find.byKey(const Key('edit-meeting')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(
        find.byKey(const Key('field-Title')),
        'Club review',
      );
      await tester.tap(find.text('Save').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('add-agenda')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(
        find.byKey(const Key('field-Agenda title')),
        'Budget',
      );
      await tester.tap(find.text('Save').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('add-decision')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(
        find.byKey(const Key('field-Decision')),
        'Approve budget',
      );
      await tester.tap(find.text('Save').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('add-action')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(
        find.byKey(const Key('field-Action')),
        'Send report',
      );
      await tester.enterText(find.byKey(const Key('field-Owner')), 'Ari');
      await tester.tap(find.text('Save').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final meeting = (await store.load()).meetings.single;
      expect(meeting.title, 'Club review');
      expect(meeting.agenda.single.title, 'Budget');
      expect(meeting.decisions.single.text, 'Approve budget');
      expect(meeting.actions.single.owner, 'Ari');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 800));
      await start();
      expect(find.text('Club review · ${meeting.date}'), findsOneWidget);
      await tester.tap(find.byKey(Key('meeting-${meeting.id}')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Decision: Approve budget'), findsOneWidget);
      expect(find.textContaining('Send report · Ari'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    for (final width in [390.0, 900.0, 1400.0]) {
      testWidgets(
        '$platform ${width.toInt()}px action dashboard filters and persists completion',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          final id = newRecordId();
          final agendaId = newRecordId();
          final actionId = newRecordId();
          final secondActionId = newRecordId();
          final secondAgendaId = newRecordId();
          final store = _MemoryLedgerFile(File('unused-test-ledger.json'));
          store.current = Ledger([
            Meeting(
              id: id,
              title: 'Club',
              date: '2026-10-31',
              agenda: [AgendaItem(id: agendaId, title: 'Plans', order: 0)],
              decisions: [],
              actions: [
                ActionItem(
                  id: actionId,
                  agendaId: agendaId,
                  text: 'Send notes',
                  owner: 'Ari',
                ),
              ],
            ),
            Meeting(
              id: newRecordId(),
              title: 'Board',
              date: '2026-10-30',
              agenda: [
                AgendaItem(id: secondAgendaId, title: 'Agenda', order: 0),
              ],
              decisions: [],
              actions: [
                ActionItem(
                  id: secondActionId,
                  agendaId: secondAgendaId,
                  text: 'Call members',
                  owner: 'Bea',
                  status: ActionStatus.carriedOver,
                ),
              ],
            ),
          ]);
          await tester.pumpWidget(
            MinuteKeeperApp(platform: platform, store: store),
          );
          await tester.pumpAndSettle();
          if (width < 720) {
            expect(find.byKey(const Key('nav-actions')), findsOneWidget);
          }
          await tester.tap(find.byKey(const Key('nav-actions')));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('Send notes · Ari · Club'),
            findsOneWidget,
          );
          expect(
            find.textContaining('Call members · Bea · Board'),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const Key('filter-carriedOver')));
          await tester.pumpAndSettle();
          expect(find.textContaining('Send notes · Ari · Club'), findsNothing);
          expect(
            find.textContaining('Call members · Bea · Board'),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const Key('filter-open')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(Key('complete-$actionId')));
          await tester.pumpAndSettle();
          expect(
            store.current.meetings.first.actions.single.status,
            ActionStatus.completed,
          );
          expect(find.textContaining('Send notes · Ari · Club'), findsNothing);
          expect(
            find.textContaining('Call members · Bea · Board'),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const Key('filter-completed')));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('Send notes · Ari · Club'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _MemoryLedgerFile extends LedgerFile {
  _MemoryLedgerFile(super.file);
  Ledger current = Ledger([]);
  @override
  Future<Ledger> load() async => current;
  @override
  Future<void> save(Ledger ledger) async {
    current = ledger;
  }
}
