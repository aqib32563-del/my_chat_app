import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('members', arrayContains: me)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs.toList();
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Abhi koi chat nahi',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        docs.sort((a, b) {
          final ta = a.data()['lastTime'] as Timestamp?;
          final tb = b.data()['lastTime'] as Timestamp?;
          final va = ta?.millisecondsSinceEpoch ?? (1 << 50);
          final vb = tb?.millisecondsSinceEpoch ?? (1 << 50);
          return vb.compareTo(va);
        });
        return ListView(
          children: docs.map((d) {
            final c = d.data();
            final members = List<String>.from(c['members']);
            final other = members.firstWhere((m) => m != me, orElse: () => me);
            final name = '${(c['names'] as Map)[other] ?? ''}';
            final uname = '${(c['usernames'] as Map)[other] ?? ''}';
            return ListTile(
              leading: CircleAvatar(
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
              title: Text(other == me ? '$name (You)' : name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${c['lastMessage'] ?? ''}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                      otherUid: other, otherName: name, otherUsername: uname),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
