import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OurChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF075E54),
        scaffoldBackgroundColor: const Color(0xFF0B141A),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1F2C34), iconTheme: IconThemeData(color: Colors.white)),
      ),
      home: const AuthScreen(),
    );
  }
}

// ================= 1. LOGIN SCREEN =================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainChatsScreen()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Login Failed'), backgroundColor: Colors.red));
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat, size: 80, color: Color(0xFF00A884)),
              const SizedBox(height: 30),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: (val) => !val!.contains('@') ? 'Sahi Email likhein' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A884)),
                  onPressed: _loading ? null : _login,
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                child: const Text('Naya account banayein? Sign Up', style: TextStyle(color: Color(0xFF00A884))),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ================= 2. SIGN UP SCREEN =================
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; });
    try {
      UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await userCred.user!.sendEmailVerification();
      Navigator.push(context, MaterialPageRoute(builder: (context) => EmailVerifyScreen(
        username: _usernameController.text.trim().toLowerCase(),
        email: _emailController.text.trim(),
      )));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error'), backgroundColor: Colors.red));
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Unique Username (e.g. javeed7710)', prefixText: '@', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Username likhein' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: (val) => !val!.contains('@') ? 'Sahi Email likhein' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password (min 6 chars)', border: OutlineInputBorder()),
                validator: (val) => val!.length < 6 ? 'Password chhota hai' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A884)),
                  onPressed: _loading ? null : _createAccount,
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign Up & Send Verification', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= 3. EMAIL VERIFY SCREEN =================
class EmailVerifyScreen extends StatefulWidget {
  final String username;
  final String email;
  const EmailVerifyScreen({super.key, required this.username, required this.email});
  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  bool _loading = false;

  void _checkVerification() async {
    setState(() { _loading = true; });
    await FirebaseAuth.instance.currentUser!.reload();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PhoneNumberScreen(
        username: widget.username,
        email: widget.email,
      )));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email abhi verify nahi hui. Link par click karein.')));
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text('Humne aapke email (${widget.email}) par ek verification link bheji hai. Pehle apna email check karein aur link par click karein.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A884)),
                onPressed: _loading ? null : _checkVerification,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Maine Link Par Click Kar Diya', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= 4. PHONE NUMBER SCREEN =================
class PhoneNumberScreen extends StatefulWidget {
  final String username;
  final String email;
  const PhoneNumberScreen({super.key, required this.username, required this.email});
  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final _phoneController = TextEditingController();
  bool _loading = false;

  Future<void> _savePhone() async {
    if (_phoneController.text.trim().isEmpty) return;
    setState(() { _loading = true; });

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': '@${widget.username}',
        'email': widget.email,
        'phone': _phoneController.text.trim(),
        'uid': uid,
      });

      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainChatsScreen()), (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Phone Number')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Email successfully verified!', style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Yeh number aapki privacy ke liye kisi ko nahi dikhega.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 30),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number (e.g. 03001234567)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A884)),
                onPressed: _loading ? null : _savePhone,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Register', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= 5. MAIN CHATS SCREEN =================
class MainChatsScreen extends StatelessWidget {
  const MainChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OurChat', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () {
             FirebaseAuth.instance.signOut();
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
          }),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).collection('my_contacts').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final contacts = snapshot.data!.docs;
          if (contacts.isEmpty) {
            return const Center(
              child: Text('Aapne abhi koi contact save nahi kiya.\nNeeche + button dabakar @username search karein.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final userData = contacts[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFF00A884), child: Text(userData['username'][1].toUpperCase(), style: const TextStyle(color: Colors.white))),
                title: Text(userData['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                    receiverUsername: userData['username'],
                    receiverId: userData['uid'],
                  )));
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A884),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectContactScreen()));
        },
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}

// ================= 6. SELECT CONTACT SCREEN (Search & Save) =================
class SelectContactScreen extends StatefulWidget {
  const SelectContactScreen({super.key});
  @override
  State<SelectContactScreen> createState() => _SelectContactScreenState();
}

class _SelectContactScreenState extends State<SelectContactScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _searchedUser;

  void _searchUser() async {
    String queryText = _searchController.text.trim().toLowerCase();
    if (queryText.isEmpty) return;
    if (!queryText.startsWith('@')) queryText = '@$queryText'; // Auto add @

    setState(() { _isSearching = true; _searchedUser = null; });

    try {
      // Exact Match Search by Unique Username
      final query = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: queryText).get();
      if (query.docs.isNotEmpty) {
        final userData = query.docs.first.data();
        if (userData['uid'] == FirebaseAuth.instance.currentUser!.uid) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeh aapka khud ka username hai.')));
        } else {
          setState(() { _searchedUser = userData; });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeh username nahi mila.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _isSearching = false; });
    }
  }

  void _saveContactAndChat() async {
    String myUid = FirebaseAuth.instance.currentUser!.uid;
    try {
      // Save to my_contacts
      await FirebaseFirestore.instance.collection('users').doc(myUid).collection('my_contacts').doc(_searchedUser!['uid']).set({
        'uid': _searchedUser!['uid'],
        'username': _searchedUser!['username'],
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact Saved! Chat start karein.')));
      
      // Navigate to Chat
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatScreen(
        receiverUsername: _searchedUser!['username'],
        receiverId: _searchedUser!['uid'],
      )));
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Chat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exact @username',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward, color: Color(0xFF00A884)), onPressed: _searchUser),
              ),
              onSubmitted: (_) => _searchUser(),
            ),
          ),
          if (_isSearching) const CircularProgressIndicator(),
          
          if (_searchedUser != null)
            ListTile(
              leading: CircleAvatar(backgroundColor: const Color(0xFF00A884), child: Text(_searchedUser!['username'][1].toUpperCase(), style: const TextStyle(color: Colors.white))),
              title: Text(_searchedUser!['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Save karke chat karein'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A884)),
                onPressed: _saveContactAndChat,
                child: const Text('Save & Chat', style: TextStyle(color: Colors.white)),
              ),
            ),

          if (_searchedUser == null && !_isSearching)
            const Expanded(
              child: Center(
                child: Text('Kisi se chat shuru karne ke liye\nuska exact @username search karein.\n\nMisaal: @saad7710', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            )
        ],
      ),
    );
  }
}

// ================= 7. CHAT SCREEN =================
class ChatScreen extends StatefulWidget {
  final String receiverUsername;
  final String receiverId;
  const ChatScreen({super.key, required this.receiverUsername, required this.receiverId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  String get chatRoomId {
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort();
    return "${ids[0]}_${ids[1]}";
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId).collection('messages').add({
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'text': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverUsername)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    bool isMe = msg['senderId'] == currentUserId;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF005C4B) : const Color(0xFF1F2C34),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(msg['text'], style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Message', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30)))),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF00A884),
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
