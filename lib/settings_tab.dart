import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme_manager.dart';

class SettingsTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onLogout;
  const SettingsTab({super.key, required this.data, required this.onLogout});

  DocumentReference<Map<String, dynamic>> get ref => FirebaseFirestore.instance
      .collection('users_public')
      .doc(FirebaseAuth.instance.currentUser!.uid);

  Future<void> update(Map<String, dynamic> v) async {
    try {
      await ref.set(v, SetOptions(merge: true));
    } catch (_) {}
  }

  Widget header(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(t,
            style: const TextStyle(
                color: Color(0xFF1B8A3A),
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      );

  Widget themeTile(BuildContext context, String id, String title, String sub,
      int need, String plan, String current) {
    final allowed = planRank(plan) >= need;
    return ListTile(
      leading: Icon(id == 'golden'
          ? Icons.workspace_premium
          : (id == 'black' ? Icons.dark_mode : Icons.light_mode)),
      title: Text(title),
      subtitle: Text(sub),
      trailing: allowed
          ? (current == id
              ? const Icon(Icons.check_circle, color: Color(0xFF1B8A3A))
              : null)
          : const Icon(Icons.lock_outline),
      onTap: () {
        if (!allowed) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '$title ke liye ${need == 2 ? 'VIP Pro' : 'Pro'} plan chahiye')));
          return;
        }
        themeNotifier.value = id;
        update({'theme': id});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        final d = snap.data?.data() ?? data;
        final plan = '${d['plan'] ?? 'local'}';
        final theme = '${d['theme'] ?? 'light'}';
        final name = '${d['name'] ?? ''}';
        final planLabel =
            plan == 'vip' ? 'VIP PRO' : (plan == 'pro' ? 'PRO' : 'LOCAL');
        return ListView(
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF1B8A3A),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 22)),
              ),
              title: Text(name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text('@${d['username'] ?? ''}'),
              trailing: Chip(label: Text(planLabel)),
            ),
            const Divider(),
            header('Themes'),
            themeTile(context, 'light', 'Simple (Light)', 'Free', 0, plan, theme),
            themeTile(context, 'black', 'Black Theme', 'Pro', 1, plan, theme),
            themeTile(context, 'golden', 'Golden Theme', 'VIP Pro', 2, plan, theme),
            header('Privacy'),
            SwitchListTile(
              title: const Text('Online status chhupayen'),
              subtitle: const Text('Doosre aap ko "online" nahi dekhenge'),
              value: d['hideOnline'] == true,
              onChanged: (v) => update({'hideOnline': v}),
            ),
            SwitchListTile(
              title: const Text('Last seen chhupayen'),
              subtitle: const Text('Doosre aap ka last seen nahi dekhenge'),
              value: d['hideLastSeen'] == true,
              onChanged: (v) => update({'hideLastSeen': v}),
            ),
            header('Plan (sirf testing ke liye)'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'local', label: Text('Local')),
                  ButtonSegment(value: 'pro', label: Text('Pro')),
                  ButtonSegment(value: 'vip', label: Text('VIP')),
                ],
                selected: {plan},
                onSelectionChanged: (s) {
                  final p = s.first;
                  final upd = <String, dynamic>{'plan': p};
                  if (themeRank(theme) > planRank(p)) {
                    upd['theme'] = 'light';
                    themeNotifier.value = 'light';
                  }
                  update(upd);
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                  'Abhi payment nahi judi, isliye yahan se plan badal sakte hain. Release se pehle ye hataya jayega.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: onLogout,
            ),
          ],
        );
      },
    );
  }
}
