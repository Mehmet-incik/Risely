import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/mood_entry.dart';

// Local-first senkronizasyon: SharedPreferences her zaman birincil kaynak kalır,
// bu servis sadece arka planda Firestore'a yansıtma/oradan çekme işini yapar.
// Push'lar fire-and-forget çağrılır (TaskStore'un yerel kaydını asla bloklamaz),
// pull ise girişte (loadData) tek seferlik çağrılır — sürekli dinleme (stream) yok.
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

  static DocumentReference<Map<String, dynamic>>? get _settingsDoc {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('profile');
  }

  // Yerel görev listesini Firestore'a olduğu gibi yansıtır (silinenler dahil).
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
      debugPrint('FirestoreSyncService.pushTasks başarısız (çevrimdışı olabilir): $e');
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
      debugPrint('FirestoreSyncService.pushMoods başarısız (çevrimdışı olabilir): $e');
    }
  }

  static Future<void> pushSettings(Map<String, dynamic> settings) async {
    final doc = _settingsDoc;
    if (doc == null) return;
    try {
      await doc.set(settings);
    } catch (e) {
      debugPrint('FirestoreSyncService.pushSettings başarısız (çevrimdışı olabilir): $e');
    }
  }

  // Buluttaki görevleri tek seferlik çeker. Hata/çevrimdışı durumunda null döner
  // (TaskStore bu durumda yerel veriyle devam eder).
  static Future<List<Task>?> pullTasks() async {
    final col = _tasksCol;
    if (col == null) return null;
    try {
      final snapshot = await col.get();
      return snapshot.docs.map((d) => Task.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('FirestoreSyncService.pullTasks başarısız (çevrimdışı olabilir): $e');
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
      debugPrint('FirestoreSyncService.pullMoods başarısız (çevrimdışı olabilir): $e');
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
      debugPrint('FirestoreSyncService.pullSettings başarısız (çevrimdışı olabilir): $e');
      return null;
    }
  }

  static String _moodDocId(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
