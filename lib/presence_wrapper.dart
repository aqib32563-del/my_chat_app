import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceWrapper extends StatefulWidget {
  final Widget child;
  const PresenceWrapper({super.key, required this.child});
  @override
  State<PresenceWrapper> createState() => _PresenceWrapperState();
}

class _PresenceWrapperState extends State<PresenceWrapper>
    with WidgetsBindingObserver {
  final db = FirebaseFirestore.instance;
  final me = FirebaseAuth.instance.currentUser!.uid;
  Timer? timer;
  StreamSubscription? chatSub;
  bool active = true;

  Future<void> setOnline(bool online) async {
    try {
      await db.collection('users_public').doc(me).set({
        'online': online,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> markDelivered(QuerySnapshot<Map<String, dynamic>> snap) async {
    for (final d in snap.docs) {
      if (d.data()['lastSenderId'] == me) continue;
      try {
        final q = await d.reference
            .collection('messages')
            .where('delivered', isEqualTo: false)
            .get();
        final batch = db.batch();
        var n = 0;
        for (final m in q.docs) {
          if (m.data()['senderId'] != me) {
            batch.update(m.reference, {'delivered': true});
            n++;
          }
        }
        if (n > 0) await batch.commit();
      } catch (_) {}
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setOnline(true);
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (active) setOnline(true);
    });
    chatSub = db
        .collection('chats')
        .where('members', arrayContains: me)
        .snapshots()
        .listen(markDelivered);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    setOnline(active);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    chatSub?.cancel();
    setOnline(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
