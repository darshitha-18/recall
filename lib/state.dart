import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'theme.dart';

class RecallState extends ChangeNotifier {
  static const _decksKey = 'recall.decks.v1';
  static const _darkKey = 'recall.dark';

  final List<Deck> _decks = [];
  List<Deck> get decks => List.unmodifiable(_decks);

  ThemeMode themeMode = ThemeMode.light;
  bool get isDark => themeMode == ThemeMode.dark;

  // The deck currently being reviewed on the preview screen.
  String draftTitle = '';
  final List<Flashcard> draft = [];

  int get totalCards => _decks.fold(0, (sum, d) => sum + d.cards.length);
  int get totalStudied => _decks.fold(0, (sum, d) => sum + d.studied);

  Deck? deckById(String id) {
    for (final d in _decks) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode =
        (prefs.getBool(_darkKey) ?? false) ? ThemeMode.dark : ThemeMode.light;
    final raw = prefs.getString(_decksKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _decks
          ..clear()
          ..addAll(list
              .map((e) => Deck.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (_) {
        _decks.clear();
      }
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _decksKey, jsonEncode(_decks.map((d) => d.toJson()).toList()));
  }

  void toggleTheme() {
    themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setBool(_darkKey, isDark));
  }

  // ---- draft handling ----

  void setDraft(String title, List<Flashcard> cards) {
    draftTitle = title;
    draft
      ..clear()
      ..addAll(cards);
    notifyListeners();
  }

  void updateDraftCard(int index, String question, String answer) {
    draft[index]
      ..question = question
      ..answer = answer;
    notifyListeners();
  }

  void removeDraftCard(int index) {
    draft.removeAt(index);
    notifyListeners();
  }

  void saveDraft() {
    if (draft.isEmpty) return;
    _decks.insert(
      0,
      Deck(
        id: newId(),
        title: draftTitle,
        colorIndex: _decks.length % Pal.deckColors.length,
        cards: List.of(draft),
      ),
    );
    draft.clear();
    draftTitle = '';
    notifyListeners();
    _persist();
  }

  // ---- study progress ----

  void recordSession(String deckId, int known, int studied) {
    final deck = deckById(deckId);
    if (deck == null || studied == 0) return;
    deck.studied += studied;
    deck.mastered = known;
    notifyListeners();
    _persist();
  }
}
