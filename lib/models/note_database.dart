import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'note.dart';

class NoteDatabase extends ChangeNotifier {
  static late Isar isar;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    final dir = Platform.isAndroid || Platform.isIOS
        ? await getApplicationDocumentsDirectory()
        : await getTemporaryDirectory();

    isar = await Isar.open([NoteSchema], directory: dir.path);
    _isInitialized = true;
  }

  final List<Note> currentNotes = [];

  Future<void> addNote(String textFromUser) async {
    if (!_isInitialized) return;

    final trimmedText = textFromUser.trim();
    if (trimmedText.isEmpty) return;

    final newNote = Note()..text = trimmedText;

    await isar.writeTxn(() async {
      await isar.notes.put(newNote);
    });

    await fetchNotes();
  }

  Future<void> fetchNotes() async {
    if (!_isInitialized) {
      currentNotes.clear();
      notifyListeners();
      return;
    }

    final fetchedNotes = await isar.notes.where().findAll();
    currentNotes
      ..clear()
      ..addAll(fetchedNotes);
    notifyListeners();
  }

  Future<void> updateNote(int id, String newText) async {
    if (!_isInitialized) return;

    final trimmedText = newText.trim();
    if (trimmedText.isEmpty) return;

    final existingNote = await isar.notes.get(id);
    if (existingNote != null) {
      existingNote.text = trimmedText;

      await isar.writeTxn(() async {
        await isar.notes.put(existingNote);
      });

      await fetchNotes();
    }
  }

  Future<void> deleteNote(int id) async {
    if (!_isInitialized) return;

    await isar.writeTxn(() async {
      await isar.notes.delete(id);
    });

    await fetchNotes();
  }
}
