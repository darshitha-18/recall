import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.deckId});
  final String deckId;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final Deck? _deck = context.read<RecallState>().deckById(widget.deckId);

  int _i = 0;
  bool _showAnswer = false;
  final Map<int, bool> _ratings = {};

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _showAnswer = !_showAnswer);
    _showAnswer ? _flip.forward() : _flip.reverse();
  }

  void _go(int to) {
    setState(() {
      _i = to;
      _showAnswer = false;
    });
    _flip.value = 0;
  }

  void _rate(bool known) {
    setState(() => _ratings[_i] = known);
    if (_i == _deck!.cards.length - 1) {
      _finish();
    } else {
      _go(_i + 1);
    }
  }

  void _finish() {
    final deck = _deck!;
    final known = _ratings.values.where((v) => v).length;
    final missed = _ratings.length - known;
    context.read<RecallState>().recordSession(deck.id, known, known + missed);
    Navigator.pushReplacementNamed(
      context,
      '/results',
      arguments: ResultsArgs(
        deckId: deck.id,
        title: deck.title,
        known: known,
        missed: missed,
        total: deck.cards.length,
      ),
    );
  }

  void _exit() =>
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final deck = _deck;

    if (deck == null) {
      return Scaffold(
        body: Center(
          child: AppButton(label: 'Back home', onPressed: _exit),
        ),
      );
    }

    final n = deck.cards.length;
    final card = deck.cards[_i];
    final isLast = _i == n - 1;
    final rated = _ratings[_i];

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final pad = c.maxWidth < 640 ? 20.0 : 32.0;
          final cardHeight = (c.maxHeight - 250).clamp(260.0, 460.0);

          return Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad - 8, 12, pad, 10),
              child: Row(children: [
                AppIconButton(
                    icon: LucideIcons.x,
                    tooltip: 'Exit study mode',
                    onPressed: _exit),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(deck.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: T.sans(14.5, p.ink, w: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                Text('${_i + 1} / $n',
                    style: T.sans(14, p.muted, w: FontWeight.w500)),
              ]),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (_i + 1) / n),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 4,
                    backgroundColor: p.border,
                    valueColor: AlwaysStoppedAnimation(p.accent),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: pad, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: cardHeight,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: KeyedSubtree(
                              key: ValueKey(_i),
                              child: FlipCard(
                                animation: _flip,
                                question: card.question,
                                answer: card.answer,
                                onTap: _toggle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!_showAnswer)
                          AppButton(
                            label: 'Reveal answer',
                            icon: LucideIcons.eye,
                            large: true,
                            expand: true,
                            onPressed: _toggle,
                          )
                        else
                          Row(children: [
                            Expanded(
                              child: AppButton(
                                label: 'Missed',
                                icon: LucideIcons.x,
                                kind: BtnKind.secondary,
                                color: p.bad,
                                large: true,
                                onPressed: () => _rate(false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton(
                                label: 'Got it',
                                icon: LucideIcons.check,
                                large: true,
                                onPressed: () => _rate(true),
                              ),
                            ),
                          ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          AppButton(
                            label: 'Previous',
                            icon: LucideIcons.arrowLeft,
                            kind: BtnKind.ghost,
                            onPressed: _i == 0 ? null : () => _go(_i - 1),
                          ),
                          Expanded(
                            child: Text(
                              rated == null
                                  ? ''
                                  : (rated ? 'Marked as known' : 'Marked as difficult'),
                              textAlign: TextAlign.center,
                              style: T.sans(12.5, p.muted),
                            ),
                          ),
                          AppButton(
                            label: isLast ? 'Finish' : 'Next',
                            trailingIcon: LucideIcons.arrowRight,
                            kind: BtnKind.ghost,
                            onPressed: isLast ? _finish : () => _go(_i + 1),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

/// A paper-like card that flips around the Y axis.
class FlipCard extends StatelessWidget {
  const FlipCard({
    super.key,
    required this.animation,
    required this.question,
    required this.answer,
    required this.onTap,
  });

  final Animation<double> animation;
  final String question;
  final String answer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);

    Widget sheet() => Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.border),
          ),
        );

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              // Loose sheets stacked behind the card.
              Positioned(left: 16, right: 16, top: 14, bottom: -14, child: sheet()),
              Positioned(left: 8, right: 8, top: 7, bottom: -7, child: sheet()),
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final angle = Curves.easeInOutCubic.transform(animation.value) * math.pi;
                  final showBack = angle > math.pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(angle),
                    child: showBack
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(math.pi),
                            child: _Face(label: 'Answer', text: answer, isAnswer: true),
                          )
                        : _Face(label: 'Question', text: question, isAnswer: false),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.label, required this.text, required this.isAnswer});
  final String label;
  final String text;
  final bool isAnswer;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final size = text.length > 140 ? 21.0 : (text.length > 70 ? 25.0 : 30.0);

    return Container(
      decoration: BoxDecoration(
        color: isAnswer ? Color.lerp(p.surface, p.accent, .06) : p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 2, offset: const Offset(0, 1)),
          BoxShadow(color: p.shadow, blurRadius: 28, offset: const Offset(0, 14)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _RulePainter(tint(p.border, .6)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 6,
                    height: 6,
                    color: isAnswer ? p.accent : p.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(label.toUpperCase(),
                      style: T.label(isAnswer ? p.accent : p.muted)),
                ]),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(text,
                            style: T.serif(size, p.ink,
                                w: FontWeight.w500, h: 1.35, ls: -0.2)),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(isAnswer ? 'Tap to flip back' : 'Tap to flip',
                      style: T.sans(12, p.muted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RulePainter extends CustomPainter {
  _RulePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = 84.0; y < size.height - 24; y += 34) {
      canvas.drawLine(Offset(24, y), Offset(size.width - 24, y), paint);
    }
  }

  @override
  bool shouldRepaint(_RulePainter old) => old.color != color;
}
