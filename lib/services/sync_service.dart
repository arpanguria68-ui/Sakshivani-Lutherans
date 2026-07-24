import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/repositories/sync_queue_repository.dart';

class SyncService {
  SyncService({
    required SyncQueueRepository syncQueueRepository,
    required bool firebaseEnabled,
  })  : _syncQueueRepository = syncQueueRepository,
        _firebaseEnabled = firebaseEnabled;

  final SyncQueueRepository _syncQueueRepository;
  final bool _firebaseEnabled;

  Future<void> flushPendingQueue() async {
    if (!_firebaseEnabled) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final List<SyncQueueItem> pending = await _syncQueueRepository.pending(limit: 100);

    for (final SyncQueueItem item in pending) {
      try {
        await _applyItem(user.uid, firestore, item);
        await _syncQueueRepository.removeById(item.id);
      } catch (_) {
        await _syncQueueRepository.incrementRetry(item.id);
      }
    }
  }

  Future<void> _applyItem(
    String uid,
    FirebaseFirestore firestore,
    SyncQueueItem item,
  ) async {
    switch (item.type) {
      case 'prayer_log_upsert':
        await firestore
            .collection('users')
            .doc(uid)
            .collection('progress_prayers')
            .doc(item.payload['date_iso'] as String)
            .set(item.payload, SetOptions(merge: true));
        break;
      case 'reflection_upsert':
        await firestore
            .collection('users')
            .doc(uid)
            .collection('reflections')
            .doc(item.payload['id'] as String)
            .set(item.payload, SetOptions(merge: true));
        break;
      case 'reflection_delete':
        await firestore
            .collection('users')
            .doc(uid)
            .collection('reflections')
            .doc(item.payload['id'] as String)
            .delete();
        break;
      case 'favorite_upsert':
        final String composite =
            '${item.payload['item_type']}::${item.payload['item_ref']}';
        await firestore
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .doc(item.payload['id'] as String)
            .set(item.payload, SetOptions(merge: true));
        await firestore
            .collection('users')
            .doc(uid)
            .collection('favorite_index')
            .doc(composite)
            .set(item.payload, SetOptions(merge: true));
        break;
      case 'favorite_delete':
        final String composite =
            '${item.payload['item_type']}::${item.payload['item_ref']}';
        final String? favoriteId = item.payload['id'] as String?;
        if (favoriteId != null && favoriteId.isNotEmpty) {
          await firestore
              .collection('users')
              .doc(uid)
              .collection('favorites')
              .doc(favoriteId)
              .delete();
        }
        await firestore.collection('users').doc(uid).collection('favorite_index').doc(composite).delete();
        break;
      default:
        await firestore.collection('users').doc(uid).collection('sync_audit').add(<String, dynamic>{
          'type': item.type,
          'payload': json.encode(item.payload),
          'skipped_at': DateTime.now().toUtc().toIso8601String(),
        });
    }
  }
}
