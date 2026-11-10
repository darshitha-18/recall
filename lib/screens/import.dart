import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../generator.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  static const _maxBytes = 1024 * 1024;

  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  String? _fileName;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.size > _maxBytes) {
        setState(() => _error = 'That file is over 1 MB. Try a smaller one.');
        return;
      }
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _error = 'Could not read that file. Try another one.');
        return;
      }
      setState(() {
        _notes.text = utf8.decode(bytes, allowMalformed: true);
        _fileName = file.name;
        _error = null;
        if (_title.text.trim().isEmpty) {
          _title.text = file.name.replaceAll(RegExp(r'\.txt$', caseSensitive: false), '');
        }
      });
    } catch (_) {
      setState(() => _error = 'Something went wrong opening that file.');
    }
  }

  void _generate() {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final cards = Generator.generate(_notes.text);
    if (cards.isEmpty) {
      setState(() => _error =
          'No cards could be made from these notes. Try “Term: Definition” lines or short factual sentences like “The heart is a muscular organ.”');
      return;
    }
    context.read<RecallState>().setDraft(_title.text.trim(), cards);
    Navigator.pushNamed(context, '/preview');
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);

    return AppShell(
      route: '/import',
      child: LayoutBuilder(builder: (context, c) {
        final narrow = c.maxWidth < 640;
        final pad = narrow ? 20.0 : 36.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, narrow ? 24 : 44, pad, 56),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Import notes',
                        style: T.serif(narrow ? 32 : 40, p.ink, h: 1.1, ls: -0.8)),
                    const SizedBox(height: 8),
                    Text(
                      'Upload a text file or paste your notes. Recall drafts the flashcards for you to review.',
                      style: T.sans(16, p.muted),
                    ),
                    const SizedBox(height: 32),
                    _UploadZone(fileName: _fileName, onTap: _pick),
                    const SizedBox(height: 28),
                    Row(children: [
                      Expanded(child: Divider(color: p.border, height: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('OR PASTE YOUR NOTES', style: T.label(p.muted)),
                      ),
                      Expanded(child: Divider(color: p.border, height: 1)),
                    ]),
                    const SizedBox(height: 28),
                    _FieldLabel('Deck title'),
                    TextFormField(
                      controller: _title,
                      textInputAction: TextInputAction.next,
                      style: T.sans(15, p.ink),
                      decoration:
                          const InputDecoration(hintText: 'e.g. Cell biology, week 3'),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Give your deck a title.';
                        if (t.length > 60) return 'Keep the title under 60 characters.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    _FieldLabel('Notes'),
                    TextFormField(
                      controller: _notes,
                      minLines: 9,
                      maxLines: 16,
                      keyboardType: TextInputType.multiline,
                      style: T.sans(15, p.ink, h: 1.6),
                      decoration: const InputDecoration(
                        hintMaxLines: 4,
                        hintText:
                            'Mitochondria: the organelle that produces most of a cell’s energy.\n\nPhotosynthesis is the process plants use to convert light into chemical energy.',
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Add some notes first.';
                        if (t.length < 20) {
                          return 'These notes are very short. Add a few full lines.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tip: write definitions as Term: Definition, or use short factual sentences.',
                      style: T.sans(13, p.muted),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: T.sans(13.5, p.bad, h: 1.5)),
                    ],
                    const SizedBox(height: 28),
                    AppButton(
                      label: 'Generate flashcards',
                      icon: LucideIcons.layers,
                      large: true,
                      expand: narrow,
                      onPressed: _generate,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: T.sans(13.5, p.ink, w: FontWeight.w600)),
    );
  }
}

class _UploadZone extends StatelessWidget {
  const _UploadZone({required this.fileName, required this.onTap});
  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final loaded = fileName != null;

    return Semantics(
      button: true,
      label: 'Upload a .txt file',
      child: HoverBox(
        onTap: onTap,
        builder: (context, hover) => CustomPaint(
          painter: DashedRRectPainter(
            color: hover || loaded ? p.accent : tint(p.ink, .28),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
            decoration: BoxDecoration(
              color: hover ? p.accentSoft : tint(p.surface, .6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    loaded ? LucideIcons.fileText : LucideIcons.upload,
                    size: 20,
                    color: p.accent,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  loaded ? fileName! : 'Upload a .txt file',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.sans(16, p.ink, w: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  loaded
                      ? 'Loaded into the notes below. Click to replace.'
                      : 'Click to browse your files',
                  textAlign: TextAlign.center,
                  style: T.sans(14, p.muted),
                ),
                const SizedBox(height: 14),
                Text('TXT ONLY  ·  UP TO 1 MB', style: T.label(p.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
