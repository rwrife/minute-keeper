import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:minutekeeper/ledger.dart';

void main() {
  const meetingId = '00000000000000000000000000000001';
  const agendaId = '00000000000000000000000000000002';
  const actionId = '00000000000000000000000000000003';
  const decisionId = '00000000000000000000000000000004';

  Meeting sample() => Meeting(
    id: meetingId,
    title: 'Planning',
    date: '2026-10-29',
    agenda: [
      AgendaItem(id: agendaId, title: 'First', order: 1),
      AgendaItem(
        id: '00000000000000000000000000000005',
        title: 'Earlier',
        order: 0,
      ),
    ],
    decisions: [Decision(id: decisionId, agendaId: agendaId, text: 'Approved')],
    actions: [
      ActionItem(
        id: actionId,
        agendaId: agendaId,
        text: 'Send notes',
        owner: 'Pat',
        dueDate: '2026-11-01',
      ),
    ],
  );

  test('stable IDs, ordered agenda, immutable lists and state transitions', () {
    final meeting = sample();
    expect(newRecordId(), hasLength(32));
    expect(meeting.agenda.map((a) => a.title), ['Earlier', 'First']);
    expect(() => meeting.agenda.clear(), throwsUnsupportedError);
    final action = meeting.actions.single;
    expect(
      action
          .transition(ActionStatus.carriedOver)
          .transition(ActionStatus.completed)
          .status,
      ActionStatus.completed,
    );
    expect(
      action.transition(ActionStatus.completed).status,
      ActionStatus.completed,
    );
    expect(
      () => action
          .transition(ActionStatus.completed)
          .transition(ActionStatus.pending),
      throwsStateError,
    );
    expect(
      () => action
          .transition(ActionStatus.carriedOver)
          .transition(ActionStatus.pending),
      throwsStateError,
    );
    expect(
      Ledger.fromJson(jsonDecode(jsonEncode(Ledger([meeting]).toJson())))
          .toJson(),
      Ledger([meeting]).toJson(),
    );
  });

  test(
    'rejects bad dates, owner, references, duplicate IDs and malformed records',
    () {
      final json = sample().toJson();
      for (final badDate in ['2026-02-30', '2026-13-01', '2026-2-01']) {
        expect(
          () => Meeting.fromJson({...json, 'date': badDate}),
          throwsFormatException,
        );
      }
      expect(
        () => Meeting.fromJson({
          ...json,
          'actions': [
            {...sample().actions.single.toJson(), 'owner': '  '},
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => Meeting.fromJson({
          ...json,
          'actions': [
            {...sample().actions.single.toJson(), 'dueDate': '2026-02-30'},
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => Meeting.fromJson({
          ...json,
          'actions': [
            {...sample().actions.single.toJson(), 'agendaId': actionId},
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => Meeting.fromJson({
          ...json,
          'actions': [
            {...sample().actions.single.toJson(), 'status': 'unknown'},
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => Meeting.fromJson({
          ...json,
          'actions': [
            sample().actions.single.toJson(),
            sample().actions.single.toJson(),
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => Ledger.fromJson({'schemaVersion': 99, 'meetings': []}),
        throwsFormatException,
      );
      expect(() => Ledger([sample(), sample()]), throwsFormatException);
    },
  );

  test(
    'migrates v0 and writes atomically without losing file on invalid load',
    () async {
      final dir = await Directory.systemTemp.createTemp('minute-keeper-test-');
      addTearDown(() => dir.delete(recursive: true));
      final file = LedgerFile(File('${dir.path}/data/ledger.json'));
      expect((await file.load()).meetings, isEmpty);
      final original = sample().toJson();
      final oldActions = (original['actions'] as List)
          .cast<Map<String, Object?>>()
          .map((a) => {...a}..remove('status'))
          .toList();
      final v0 = {
        'schemaVersion': 0,
        'meetings': [
          {...original, 'actions': oldActions},
        ],
      };
      await file.file.parent.create(recursive: true);
      await file.file.writeAsString(jsonEncode(v0));
      final migrated = await file.load();
      expect(
        migrated.meetings.single.actions.single.status,
        ActionStatus.pending,
      );
      await file.save(migrated);
      expect(jsonDecode(await file.file.readAsString())['schemaVersion'], 1);
      expect((await file.load()).toJson(), migrated.toJson());
      expect(file.file.parent.listSync().length, 1);
      await file.file.writeAsString('{bad');
      await expectLater(file.load(), throwsFormatException);
      expect(await file.file.readAsString(), '{bad');
    },
  );
}
