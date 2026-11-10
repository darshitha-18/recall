import 'models.dart';

/// Simple rule-based flashcard generation.
///  - "Term: Definition" lines become "What is Term?" cards.
///  - Short explanatory sentences become fill-in-the-blank cards.
class Generator {
  static final _termLine =
      RegExp(r'^(?:[-*•]|\d+[.)])?\s*([^:\n]{2,60}?)\s*:\s*(\S.{2,})$');
  static final _linking = RegExp(
      r'\b(is|are|was|were|means|refers to|called|known as|consists of|contains|produces|uses|provides)\b',
      caseSensitive: false);
  static final _sentence = RegExp(r'[^.!?]+[.!?]?');
  static final _strip = RegExp(r'[^\p{L}\p{N}\-]', unicode: true);

  static const _stop = {
    'which', 'their', 'there', 'these', 'those', 'about', 'would', 'could',
    'should', 'where', 'while', 'being', 'other', 'because', 'through',
    'between', 'called', 'known', 'means', 'using', 'after', 'before',
    'under', 'every', 'among', 'within', 'without', 'refers', 'contains',
    'consists', 'produces', 'provides', 'usually', 'often', 'since',
  };

  static List<Flashcard> generate(String text, {int max = 40}) {
    final cards = <Flashcard>[];
    final seen = <String>{};

    void add(String q, String a) {
      if (cards.length >= max) return;
      if (seen.add(q.toLowerCase())) {
        cards.add(Flashcard(id: newId(), question: q, answer: a));
      }
    }

    for (final raw in text.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      final m = _termLine.firstMatch(line);
      if (m != null) {
        final term = m.group(1)!.trim();
        final def = m.group(2)!.trim();
        final wordCount = term.split(RegExp(r'\s+')).length;
        if (wordCount <= 6 && !RegExp(r'\d$').hasMatch(term)) {
          add('What is $term?', def);
          continue;
        }
      }

      for (final match in _sentence.allMatches(line)) {
        _blank(match.group(0)!.trim(), add);
      }
    }
    return cards;
  }

  static void _blank(String sentence, void Function(String, String) add) {
    final words = sentence.split(RegExp(r'\s+'));
    if (words.length < 6 || words.length > 30 || !_linking.hasMatch(sentence)) {
      return;
    }
    var best = -1;
    var bestLen = 0;
    for (var i = 1; i < words.length; i++) {
      final core = words[i].replaceAll(_strip, '');
      if (core.length < 5 || _stop.contains(core.toLowerCase())) continue;
      if (core.length > bestLen) {
        best = i;
        bestLen = core.length;
      }
    }
    if (best < 0) return;
    final target = words[best].replaceAll(_strip, '');
    words[best] = words[best].replaceFirst(target, '_____');
    add('Fill in the blank: ${words.join(' ')}', target);
  }
}
