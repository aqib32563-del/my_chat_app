import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});
  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  List<Map<String, dynamic>> results = [];
  bool loading = false;
  String error = '';

  Future<void> search(String text) async {
    final q = text.trim().toLowerCase().replaceAll('@', '');
    if (q.isEmpty) {
      setState(() => results = []);
      return;
    }
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users_public')
          .where('username', isGreaterThanOrEqualTo: q)
          .where('username', isLessThan: '$q\uf8ff')
          .limit(10)
          .get();
      final me = FirebaseAuth.instance.currentUser!.uid;
      results = snap.docs
          .map((d) => d.data())
          .where((u) => u['uid'] != me)
          .toList();
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: search,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Username likhein...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
      ),
      body: Column(
        children: [
          if (loading) const LinearProgressIndicator(),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(error, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Text('Username likh kar dost dhoondein',
                        style: TextStyle(color: Colors.grey)))
                : ListView(
                    children: results
                        .map((u) => ListTile(
                              leading: CircleAvatar(
                                  child: Text(
                                      '${u['name']}'.isNotEmpty ? '${u['name']}'[0].toUpperCase() : '?')),
                              title: Text('${u['name']}'),
                              subtitle: Text('@${u['username']}'),
                              onTap: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text('Chat agle step mein banegi'))),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
