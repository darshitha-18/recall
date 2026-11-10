int _idCounter = 0;
String newId() => '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

class Flashcard {
  Flashcard({required this.id, required this.question, required this.answer});

  final String id;
  String question;
  String answer;

  Map<String, dynamic> toJson() => {'id': id, 'q': question, 'a': answer};

  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
        id: j['id'] as String,
        question: j['q'] as String,
        answer: j['a'] as String,
      );
}

class Deck {
  Deck({
    required this.id,
    required this.title,
    required this.colorIndex,
    required this.cards,
    this.studied = 0,
    this.mastered = 0,
  });

  final String id;
  final String title;
  final int colorIndex;
  final List<Flashcard> cards;

  /// Total cards rated across all study sessions.
  int studied;

  /// Cards marked "known" in the most recent session.
  int mastered;

  double get progress =>
      cards.isEmpty ? 0 : (mastered / cards.length).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'color': colorIndex,
        'studied': studied,
        'mastered': mastered,
        'cards': cards.map((c) => c.toJson()).toList(),
      };

  factory Deck.fromJson(Map<String, dynamic> j) => Deck(
        id: j['id'] as String,
        title: j['title'] as String,
        colorIndex: j['color'] as int,
        studied: j['studied'] as int,
        mastered: j['mastered'] as int,
        cards: (j['cards'] as List)
            .map((e) => Flashcard.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// Arguments passed to the results route.
class ResultsArgs {
  const ResultsArgs({
    required this.deckId,
    required this.title,
    required this.known,
    required this.missed,
    required this.total,
  });

  final String deckId;
  final String title;
  final int known;
  final int missed;
  final int total;

  int get studied => known + missed;
}
