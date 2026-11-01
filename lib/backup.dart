import 'dart:convert';

import 'ledger.dart';

/// Preview excludes owner names and due dates unless explicitly included.
String markdownMinutes(Meeting meeting, {bool includePrivateFields = false}) {
  String clean(String value) =>
      value.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
  final lines = <String>[
    '# ${clean(meeting.title)}',
    '',
    'Date: ${meeting.date}',
  ];
  for (final agenda in meeting.agenda) {
    lines.addAll(['', '## ${clean(agenda.title)}']);
    for (final decision in meeting.decisions.where(
      (d) => d.agendaId == agenda.id,
    )) {
      lines.add('- Decision: ${clean(decision.text)}');
    }
    for (final action in meeting.actions.where(
      (a) => a.agendaId == agenda.id,
    )) {
      final private = includePrivateFields
          ? ' — ${clean(action.owner)}${action.dueDate == null ? '' : ', due ${action.dueDate}'}'
          : '';
      lines.add(
        '- Action: ${clean(action.text)}$private (${action.status.name})',
      );
    }
  }
  return '${lines.join('\n')}\n';
}

String exportBackup(Ledger ledger) =>
    const JsonEncoder.withIndent('  ').convert(ledger.toJson());

/// Parse and validate entire candidate before touching existing state.
Ledger importBackup(
  String source,
  Ledger current, {
  required bool replaceConflicts,
}) {
  final incoming = Ledger.fromJson(jsonDecode(source));
  if (replaceConflicts) {
    final ids = incoming.meetings.map((m) => m.id).toSet();
    return Ledger([
      for (final meeting in current.meetings)
        if (!ids.contains(meeting.id)) meeting,
      ...incoming.meetings,
    ]);
  }
  final ids = current.meetings.map((m) => m.id).toSet();
  return Ledger([
    ...current.meetings,
    for (final meeting in incoming.meetings)
      if (!ids.contains(meeting.id)) meeting,
  ]);
}
