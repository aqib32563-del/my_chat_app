import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  String timeText(Timestamp? t) {
    if (t == null) return '';
    final d = t.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) {
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final m = d.minute.toString().padLeft(2, '0');
      return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
    }
    if (diff == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }

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
            final time = timeText(c['lastTime'] as Timestamp?);
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: d.reference
                  .collection('messages')
                  .where('senderId', isEqualTo: other)
                  .where('read', isEqualTo: false)
                  .snapshots(),
              builder: (context, us) {
                final unread = other == me ? 0 : (us.data?.docs.length ?? 0);
                return ListTile(
                  leading: CircleAvatar(
                      child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?')),
                  title: Text(other == me ? '$name (You)' : name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${c['lastMessage'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight:
                              unread > 0 ? FontWeight.bold : FontWeight.normal)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(time,
                          style: TextStyle(
                              fontSize: 12,
                              color: unread > 0
                                  ? const Color(0xFF1B8A3A)
                                  : Colors.grey)),
                      if (unread > 0) ...[
                        const SizedBox(height: 4),
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: const Color(0xFF1B8A3A),
                          child: Text('$unread',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                          otherUid: other,
                          otherName: name,
                          otherUsername: uname),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
