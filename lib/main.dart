import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'username_screen.dart';
import 'home_shell.dart';
import 'presence_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const OurChat());
}

class OurChat extends StatelessWidget {
  const OurChat({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OurChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1B8A3A), useMaterial3: true, appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1B8A3A), foregroundColor: Colors.white)),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snap.hasData) return ProfileGate(uid: snap.data!.uid);
          return const LoginScreen();
        },
      ),
    );
  }
}

class ProfileGate extends StatelessWidget {
  final String uid;
  const ProfileGate({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users_public').doc(uid).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
              body: Center(
                  child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: ${snap.error}',
                style: const TextStyle(color: Colors.red)),
          )));
        }
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.data!.exists) return const UsernameScreen();
        return PresenceWrapper(child: HomeShell(data: snap.data!.data()!));
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String error = '';
  bool loading = false;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final gUser = await GoogleSignIn().signIn();
      if (gUser == null) throw Exception('Login cancel ho gaya');
      final gAuth = await gUser.authentication;
      final cred = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken, idToken: gAuth.idToken);
      await FirebaseAuth.instance.signInWithCredential(cred);
    } catch (e) {
      setState(() => error = e.toString());
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
            const Icon(Icons.chat_bubble, size: 90, color: Colors.green),
            const SizedBox(height: 12),
            const Text('OurChat',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            const Text('Connect • Chat • Call • Share'),
            const SizedBox(height: 40),
            loading
                ? const CircularProgressIndicator()
                : FilledButton.icon(
                    onPressed: login,
                    icon: const Icon(Icons.login),
                    label: const Text('Google se login karein'),
                  ),
            const SizedBox(height: 16),
            Text(error, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const HomeScreen({super.key, required this.data});

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OurChat'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Khush aamdeed, ${data['name']}!',
                style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text('@${data['username']}',
                style: const TextStyle(fontSize: 18, color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
