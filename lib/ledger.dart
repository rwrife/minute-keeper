import 'dart:convert';
import 'dart:io';
import 'dart:math';

final Random _random = Random.secure();

String newRecordId() => List.generate(
  16,
  (_) => _random.nextInt(256),
).map((n) => n.toRadixString(16).padLeft(2, '0')).join();

String _text(Object? value, String field) {
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw FormatException('Invalid $field');
  }
  return value;
}

String _id(Object? value) {
  final id = _text(value, 'id');
  if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(id)) {
    throw const FormatException('Invalid id');
  }
  return id;
}

String _date(Object? value, {bool optional = false}) {
  if (optional && value == null) return '';
  final date = _text(value, 'date');
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(date);
  if (match == null) throw const FormatException('Invalid date');
  final parsed = DateTime.utc(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
  );
  if (parsed.toIso8601String().substring(0, 10) != date) {
    throw const FormatException('Invalid date');
  }
  return date;
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected object');
  }
  return value;
}

List<T> _list<T>(Object? value, T Function(Object?) parse) {
  if (value is! List) throw const FormatException('Expected list');
  return List.unmodifiable(value.map(parse));
}

void _unique(Iterable<String> ids) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) throw const FormatException('Duplicate id');
  }
}

class AgendaItem {
  AgendaItem({required this.id, required this.title, required this.order}) {
    _id(id);
    _text(title, 'agenda title');
    if (order < 0) throw const FormatException('Invalid agenda order');
  }

  final String id;
  final String title;
  final int order;

  factory AgendaItem.fromJson(Object? value) {
    final m = _object(value);
    final order = m['order'];
    if (order is! int) throw const FormatException('Invalid agenda order');
    return AgendaItem(
      id: _id(m['id']),
      title: _text(m['title'], 'agenda title'),
      order: order,
    );
  }

  Map<String, Object> toJson() => {'id': id, 'title': title, 'order': order};
}

class Decision {
  Decision({required this.id, required this.agendaId, required this.text}) {
    _id(id);
    _id(agendaId);
    _text(text, 'decision');
  }

  final String id;
  final String agendaId;
  final String text;

  factory Decision.fromJson(Object? value) {
    final m = _object(value);
    return Decision(
      id: _id(m['id']),
      agendaId: _id(m['agendaId']),
      text: _text(m['text'], 'decision'),
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'agendaId': agendaId,
    'text': text,
  };
}

enum ActionStatus { pending, carriedOver, completed }

class ActionItem {
  ActionItem({
    required this.id,
    required this.agendaId,
    required this.text,
    required this.owner,
    this.dueDate,
    this.status = ActionStatus.pending,
  }) {
    _id(id);
    _id(agendaId);
    _text(text, 'action');
    _text(owner, 'owner');
    if (dueDate != null) _date(dueDate);
  }

  final String id;
  final String agendaId;
  final String text;
  final String owner;
  final String? dueDate;
  final ActionStatus status;

  ActionItem transition(ActionStatus next) {
    if (next != status &&
        !((status == ActionStatus.pending && next != ActionStatus.pending) ||
            (status == ActionStatus.carriedOver &&
                next == ActionStatus.completed))) {
      throw StateError('Invalid action transition: $status to $next');
    }
    return ActionItem(
      id: id,
      agendaId: agendaId,
      text: text,
      owner: owner,
      dueDate: dueDate,
      status: next,
    );
  }

  factory ActionItem.fromJson(Object? value) {
    final m = _object(value);
    final due = m['dueDate'];
    final status = m['status'];
    if (due != null && due is! String) {
      throw const FormatException('Invalid due date');
    }
    return ActionItem(
      id: _id(m['id']),
      agendaId: _id(m['agendaId']),
      text: _text(m['text'], 'action'),
      owner: _text(m['owner'], 'owner'),
      dueDate: due == null ? null : _date(due),
      status: ActionStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => throw const FormatException('Invalid action status'),
      ),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'agendaId': agendaId,
    'text': text,
    'owner': owner,
    'dueDate': dueDate,
    'status': status.name,
  };
}

class Meeting {
  Meeting({
    required this.id,
    required this.title,
    required this.date,
    required List<AgendaItem> agenda,
    required List<Decision> decisions,
    required List<ActionItem> actions,
  }) : agenda = List.unmodifiable(
         [...agenda]..sort((a, b) => a.order.compareTo(b.order)),
       ),
       decisions = List.unmodifiable(decisions),
       actions = List.unmodifiable(actions) {
    _id(id);
    _text(title, 'meeting title');
    _date(date);
    _unique([
      ...this.agenda.map((a) => a.id),
      ...this.decisions.map((d) => d.id),
      ...this.actions.map((a) => a.id),
    ]);
    _unique(this.agenda.map((a) => a.order.toString()));
    final agendaIds = this.agenda.map((a) => a.id).toSet();
    if (this.decisions.any((d) => !agendaIds.contains(d.agendaId)) ||
        this.actions.any((a) => !agendaIds.contains(a.agendaId))) {
      throw const FormatException('Unknown agenda reference');
    }
  }

  final String id;
  final String title;
  final String date;
  final List<AgendaItem> agenda;
  final List<Decision> decisions;
  final List<ActionItem> actions;

  factory Meeting.fromJson(Object? value) {
    final m = _object(value);
    return Meeting(
      id: _id(m['id']),
      title: _text(m['title'], 'meeting title'),
      date: _date(m['date']),
      agenda: _list(m['agenda'], AgendaItem.fromJson),
      decisions: _list(m['decisions'], Decision.fromJson),
      actions: _list(m['actions'], ActionItem.fromJson),
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'agenda': agenda.map((a) => a.toJson()).toList(),
    'decisions': decisions.map((d) => d.toJson()).toList(),
    'actions': actions.map((a) => a.toJson()).toList(),
  };
}

class Ledger {
  Ledger(List<Meeting> meetings) : meetings = List.unmodifiable(meetings) {
    _unique(meetings.map((m) => m.id));
    _unique(
      meetings.expand(
        (m) => [
          m.id,
          ...m.agenda.map((a) => a.id),
          ...m.decisions.map((d) => d.id),
          ...m.actions.map((a) => a.id),
        ],
      ),
    );
  }

  final List<Meeting> meetings;

  factory Ledger.fromJson(Object? value) {
    final m = _object(value);
    if (m['schemaVersion'] == 0) {
      // ponytail: v0 supported only; add explicit migrations when schema changes.
      final old = _list(m['meetings'], _object);
      return Ledger(
        old.map((meeting) {
          final actions = _list(meeting['actions'], _object);
          return Meeting.fromJson({
            ...meeting,
            'actions': actions
                .map((action) => {...action, 'status': 'pending'})
                .toList(),
          });
        }).toList(),
      );
    }
    if (m['schemaVersion'] != 1) {
      throw const FormatException('Unsupported schema version');
    }
    return Ledger(_list(m['meetings'], Meeting.fromJson));
  }

  Map<String, Object> toJson() => {
    'schemaVersion': 1,
    'meetings': meetings.map((m) => m.toJson()).toList(),
  };
}

class LedgerFile {
  LedgerFile(this.file);
  final File file;

  Future<Ledger> load() async {
    if (!await file.exists()) return Ledger([]);
    try {
      return Ledger.fromJson(jsonDecode(await file.readAsString()));
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid ledger file: $error');
    }
  }

  Future<void> save(Ledger ledger) async {
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.${newRecordId()}.tmp');
    try {
      await temp.writeAsString(jsonEncode(ledger.toJson()), flush: true);
      await temp.rename(file.path);
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }
}
