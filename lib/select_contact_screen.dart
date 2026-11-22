import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

class SelectContactScreen extends StatefulWidget {
  const SelectContactScreen({super.key});
  @override
  State<SelectContactScreen> createState() => _SelectContactScreenState();
}

class _SelectContactScreenState extends State<SelectContactScreen> {
  final me = FirebaseAuth.instance.currentUser!;
  List<Map<String, dynamic>>? contacts;
  Map<String, dynamic>? myData;
  bool searching = false;
  String filter = '';
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    final db = FirebaseFirestore.instance;
    db.collection('users_public').doc(me.uid).get().then((d) {
      if (mounted) setState(() => myData = d.data());
    });
    sub = db.collection('users_private').doc(me.uid).snapshots().listen((s) async {
      final uids = List<String>.from(s.data()?['contacts'] ?? []);
      final docs = await Future.wait(
          uids.map((u) => db.collection('users_public').doc(u).get()));
      final list = docs.where((d) => d.exists).map((d) => d.data()!).toList();
      list.sort((a, b) =>
          '${a['name']}'.toLowerCase().compareTo('${b['name']}'.toLowerCase()));
      if (mounted) setState(() => contacts = list);
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  void openChat(Map<String, dynamic> u) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUid: '${u['uid']}',
          otherName: '${u['name']}',
          otherUsername: '${u['username']}',
        ),
      ),
    );
  }

  Widget action(IconData icon, String title, VoidCallback onTap,
      {Widget? trailing}) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF1B8A3A),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = contacts
        ?.where((c) =>
            filter.isEmpty ||
            '${c['name']}'.toLowerCase().contains(filter) ||
            '${c['username']}'.contains(filter))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: searching
            ? TextField(
                autofocus: true,
                onChanged: (t) => setState(
                    () => filter = t.trim().toLowerCase().replaceAll('@', '')),
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Contact dhoondein...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select contact',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${contacts?.length ?? 0} contacts',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              searching = !searching;
              filter = '';
            }),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (!searching) ...[
            action(Icons.group_add, 'New group', () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Groups agle phase mein aa rahe hain')));
            }),
            action(
              Icons.person_add,
              'New contact',
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NewChatScreen())),
              trailing: const Icon(Icons.qr_code_2),
            ),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Contacts on OurChat',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ),
          if (!searching && myData != null)
            ListTile(
              leading: const CircleAvatar(
                  radius: 24, child: Icon(Icons.person)),
              title: Text('${myData!['name']} (You)',
                  style: const TextStyle(fontSize: 17)),
              subtitle: const Text('Message yourself'),
              onTap: () => openChat(myData!),
            ),
          if (shown == null)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()))
          else if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                  'Abhi koi contact nahi. "New contact" se username dhoondein.',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            ...shown.map((c) {
              final name = '${c['name']}';
              return ListTile(
                leading: CircleAvatar(
                    radius: 24,
                    child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?')),
                title: Text(name, style: const TextStyle(fontSize: 17)),
                subtitle: Text('@${c['username']}'),
                onTap: () => openChat(c),
              );
            }),
        ],
      ),
    );
  }
}
