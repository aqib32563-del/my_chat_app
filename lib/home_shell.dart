import 'package:flutter/material.dart';
import 'new_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeShell extends StatefulWidget {
  final Map<String, dynamic> data;
  const HomeShell({super.key, required this.data});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final titles = ['OurChat', 'Groups', 'Calls', 'Status', 'Settings'];

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  Widget empty(IconData icon, String text) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget body() {
    switch (index) {
      case 0:
        return empty(Icons.chat_bubble_outline, 'Abhi koi chat nahi');
      case 1:
        return empty(Icons.groups_outlined, 'Abhi koi group nahi');
      case 2:
        return empty(Icons.call_outlined, 'Abhi koi call nahi');
      case 3:
        return empty(Icons.donut_large, 'Abhi koi status nahi');
      default:
        return ListView(
          children: [
            ListTile(
              leading: const CircleAvatar(
                  radius: 26, child: Icon(Icons.person, size: 30)),
              title: Text('${widget.data['name']}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text('@${widget.data['username']}'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: logout,
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: body(),
      floatingActionButton: index == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen())), child: const Icon(Icons.chat))
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Groups'),
          NavigationDestination(icon: Icon(Icons.call_outlined), label: 'Calls'),
          NavigationDestination(icon: Icon(Icons.donut_large), label: 'Status'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
