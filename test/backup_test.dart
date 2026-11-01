import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:minutekeeper/backup.dart';
import 'package:minutekeeper/ledger.dart';

Meeting _sampleMeeting({
  String? id,
  String title = 'Budget Sync',
  String date = '2026-11-01',
}) {
  final mId = id ?? newRecordId();
  final aId = newRecordId();
  return Meeting(
    id: mId,
    title: title,
    date: date,
    agenda: [AgendaItem(id: aId, title: 'Q4 Budget', order: 0)],
    decisions: [
      Decision(
        id: newRecordId(),
        agendaId: aId,
        text: 'Approved \$5,000 grant',
      ),
    ],
    actions: [
      ActionItem(
        id: newRecordId(),
        agendaId: aId,
        text: 'File receipts',
        owner: 'Alice Admin',
        dueDate: '2026-11-15',
        status: ActionStatus.pending,
      ),
    ],
  );
}

void main() {
  group('markdownMinutes', () {
    test('redacts private fields (owner and due date) by default', () {
      final meeting = _sampleMeeting();
      final md = markdownMinutes(meeting);
      expect(md, contains('# Budget Sync'));
      expect(md, contains('Date: 2026-11-01'));
      expect(md, contains('## Q4 Budget'));
      expect(md, contains('- Decision: Approved \$5,000 grant'));
      expect(md, contains('- Action: File receipts (pending)'));
      expect(md, isNot(contains('Alice Admin')));
      expect(md, isNot(contains('2026-11-15')));
    });

    test('includes owner and due date when includePrivateFields is true', () {
      final meeting = _sampleMeeting();
      final md = markdownMinutes(meeting, includePrivateFields: true);
      expect(
        md,
        contains(
          '- Action: File receipts — Alice Admin, due 2026-11-15 (pending)',
        ),
      );
    });
  });

  group('backup export and import', () {
    test('round-trip preserves meetings, agenda, decisions, actions', () {
      final m1 = _sampleMeeting(title: 'Sprint Kickoff');
      final m2 = _sampleMeeting(title: 'Retrospective', date: '2026-11-02');
      final initial = Ledger([m1, m2]);
      final json = exportBackup(initial);

      final imported = importBackup(json, Ledger([]), replaceConflicts: false);
      expect(imported.meetings.length, 2);
      expect(imported.meetings[0].title, 'Sprint Kickoff');
      expect(imported.meetings[1].title, 'Retrospective');
      expect(imported.meetings[0].actions[0].owner, 'Alice Admin');
    });

    test('replaces conflicts when replaceConflicts is true', () {
      final sharedId = newRecordId();
      final original = _sampleMeeting(id: sharedId, title: 'Original Version');
      final incoming = _sampleMeeting(id: sharedId, title: 'Updated Version');

      final merged = importBackup(
        exportBackup(Ledger([incoming])),
        Ledger([original]),
        replaceConflicts: true,
      );
      expect(merged.meetings.length, 1);
      expect(merged.meetings.first.title, 'Updated Version');
    });

    test(
      'keeps existing version on conflict when replaceConflicts is false',
      () {
        final sharedId = newRecordId();
        final original = _sampleMeeting(
          id: sharedId,
          title: 'Original Version',
        );
        final incoming = _sampleMeeting(id: sharedId, title: 'Updated Version');

        final merged = importBackup(
          exportBackup(Ledger([incoming])),
          Ledger([original]),
          replaceConflicts: false,
        );
        expect(merged.meetings.length, 1);
        expect(merged.meetings.first.title, 'Original Version');
      },
    );

    test('fails closed on invalid json without mutating state', () {
      final original = Ledger([_sampleMeeting()]);
      expect(
        () =>
            importBackup('{not valid json', original, replaceConflicts: false),
        throwsA(isA<FormatException>()),
      );
    });

    test('fails closed on invalid schema/unsupported version', () {
      final original = Ledger([_sampleMeeting()]);
      final badSchema = jsonEncode({'schemaVersion': 99, 'meetings': []});
      expect(
        () => importBackup(badSchema, original, replaceConflicts: false),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
