import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasData) return const HomeScreen();
          return const LoginScreen();
        },
      ),
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
      if (gUser == null) throw Exception("Login cancel ho gaya");
      final gAuth = await gUser.authentication;
      final cred = GoogleAuthProvider.credential(accessToken: gAuth.accessToken, idToken: gAuth.idToken);
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
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('OurChat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Text('Khush aamdeed, ${user?.displayName ?? ''}!',
            style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
