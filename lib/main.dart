import 'dart:async';
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
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B8A3A),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B8A3A),
          foregroundColor: Colors.white,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final user = snap.data;
          if (user == null) return const LoginScreen();
          final isPassword =
              user.providerData.any((p) => p.providerId == 'password');
          if (isPassword && !user.emailVerified) {
            return VerifyEmailScreen(user: user);
          }
          return ProfileGate(uid: user.uid);
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
      stream: FirebaseFirestore.instance
          .collection('users_public')
          .doc(uid)
          .snapshots(),
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
        return PresenceWrapper(
            child: HomeShell(data: snap.data!.data()!));
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
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  bool hidePass = true;
  String error = '';
  String info = '';

  String friendly(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Email sahi nahi likhi';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email ya password galat hai';
        case 'email-already-in-use':
          return 'Ye email pehle se register hai, Login karein';
        case 'weak-password':
          return 'Password kam az kam 6 harf ka rakhein';
        case 'network-request-failed':
          return 'Internet check karein';
        case 'too-many-requests':
          return 'Bohat koshishein ho gayin, thori der baad try karein';
      }
      return e.message ?? e.code;
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  Future<void> run(Future<void> Function() job) async {
    setState(() {
      loading = true;
      error = '';
      info = '';
    });
    try {
      await job();
    } catch (e) {
      if (mounted) setState(() => error = friendly(e));
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> emailLogin() => run(() async {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: emailCtrl.text.trim(), password: passCtrl.text);
      });

  Future<void> emailRegister() => run(() async {
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: emailCtrl.text.trim(), password: passCtrl.text);
        await cred.user?.sendEmailVerification();
      });

  Future<void> resetPassword() => run(() async {
        final e = emailCtrl.text.trim();
        if (e.isEmpty) throw FirebaseAuthException(code: 'invalid-email');
        await FirebaseAuth.instance.sendPasswordResetEmail(email: e);
        if (mounted) {
          setState(() =>
              info = 'Password reset ka link email par bhej diya gaya hai');
        }
      });

  Future<void> googleLogin() => run(() async {
        final gUser = await GoogleSignIn().signIn();
        if (gUser == null) throw Exception('Login cancel ho gaya');
        final gAuth = await gUser.authentication;
        final cred = GoogleAuthProvider.credential(
            accessToken: gAuth.accessToken, idToken: gAuth.idToken);
        await FirebaseAuth.instance.signInWithCredential(cred);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.chat_bubble, size: 80, color: Color(0xFF1B8A3A)),
              const SizedBox(height: 8),
              const Text('OurChat',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
              const Text('Connect • Chat • Call • Share'),
              const SizedBox(height: 28),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: hidePass,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        hidePass ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => hidePass = !hidePass),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (loading) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: loading ? null : emailLogin,
                      child: const Text('Login'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading ? null : emailRegister,
                      child: const Text('Naya account'),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: loading ? null : resetPassword,
                child: const Text('Password bhool gaye?'),
              ),
              if (info.isNotEmpty)
                Text(info,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF1B8A3A))),
              if (error.isNotEmpty)
                Text(error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('ya'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : googleLogin,
                  icon: const Icon(Icons.g_mobiledata, size: 32),
                  label: const Text('Google se login karein'),
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.phone_android),
                  label: Text('Phone number se login (jald aa raha hai)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerifyEmailScreen extends StatefulWidget {
  final User user;
  const VerifyEmailScreen({super.key, required this.user});
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? timer;
  String msg = '';

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) => check());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> check({bool manual = false}) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    try {
      await u.reload();
      final fresh = FirebaseAuth.instance.currentUser;
      if (fresh != null && fresh.emailVerified) {
        await fresh.getIdToken(true);
      } else if (manual && mounted) {
        setState(() => msg = 'Abhi verify nahi hua. Email ka link dabayen.');
      }
    } catch (_) {}
  }

  Future<void> resend() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        setState(() =>
            msg = 'Link dobara bhej diya gaya. Spam folder bhi dekh lein.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => msg = 'Thori der baad dobara koshish karein');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_unread,
                  size: 80, color: Color(0xFF1B8A3A)),
              const SizedBox(height: 16),
              const Text('Email verify karein',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                  'Hum ne ${widget.user.email} par ek link bheja hai.\nUs link ko dabayen, phir wapas yahan aayen.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => check(manual: true),
                child: const Text('Maine verify kar liya'),
              ),
              TextButton(
                  onPressed: resend, child: const Text('Link dobara bhejein')),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Logout / doosri email'),
              ),
              const SizedBox(height: 8),
              Text(msg, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
