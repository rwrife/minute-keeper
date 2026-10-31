import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:path_provider/path_provider.dart';

import 'ledger.dart';

void main() => runApp(const MinuteKeeperApp());

class MinuteKeeperApp extends StatelessWidget {
  const MinuteKeeperApp({super.key, this.platform, this.store});
  final TargetPlatform? platform;
  final LedgerFile? store;

  @override
  Widget build(BuildContext context) {
    final target = platform ?? defaultTargetPlatform;
    final home = _MinuteKeeperHome(platform: target, store: store);
    if (target == TargetPlatform.iOS || target == TargetPlatform.macOS) {
      return CupertinoApp(title: 'Minute Keeper', home: home);
    }
    if (target == TargetPlatform.windows) {
      return fluent.FluentApp(title: 'Minute Keeper', home: home);
    }
    return material.MaterialApp(
      title: 'Minute Keeper',
      theme: material.ThemeData(useMaterial3: true),
      home: home,
    );
  }
}

class _MinuteKeeperHome extends StatefulWidget {
  const _MinuteKeeperHome({required this.platform, this.store});
  final TargetPlatform platform;
  final LedgerFile? store;

  @override
  State<_MinuteKeeperHome> createState() => _MinuteKeeperHomeState();
}

class _MinuteKeeperHomeState extends State<_MinuteKeeperHome> {
  LedgerFile? _store;
  Ledger? _ledger;
  String? _meetingId;
  String? _agendaId;
  bool _dashboard = false;
  ActionStatus? _actionFilter;
  bool _busy = false;
  // ponytail: Status-only filters; add owner/date search when action volume warrants it.
  Object? _error;

  TargetPlatform get _platform => widget.platform;
  bool get _ios =>
      _platform == TargetPlatform.iOS || _platform == TargetPlatform.macOS;
  bool get _windows => _platform == TargetPlatform.windows;
  Meeting? get _meeting {
    for (final meeting in _ledger?.meetings ?? <Meeting>[]) {
      if (meeting.id == _meetingId) return meeting;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final store =
          widget.store ??
          LedgerFile(
            File(
              '${(await getApplicationSupportDirectory()).path}/ledger.json',
            ),
          );
      final ledger = await store.load();
      if (mounted) {
        setState(() {
          _store = store;
          _ledger = ledger;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _update(Meeting replacement) async {
    if (_busy || _ledger == null || _store == null) {
      throw StateError('Store unavailable');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final next = Ledger([
        for (final meeting in _ledger!.meetings)
          if (meeting.id == replacement.id) replacement else meeting,
        if (!_ledger!.meetings.any((m) => m.id == replacement.id)) replacement,
      ]);
      await _store!.save(next);
      if (mounted) {
        setState(() {
          _ledger = next;
          _busy = false;
          _meetingId = replacement.id;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _busy = false;
        });
      }
      rethrow;
    }
  }

  Meeting _copy(
    Meeting meeting, {
    String? title,
    String? date,
    List<AgendaItem>? agenda,
    List<Decision>? decisions,
    List<ActionItem>? actions,
  }) => Meeting(
    id: meeting.id,
    title: title ?? meeting.title,
    date: date ?? meeting.date,
    agenda: agenda ?? meeting.agenda,
    decisions: decisions ?? meeting.decisions,
    actions: actions ?? meeting.actions,
  );

  // ponytail: Text dates only; replace with native date pickers when calendar navigation lands.
  Future<void> _form(
    String heading,
    List<String> labels,
    Future<void> Function(List<String>) submit, {
    List<String>? initial,
  }) async {
    final controllers = [
      for (var i = 0; i < labels.length; i++)
        TextEditingController(text: initial == null ? '' : initial[i]),
    ];
    String? problem;
    bool submitting = false;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: heading,
      pageBuilder: (context, _, _) => StatefulBuilder(
        builder: (context, refresh) {
          final fields = <Widget>[
            for (var i = 0; i < labels.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _field(labels[i], controllers[i]),
              ),
            if (problem != null) Text(problem!, key: const Key('form-error')),
          ];
          Future<void> save() async {
            if (submitting) return;
            final values = [for (final c in controllers) c.text.trim()];
            refresh(() {
              problem = null;
              submitting = true;
            });
            try {
              await submit(values);
              if (context.mounted) Navigator.of(context).pop();
            } catch (error) {
              if (context.mounted) refresh(() => problem = error.toString());
            } finally {
              if (context.mounted) refresh(() => submitting = false);
            }
          }

          if (_ios) {
            return CupertinoAlertDialog(
              title: Text(heading),
              content: Column(children: fields),
              actions: [
                CupertinoDialogAction(
                  onPressed: submitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  onPressed: submitting ? null : save,
                  child: const Text('Save'),
                ),
              ],
            );
          }
          if (_windows) {
            return fluent.ContentDialog(
              title: Text(heading),
              content: Column(mainAxisSize: MainAxisSize.min, children: fields),
              actions: [
                fluent.Button(
                  onPressed: submitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                fluent.FilledButton(
                  onPressed: submitting ? null : save,
                  child: const Text('Save'),
                ),
              ],
            );
          }
          return material.AlertDialog(
            title: Text(heading),
            content: material.SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: fields),
            ),
            actions: [
              material.TextButton(
                onPressed: submitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              material.FilledButton(
                onPressed: submitting ? null : save,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    // Dialog pop finishes before its exit animation; keep fields alive until unmounted.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  Widget _field(String label, TextEditingController controller) {
    if (_ios) {
      return Semantics(
        label: label,
        child: CupertinoTextField(
          controller: controller,
          placeholder: label,
          key: Key('field-$label'),
        ),
      );
    }
    if (_windows) {
      return fluent.TextBox(
        controller: controller,
        placeholder: label,
        key: Key('field-$label'),
      );
    }
    return material.TextField(
      controller: controller,
      decoration: material.InputDecoration(labelText: label),
      key: Key('field-$label'),
    );
  }

  void _newMeeting() => _form(
    'New meeting',
    ['Title', 'Date (YYYY-MM-DD)'],
    (values) => _update(
      Meeting(
        id: newRecordId(),
        title: values[0],
        date: values[1],
        agenda: [],
        decisions: [],
        actions: [],
      ),
    ),
    initial: ['', DateTime.now().toIso8601String().substring(0, 10)],
  );
  void _editMeeting(Meeting m) => _form(
    'Edit meeting',
    ['Title', 'Date (YYYY-MM-DD)'],
    (values) => _update(_copy(m, title: values[0], date: values[1])),
    initial: [m.title, m.date],
  );
  void _addAgenda(Meeting m) =>
      _form('Add agenda item', ['Agenda title'], (values) async {
        final item = AgendaItem(
          id: newRecordId(),
          title: values[0],
          order: m.agenda.length,
        );
        await _update(_copy(m, agenda: [...m.agenda, item]));
        if (mounted) setState(() => _agendaId = item.id);
      });
  void _addDecision(Meeting m, AgendaItem a) => _form(
    'Record decision',
    ['Decision'],
    (values) => _update(
      _copy(
        m,
        decisions: [
          ...m.decisions,
          Decision(id: newRecordId(), agendaId: a.id, text: values[0]),
        ],
      ),
    ),
  );
  void _addAction(Meeting m, AgendaItem a) => _form(
    'Add action',
    ['Action', 'Owner', 'Due (YYYY-MM-DD, optional)'],
    (values) => _update(
      _copy(
        m,
        actions: [
          ...m.actions,
          ActionItem(
            id: newRecordId(),
            agendaId: a.id,
            text: values[0],
            owner: values[1],
            dueDate: values[2].isEmpty ? null : values[2],
          ),
        ],
      ),
    ),
  );

  Widget _button(String text, VoidCallback? action, {Key? key}) {
    if (_ios) {
      return CupertinoButton(key: key, onPressed: action, child: Text(text));
    }
    if (_windows) {
      return fluent.Button(key: key, onPressed: action, child: Text(text));
    }
    return material.OutlinedButton(
      key: key,
      onPressed: action,
      child: Text(text),
    );
  }

  Widget _row(String text, VoidCallback action, {Key? key}) {
    if (_ios) {
      return CupertinoButton(
        key: key,
        alignment: Alignment.centerLeft,
        onPressed: action,
        child: Text(text),
      );
    }
    if (_windows) {
      return fluent.ListTile(key: key, title: Text(text), onPressed: action);
    }
    return material.ListTile(key: key, title: Text(text), onTap: action);
  }

  Future<void> _complete(Meeting meeting, ActionItem action) => _update(
    _copy(
      meeting,
      actions: [
        for (final item in meeting.actions)
          if (item.id == action.id)
            item.transition(ActionStatus.completed)
          else
            item,
      ],
    ),
  );

  Widget _dashboardView() {
    final actions = [
      for (final meeting in _ledger!.meetings)
        for (final action in meeting.actions)
          if (_actionFilter == null
              ? action.status != ActionStatus.completed
              : action.status == _actionFilter)
            (meeting, action),
    ];
    return ListView(
      key: const Key('action-dashboard'),
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Outstanding actions', style: TextStyle(fontSize: 22)),
        Wrap(
          spacing: 8,
          children: [
            for (final (label, filter) in [
              ('Open', null),
              ('Pending', ActionStatus.pending),
              ('Carried over', ActionStatus.carriedOver),
              ('Completed', ActionStatus.completed),
            ])
              _button(
                label,
                () => setState(() => _actionFilter = filter),
                key: Key('filter-${filter?.name ?? 'open'}'),
              ),
          ],
        ),
        if (actions.isEmpty) const Text('No actions in this view'),
        for (final (meeting, action) in actions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${action.text} · ${action.owner} · ${meeting.title}'
                  '${action.dueDate == null ? '' : ' · Due ${action.dueDate}'}'
                  ' · ${action.status.name}',
                ),
                if (action.status != ActionStatus.completed)
                  _button(
                    'Complete ${action.text}',
                    _busy
                        ? null
                        : () {
                            _complete(meeting, action);
                          },
                    key: Key('complete-${action.id}'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _meetings() => ListView(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: _button(
          'New meeting',
          _busy ? null : _newMeeting,
          key: const Key('new-meeting'),
        ),
      ),
      for (final m in _ledger!.meetings)
        _row(
          '${m.title} · ${m.date}',
          () => setState(() {
            _meetingId = m.id;
            _dashboard = false;
            _agendaId = null;
          }),
          key: Key('meeting-${m.id}'),
        ),
    ],
  );

  Widget _navigation() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _button(
        'Meetings',
        () => setState(() {
          _dashboard = false;
          _meetingId = null;
        }),
        key: const Key('nav-meetings'),
      ),
      _button(
        'Actions',
        () => setState(() {
          _dashboard = true;
          _meetingId = null;
        }),
        key: const Key('nav-actions'),
      ),
    ],
  );

  Widget _detail(Meeting m) {
    final selected =
        m.agenda.where((a) => a.id == _agendaId).firstOrNull ??
        m.agenda.firstOrNull;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('${m.title} · ${m.date}', style: const TextStyle(fontSize: 22)),
        _button(
          'Edit meeting',
          _busy ? null : () => _editMeeting(m),
          key: const Key('edit-meeting'),
        ),
        _button(
          'Add agenda item',
          _busy ? null : () => _addAgenda(m),
          key: const Key('add-agenda'),
        ),
        for (final a in m.agenda)
          _row(
            '${a.order + 1}. ${a.title}',
            () => setState(() => _agendaId = a.id),
            key: Key('agenda-${a.id}'),
          ),
        if (selected != null) ...[
          const SizedBox(height: 16),
          Text(
            'Agenda: ${selected.title}',
            style: const TextStyle(fontSize: 18),
          ),
          _button(
            'Record decision',
            _busy ? null : () => _addDecision(m, selected),
            key: const Key('add-decision'),
          ),
          for (final d in m.decisions.where((d) => d.agendaId == selected.id))
            Text('Decision: ${d.text}'),
          _button(
            'Add action',
            _busy ? null : () => _addAction(m, selected),
            key: const Key('add-action'),
          ),
          for (final a in m.actions.where(
            (a) => a.agendaId == selected.id,
          )) ...[
            Text(
              '${a.text} · ${a.owner}${a.dueDate == null ? '' : ' · ${a.dueDate}'} · ${a.status.name}',
            ),
            if (a.status == ActionStatus.pending)
              _button(
                'Carry over ${a.text}',
                _busy
                    ? null
                    : () {
                        _update(
                          _copy(
                            m,
                            actions: [
                              for (final item in m.actions)
                                if (item.id == a.id)
                                  item.transition(ActionStatus.carriedOver)
                                else
                                  item,
                            ],
                          ),
                        );
                      },
              ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = _meeting;
    final body = _ledger == null
        ? Center(
            child: Text(
              _error == null
                  ? 'Loading meetings…'
                  : 'Unable to open private meetings: $_error',
            ),
          )
        : LayoutBuilder(
            builder: (context, box) {
              if (box.maxWidth >= 720) {
                return Row(
                  children: [
                    SizedBox(
                      width: 260,
                      child: Column(
                        children: [
                          _navigation(),
                          const SizedBox(height: 1),
                          Expanded(child: _meetings()),
                        ],
                      ),
                    ),
                    const SizedBox(width: 1),
                    Expanded(
                      child: _dashboard
                          ? _dashboardView()
                          : (m == null
                                ? const Center(
                                    child: Text('Your private meeting space'),
                                  )
                                : _detail(m)),
                    ),
                  ],
                );
              }
              if (_dashboard) {
                return Column(
                  children: [
                    _navigation(),
                    Expanded(child: _dashboardView()),
                  ],
                );
              }
              if (m != null) {
                return Column(
                  children: [
                    _button(
                      'Back to meetings',
                      () => setState(() {
                        _meetingId = null;
                        _agendaId = null;
                      }),
                      key: const Key('back-meetings'),
                    ),
                    Expanded(child: _detail(m)),
                  ],
                );
              }
              return Column(
                children: [
                  _navigation(),
                  Expanded(child: _meetings()),
                ],
              );
            },
          );
    final content = Column(
      children: [
        if (_ledger != null && _error != null)
          Text('Save failed: $_error', key: const Key('save-error')),
        Expanded(child: body),
      ],
    );
    if (_ios) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Minute Keeper'),
        ),
        child: SafeArea(child: content),
      );
    }
    if (_windows) {
      return fluent.NavigationView(
        titleBar: const fluent.TitleBar(title: Text('Minute Keeper')),
        content: fluent.ScaffoldPage(content: content),
      );
    }
    return material.Scaffold(
      appBar: material.AppBar(title: const Text('Minute Keeper')),
      body: content,
    );
  }
}
