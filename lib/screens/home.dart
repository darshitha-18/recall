import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<RecallState>();
    final p = Pal.of(context);

    return AppShell(
      route: '/',
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final narrow = w < 640;
        final pad = narrow ? 20.0 : 36.0;
        final cols = w >= 900 ? 3 : (w >= 560 ? 2 : 1);
        final gap = narrow ? 10.0 : 16.0;
        final hasDecks = s.decks.isNotEmpty;

        final importButton = AppButton(
          label: 'Import notes',
          icon: LucideIcons.upload,
          expand: narrow,
          onPressed: () => Navigator.pushNamed(context, '/import'),
        );

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_greeting()}.',
                style: T.serif(narrow ? 32 : 40, p.ink, h: 1.1, ls: -0.8)),
            const SizedBox(height: 8),
            Text(
              hasDecks
                  ? 'Pick a deck and pick up where you left off.'
                  : 'Turn your notes into flashcards you can actually remember.',
              style: T.sans(16, p.muted),
            ),
          ],
        );

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, narrow ? 24 : 44, pad, 56),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (narrow) ...[
                    titleBlock,
                    const SizedBox(height: 20),
                    importButton,
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: titleBlock),
                        const SizedBox(width: 24),
                        importButton,
                      ],
                    ),
                  const SizedBox(height: 32),
                  Row(children: [
                    Expanded(
                      child: StatTile(
                        label: narrow ? 'Decks' : 'Total decks',
                        value: '${s.decks.length}',
                        compact: narrow,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: StatTile(
                        label: narrow ? 'Cards' : 'Total flashcards',
                        value: '${s.totalCards}',
                        compact: narrow,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: StatTile(
                        label: narrow ? 'Studied' : 'Cards studied',
                        value: '${s.totalStudied}',
                        compact: narrow,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 40),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('Your decks', style: T.serif(24, p.ink)),
                      const SizedBox(width: 10),
                      if (hasDecks)
                        Text('${s.decks.length}',
                            style: T.sans(14, p.muted, w: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (hasDecks)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 176,
                      ),
                      itemCount: s.decks.length,
                      itemBuilder: (context, i) => FadeSlideIn(
                        index: i,
                        child: _DeckCard(deck: s.decks[i]),
                      ),
                    )
                  else
                    const _EmptyState(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.deck});
  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final color = Pal.deckColors[deck.colorIndex % Pal.deckColors.length];
    final pct = (deck.progress * 100).round();

    return Semantics(
      button: true,
      label: 'Study ${deck.title}',
      child: HoverBox(
        onTap: () => Navigator.pushNamed(context, '/study', arguments: deck.id),
        builder: (context, hover) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, hover ? -2 : 0, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: hover ? tint(p.ink, .35) : p.border),
            boxShadow: [
              BoxShadow(
                color: p.shadow,
                blurRadius: hover ? 18 : 2,
                offset: Offset(0, hover ? 8 : 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${deck.cards.length} ${deck.cards.length == 1 ? 'card' : 'cards'}',
                  style: T.label(p.muted),
                ),
                const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: hover ? 1 : 0,
                  child: Icon(LucideIcons.arrowRight, size: 16, color: p.ink),
                ),
              ]),
              const SizedBox(height: 14),
              Text(
                deck.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: T.serif(21, p.ink, h: 1.2),
              ),
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: deck.progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 4,
                    backgroundColor: p.border,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                deck.studied == 0 ? 'Not studied yet' : '$pct% known',
                style: T.sans(12.5, p.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  Widget _sheet(Pal p, {bool accent = false}) => Container(
        width: 88,
        height: 60,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(color: p.shadow, blurRadius: 3, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 28,
                height: 4,
                color: accent ? p.accent : p.border),
            const SizedBox(height: 6),
            Container(width: 56, height: 3, color: p.border),
            const SizedBox(height: 5),
            Container(width: 44, height: 3, color: p.border),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return CustomPaint(
      painter: DashedRRectPainter(color: p.border),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            SizedBox(
              width: 120,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(angle: -.14, child: _sheet(p)),
                  Transform.rotate(angle: .09, child: _sheet(p)),
                  _sheet(p, accent: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('No decks yet', style: T.serif(24, p.ink)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                'Paste some notes or upload a text file and Recall will draft your first deck in seconds.',
                textAlign: TextAlign.center,
                style: T.sans(15, p.muted),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Import notes',
              icon: LucideIcons.upload,
              onPressed: () => Navigator.pushNamed(context, '/import'),
            ),
          ],
        ),
      ),
    );
  }
}
