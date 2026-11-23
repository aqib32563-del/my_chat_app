import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String otherUid;
  final String otherName;
  final String otherUsername;
  const ChatScreen({
    super.key,
    required this.otherUid,
    required this.otherName,
    required this.otherUsername,
  });
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ctrl = TextEditingController();
  final me = FirebaseAuth.instance.currentUser!;
  late final String chatId;
  late final DocumentReference<Map<String, dynamic>> chatRef;
  Map<String, dynamic>? myData;
  bool marking = false;
  Timer? tick;

  @override
  void initState() {
    super.initState();
    final ids = [me.uid, widget.otherUid]..sort();
    chatId = ids.join('_');
    chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    tick?.cancel();
    ctrl.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    ctrl.clear();
    final isSelf = widget.otherUid == me.uid;
    myData ??= (await FirebaseFirestore.instance
            .collection('users_public')
            .doc(me.uid)
            .get())
        .data();
    await chatRef.collection('messages').add({
      'text': text,
      'senderId': me.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'delivered': isSelf,
      'read': isSelf,
    });
    await chatRef.set({
      'members': [me.uid, widget.otherUid],
      'names': {me.uid: myData?['name'], widget.otherUid: widget.otherName},
      'usernames': {
        me.uid: myData?['username'],
        widget.otherUid: widget.otherUsername
      },
      'lastMessage': text,
      'lastSenderId': me.uid,
      'lastTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markRead(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    if (marking) return;
    final unread = docs.where((d) {
      final m = d.data();
      return m['senderId'] != me.uid && m['read'] != true;
    }).toList();
    if (unread.isEmpty) return;
    marking = true;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final d in unread) {
        batch.update(d.reference, {'read': true, 'delivered': true});
      }
      await batch.commit();
    } catch (_) {}
    marking = false;
  }

  String fmtTime(Timestamp? t) {
    if (t == null) return '';
    final d = t.toDate();
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  String lastSeenText(Timestamp t) {
    final d = t.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'last seen today at ${fmtTime(t)}';
    if (diff == 1) return 'last seen yesterday at ${fmtTime(t)}';
    return 'last seen ${d.day}/${d.month}/${d.year}';
  }

  Widget statusLine() {
    if (widget.otherUid == me.uid) {
      return const Text('Message yourself', style: TextStyle(fontSize: 12));
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users_public')
          .doc(widget.otherUid)
          .snapshots(),
      builder: (context, s) {
        final d = s.data?.data();
        final ls = d?['lastSeen'] as Timestamp?;
        final fresh =
            ls != null && DateTime.now().difference(ls.toDate()).inSeconds < 90;
        final online = d?['online'] == true && fresh;
        final text = online
            ? 'online'
            : (ls != null ? lastSeenText(ls) : '@${widget.otherUsername}');
        return Text(text, style: const TextStyle(fontSize: 12));
      },
    );
  }

  Widget tickIcon(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    if (d.metadata.hasPendingWrites) {
      return const Icon(Icons.access_time, size: 14, color: Colors.black45);
    }
    if (m['read'] == true) {
      return const Icon(Icons.done_all, size: 17, color: Colors.blue);
    }
    if (m['delivered'] == true) {
      return const Icon(Icons.done_all, size: 17, color: Colors.black54);
    }
    return const Icon(Icons.done, size: 17, color: Colors.black54);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherName,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            statusLine(),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: chatRef
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(includeMetadataChanges: true),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                      child: Text('Pehla message bhejein 👋',
                          style: TextStyle(color: Colors.grey)));
                }
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => markRead(docs));
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final m = docs[i].data();
                    final mine = m['senderId'] == me.uid;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: mine
                              ? const Color(0xFFCDEFC8)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${m['text']}',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(fmtTime(m['createdAt'] as Timestamp?),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.black54)),
                                if (mine) ...[
                                  const SizedBox(width: 4),
                                  tickIcon(docs[i]),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      onSubmitted: (_) => send(),
                      decoration: InputDecoration(
                        hintText: 'Message likhein...',
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1B8A3A),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
