import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});
  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final nameCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  String error = '';
  bool loading = false;

  Future<void> save() async {
    final username = userCtrl.text.trim().toLowerCase();
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => error = 'Apna naam likhein');
      return;
    }
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username)) {
      setState(() => error = 'Username 3 se 20 harf, sirf a-z, 0-9 aur _');
      return;
    }
    setState(() {
      loading = true;
      error = '';
    });
    final user = FirebaseAuth.instance.currentUser!;
    final db = FirebaseFirestore.instance;
    try {
      final unameRef = db.collection('usernames').doc(username);
      await db.runTransaction((tx) async {
        final snap = await tx.get(unameRef);
        if (snap.exists) throw Exception('taken');
        tx.set(unameRef, {'uid': user.uid});
        tx.set(db.collection('users_public').doc(user.uid), {
          'uid': user.uid,
          'username': username,
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.set(db.collection('users_private').doc(user.uid), {
          'email': user.email,
          'phone': user.phoneNumber,
        });
      });
    } catch (e) {
      setState(() => error = e.toString().contains('taken')
          ? 'Ye username pehle se liya hua hai'
          : e.toString());
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 80, color: Colors.green),
            const SizedBox(height: 12),
            const Text('Apna profile banayen',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Doosron ko sirf aap ka username nazar aayega.\nEmail aur phone chhupa rahega.',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Aap ka naam', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(
                  labelText: 'Username (jaise aqib_01)',
                  prefixText: '@',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : FilledButton(onPressed: save, child: const Text('Aage barhein')),
            const SizedBox(height: 12),
            Text(error, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
