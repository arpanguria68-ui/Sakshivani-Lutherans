import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/repositories/favorites_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/reflection_repository.dart';
import '../data/repositories/sync_queue_repository.dart';

class SyncService {
  /// Caps every Firestore network call this service makes. Without this, an
  /// unreachable/misconfigured Firestore (e.g. the database not created yet
  /// for the project, or no network) leaves the underlying gRPC call
  /// retrying with backoff for a long time — and since [pullFromCloud] and
  /// [flushPendingQueue] run inline during app bootstrap, that hangs the
  /// splash screen instead of just skipping sync for this launch.
  static const Duration _networkTimeout = Duration(seconds: 8);

  /// After this many failed pushes, drop the queue item instead of retrying
  /// forever — prevents a permanently-bad payload from blocking the outbox.
  static const int maxQueueRetries = 5;

  SyncService({
    required SyncQueueRepository syncQueueRepository,
    required FavoritesRepository favoritesRepository,
    required ReflectionRepository reflectionRepository,
    required ProgressRepository progressRepository,
    required bool firebaseEnabled,
  })  : _syncQueueRepository = syncQueueRepository,
        _favoritesRepository = favoritesRepository,
        _reflectionRepository = reflectionRepository,
        _progressRepository = progressRepository,
        _firebaseEnabled = firebaseEnabled;

  final SyncQueueRepository _syncQueueRepository;
  final FavoritesRepository _favoritesRepository;
  final ReflectionRepository _reflectionRepository;
  final ProgressRepository _progressRepository;
  final bool _firebaseEnabled;

  /// Mirrors the "real account, sync unlocked" entitlement onto the user's
  /// Firestore doc — a cheap (one field, one write per sign-in), queryable
  /// record of who has cloud sync active, separate from deriving it live
  /// from the auth stream each time. Anonymous/local-guest users never call
  /// this (they have no authenticated [FirebaseAuth.instance.currentUser]).
  Future<void> setSyncEnabled(bool enabled) async {
    if (!_firebaseEnabled) {
      return;
    }
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
            <String, dynamic>{
              'sync_enabled': enabled,
              'sync_enabled_at': DateTime.now().toUtc().toIso8601String(),
            },
            SetOptions(merge: true),
          )
          .timeout(_networkTimeout);
    } catch (_) {
      // Best-effort mirror; the local flag and live auth state remain correct either way.
    }
  }

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
      if (item.retries >= maxQueueRetries) {
        await _syncQueueRepository.removeById(item.id);
        continue;
      }
      try {
        await _applyItem(user.uid, firestore, item).timeout(_networkTimeout);
        await _syncQueueRepository.removeById(item.id);
      } catch (_) {
        final int nextRetries = item.retries + 1;
        if (nextRetries >= maxQueueRetries) {
          await _syncQueueRepository.removeById(item.id);
        } else {
          await _syncQueueRepository.incrementRetry(item.id);
        }
      }
    }
  }

  /// Fetch this user's reflections, favorites, and prayer logs from
  /// Firestore and merge them into the local DB ("cloud wins" on
  /// overlapping records) — restores data after sign-in on a new
  /// device/reinstall, since [flushPendingQueue] only pushes local -> cloud.
  Future<void> pullFromCloud() async {
    if (!_firebaseEnabled) {
      return;
    }
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference<Map<String, dynamic>> userDoc =
        firestore.collection('users').doc(user.uid);

    try {
      final QuerySnapshot<Map<String, dynamic>> reflections =
          await userDoc.collection('reflections').get().timeout(_networkTimeout);
      await _reflectionRepository.mergeFromCloud(
        reflections.docs.map((d) => d.data()).toList(growable: false),
      );
    } catch (_) {
      // best-effort; a failed collection shouldn't block the others
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> favorites =
          await userDoc.collection('favorites').get().timeout(_networkTimeout);
      await _favoritesRepository.mergeFromCloud(
        favorites.docs.map((d) => d.data()).toList(growable: false),
      );
    } catch (_) {}

    try {
      final QuerySnapshot<Map<String, dynamic>> prayers =
          await userDoc.collection('progress_prayers').get().timeout(_networkTimeout);
      await _progressRepository.mergeFromCloud(
        prayers.docs.map((d) => d.data()).toList(growable: false),
      );
    } catch (_) {}
  }

  /// Deletes every document under this user's Firestore tree — irreversible,
  /// used only by account deletion right before the Firebase Auth user
  /// itself is deleted. Firestore has no client-side recursive delete, so
  /// each known subcollection is queried and batch-deleted individually.
  Future<void> deleteCloudUserData() async {
    if (!_firebaseEnabled) {
      return;
    }
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference<Map<String, dynamic>> userDoc =
        firestore.collection('users').doc(user.uid);

    for (final String collection in <String>[
      'reflections',
      'favorites',
      'favorite_index',
      'progress_prayers',
      'sync_audit',
    ]) {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await userDoc.collection(collection).get().timeout(_networkTimeout);
      if (snapshot.docs.isEmpty) {
        continue;
      }
      final WriteBatch batch = firestore.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit().timeout(_networkTimeout);
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
