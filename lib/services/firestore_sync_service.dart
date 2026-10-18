import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/mood_entry.dart';
import '../models/focus_session.dart';

class FirestoreSyncService {
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>>? get _tasksCol {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('tasks');
  }

  static CollectionReference<Map<String, dynamic>>? get _moodsCol {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('moods');
  }

  static CollectionReference<Map<String, dynamic>>? get _focusCol {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('focus_sessions');
  }

  static DocumentReference<Map<String, dynamic>>? get _settingsDoc {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('profile');
  }

  static Future<void> pushTasks(List<Task> tasks) async {
    final col = _tasksCol;
    if (col == null) return;
    try {
      final cloudSnapshot = await col.get();
      final cloudIds = cloudSnapshot.docs.map((d) => d.id).toSet();
      final localIds = tasks.map((t) => t.id).toSet();

      final batch = FirebaseFirestore.instance.batch();
      for (final task in tasks) {
        batch.set(col.doc(task.id), task.toJson());
      }
      for (final staleId in cloudIds.difference(localIds)) {
        batch.delete(col.doc(staleId));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreSyncService.pushTasks başarısız: $e');
    }
  }

  static Future<void> pushMoods(List<MoodEntry> moods) async {
    final col = _moodsCol;
    if (col == null) return;
    try {
      final cloudSnapshot = await col.get();
      final cloudIds = cloudSnapshot.docs.map((d) => d.id).toSet();
      final localIds = moods.map((m) => _moodDocId(m.date)).toSet();

      final batch = FirebaseFirestore.instance.batch();
      for (final mood in moods) {
        batch.set(col.doc(_moodDocId(mood.date)), mood.toJson());
      }
      for (final staleId in cloudIds.difference(localIds)) {
        batch.delete(col.doc(staleId));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreSyncService.pushMoods başarısız: $e');
    }
  }

  static Future<void> pushFocusSessions(List<FocusSession> sessions) async {
    final col = _focusCol;
    if (col == null) return;
    try {
      final cloudSnapshot = await col.get();
      final cloudIds = cloudSnapshot.docs.map((d) => d.id).toSet();
      final localIds = sessions.map((s) => s.id).toSet();

      final batch = FirebaseFirestore.instance.batch();
      for (final s in sessions) {
        batch.set(col.doc(s.id), s.toJson());
      }
      for (final staleId in cloudIds.difference(localIds)) {
        batch.delete(col.doc(staleId));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreSyncService.pushFocusSessions başarısız: $e');
    }
  }

  static Future<void> pushSettings(Map<String, dynamic> settings) async {
    final doc = _settingsDoc;
    if (doc == null) return;
    try {
      await doc.set(settings);
    } catch (e) {
      debugPrint('FirestoreSyncService.pushSettings başarısız: $e');
    }
  }

  static Future<List<Task>?> pullTasks() async {
    final col = _tasksCol;
    if (col == null) return null;
    try {
      final snapshot = await col.get();
      return snapshot.docs.map((d) => Task.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('FirestoreSyncService.pullTasks başarısız: $e');
      return null;
    }
  }

  static Future<List<MoodEntry>?> pullMoods() async {
    final col = _moodsCol;
    if (col == null) return null;
    try {
      final snapshot = await col.get();
      return snapshot.docs.map((d) => MoodEntry.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('FirestoreSyncService.pullMoods başarısız: $e');
      return null;
    }
  }

  static Future<List<FocusSession>?> pullFocusSessions() async {
    final col = _focusCol;
    if (col == null) return null;
    try {
      final snapshot = await col.get();
      return snapshot.docs.map((d) => FocusSession.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('FirestoreSyncService.pullFocusSessions başarısız: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> pullSettings() async {
    final doc = _settingsDoc;
    if (doc == null) return null;
    try {
      final snapshot = await doc.get();
      return snapshot.data();
    } catch (e) {
      debugPrint('FirestoreSyncService.pullSettings başarısız: $e');
      return null;
    }
  }

  static String _moodDocId(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}