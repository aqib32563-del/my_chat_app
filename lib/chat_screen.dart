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

  @override
  void initState() {
    super.initState();
    final ids = [me.uid, widget.otherUid]..sort();
    chatId = ids.join('_');
    chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
  }

  Future<void> send() async {
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    ctrl.clear();
    myData ??= (await FirebaseFirestore.instance
            .collection('users_public')
            .doc(me.uid)
            .get())
        .data();
    await chatRef.set({
      'members': [me.uid, widget.otherUid],
      'names': {me.uid: myData?['name'], widget.otherUid: widget.otherName},
      'usernames': {
        me.uid: myData?['username'],
        widget.otherUid: widget.otherUsername
      },
      'lastMessage': text,
      'lastTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await chatRef.collection('messages').add({
      'text': text,
      'senderId': me.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
            Text('@${widget.otherUsername}',
                style: const TextStyle(fontSize: 12)),
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
                  .snapshots(),
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
                        child: Text('${m['text']}',
                            style: const TextStyle(fontSize: 16)),
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
