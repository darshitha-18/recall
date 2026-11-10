import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  Future<void> _edit(BuildContext context, int index) async {
    final state = context.read<RecallState>();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => _EditDialog(card: state.draft[index]),
    );
    if (result != null) state.updateDraftCard(index, result[0], result[1]);
  }

  void _save(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    context.read<RecallState>().saveDraft();
    messenger.showSnackBar(const SnackBar(content: Text('Deck saved')));
    nav.pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<RecallState>();
    final p = Pal.of(context);
    final cards = s.draft;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final narrow = c.maxWidth < 640;
          final pad = narrow ? 20.0 : 32.0;

          final header = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${cards.length} ${cards.length == 1 ? 'CARD' : 'CARDS'} GENERATED',
                  style: T.label(p.accent)),
              const SizedBox(height: 10),
              Text('Review your cards',
                  style: T.serif(narrow ? 30 : 38, p.ink, h: 1.1, ls: -0.7)),
              const SizedBox(height: 8),
              Text(
                'From “${s.draftTitle}”. Edit anything that reads wrong, or delete cards you don’t need.',
                style: T.sans(15.5, p.muted),
              ),
            ],
          );

          final back = AppButton(
            label: 'Back',
            icon: LucideIcons.arrowLeft,
            kind: BtnKind.secondary,
            expand: narrow,
            onPressed: () => Navigator.pop(context),
          );
          final save = AppButton(
            label: 'Save deck',
            icon: LucideIcons.check,
            expand: narrow,
            onPressed: cards.isEmpty ? null : () => _save(context),
          );

          return Column(children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(pad, narrow ? 24 : 40, pad, 24),
                    itemCount: cards.isEmpty ? 2 : cards.length + 1,
                    separatorBuilder: (context, i) =>
                        SizedBox(height: i == 0 ? 24 : 12),
                    itemBuilder: (context, i) {
                      if (i == 0) return header;
                      if (cards.isEmpty) {
                        return Surface(
                          child: Text(
                            'No cards left. Go back to generate a new set.',
                            style: T.sans(15, p.muted),
                          ),
                        );
                      }
                      final card = cards[i - 1];
                      return _CardTile(
                        key: ValueKey(card.id),
                        index: i - 1,
                        card: card,
                        onEdit: () => _edit(context, i - 1),
                        onDelete: () =>
                            context.read<RecallState>().removeDraftCard(i - 1),
                      );
                    },
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: 14),
              decoration: BoxDecoration(
                color: p.bg,
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: narrow
                      ? Row(children: [
                          Expanded(child: back),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: save),
                        ])
                      : Row(children: [back, const Spacer(), save]),
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    super.key,
    required this.index,
    required this.card,
    required this.onEdit,
    required this.onDelete,
  });
  final int index;
  final Flashcard card;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Surface(
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Text((index + 1).toString().padLeft(2, '0'),
                style: T.serif(16, p.muted, w: FontWeight.w500)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QUESTION', style: T.label(p.muted)),
                const SizedBox(height: 6),
                Text(card.question,
                    style: T.sans(16, p.ink, w: FontWeight.w600, h: 1.4)),
                const SizedBox(height: 14),
                Text('ANSWER', style: T.label(p.accent)),
                const SizedBox(height: 6),
                Text(card.answer, style: T.sans(15, p.ink, h: 1.55)),
              ],
            ),
          ),
          Column(children: [
            AppIconButton(
                icon: LucideIcons.pencil, tooltip: 'Edit card', onPressed: onEdit),
            AppIconButton(
                icon: LucideIcons.trash2,
                tooltip: 'Delete card',
                onPressed: onDelete),
          ]),
        ],
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.card});
  final Flashcard card;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  final _form = GlobalKey<FormState>();
  late final _q = TextEditingController(text: widget.card.question);
  late final _a = TextEditingController(text: widget.card.answer);

  @override
  void dispose() {
    _q.dispose();
    _a.dispose();
    super.dispose();
  }

  String? _required(String? v, String what) =>
      (v == null || v.trim().isEmpty) ? 'Please enter the $what.' : null;

  void _submit() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, [_q.text.trim(), _a.text.trim()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Dialog(
      backgroundColor: p.surface,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit card', style: T.serif(24, p.ink)),
                  const SizedBox(height: 20),
                  Text('Question', style: T.sans(13.5, p.ink, w: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _q,
                    minLines: 2,
                    maxLines: 5,
                    style: T.sans(15, p.ink),
                    validator: (v) => _required(v, 'question'),
                  ),
                  const SizedBox(height: 16),
                  Text('Answer', style: T.sans(13.5, p.ink, w: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _a,
                    minLines: 2,
                    maxLines: 5,
                    style: T.sans(15, p.ink),
                    validator: (v) => _required(v, 'answer'),
                  ),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    AppButton(
                      label: 'Cancel',
                      kind: BtnKind.secondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    AppButton(label: 'Save changes', onPressed: _submit),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
