import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.args});
  final ResultsArgs args;

  String get _headline {
    if (args.studied == 0) return 'No cards rated.';
    final pct = args.known / args.studied;
    if (pct >= .8) return 'Strong recall.';
    if (pct >= .5) return 'Getting there.';
    return 'Worth another pass.';
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final pct = args.studied == 0 ? 0.0 : args.known / args.studied;

    final again = AppButton(
      label: 'Study again',
      icon: LucideIcons.rotateCcw,
      expand: true,
      onPressed: () =>
          Navigator.pushReplacementNamed(context, '/study', arguments: args.deckId),
    );
    final home = AppButton(
      label: 'Back home',
      icon: LucideIcons.home,
      kind: BtnKind.secondary,
      expand: true,
      onPressed: () =>
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
    );

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('SESSION COMPLETE', style: T.label(p.accent)),
                  const SizedBox(height: 12),
                  Text(_headline,
                      textAlign: TextAlign.center,
                      style: T.serif(40, p.ink, h: 1.1, ls: -0.8)),
                  const SizedBox(height: 8),
                  Text(args.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: T.sans(15.5, p.muted)),
                  const SizedBox(height: 32),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => SizedBox(
                      width: 184,
                      height: 184,
                      child: CustomPaint(
                        painter: _RingPainter(
                            value: v, track: p.border, color: p.accent),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${(v * 100).round()}%',
                                  style: T.serif(46, p.ink, h: 1)),
                              const SizedBox(height: 6),
                              Text('KNOWN', style: T.label(p.muted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(children: [
                    Expanded(
                        child: StatTile(
                            label: 'Studied',
                            value: '${args.studied}',
                            compact: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: StatTile(
                            label: 'Known',
                            value: '${args.known}',
                            valueColor: p.good,
                            compact: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: StatTile(
                            label: 'Difficult',
                            value: '${args.missed}',
                            valueColor: p.bad,
                            compact: true)),
                  ]),
                  const SizedBox(height: 32),
                  LayoutBuilder(builder: (context, c) {
                    return c.maxWidth < 380
                        ? Column(children: [again, const SizedBox(height: 12), home])
                        : Row(children: [
                            Expanded(child: again),
                            const SizedBox(width: 12),
                            Expanded(child: home),
                          ]);
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track, required this.color});
  final double value;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = const Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
    paint.color = color;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.track != track || old.color != color;
}
