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

// ================= AUTH SCREEN =================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _loading = false;
  String _errorMessage = '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMessage = ''; });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'email': _emailController.text.trim(),
          'username': '@${_usernameController.text.trim().toLowerCase()}',
          'phone': _phoneController.text.trim(),
          'uid': userCred.user!.uid,
        });
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainChatsScreen()));
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'Yeh email registered nahi hai. Pehle Naya Account banayein.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Password galat hai.';
        } else {
          _errorMessage = e.message ?? 'Koi masla hua hai.';
        }
      });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_isLogin) ...[
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username (e.g. javeed7710)', border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Username likhein' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number (e.g. 03001234567)', border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Phone Number likhein' : null,
                ),
                const SizedBox(height: 15),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: (val) => !val!.contains('@') ? 'Sahi Email likhein' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password (min 6 chars)', border: OutlineInputBorder()),
                validator: (val) => val!.length < 6 ? 'Password 6 characters ka hona chahiye' : null,
              ),
              const SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator() : Text(_isLogin ? 'Login' : 'Sign Up'),
              ),
              TextButton(
                onPressed: () => setState(() { _isLogin = !_isLogin; _errorMessage = ''; }),
                child: Text(_isLogin ? 'Naya account banayein?' : 'Pehle se account hai? Login karein'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ================= MAIN CHATS SCREEN =================
class MainChatsScreen extends StatelessWidget {
  const MainChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {
             FirebaseAuth.instance.signOut();
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
          }),
        ],
      ),
      body: const Center(child: Text('Abhi koi chat nahi hai.', style: TextStyle(color: Colors.grey))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A884),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectContactScreen()));
        },
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1F2C34),
        selectedItemColor: const Color(0xFF00A884),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),
          BottomNavigationBarItem(icon: Icon(Icons.update), label: 'Updates'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// ================= SELECT CONTACT SCREEN =================
class SelectContactScreen extends StatelessWidget {
  const SelectContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Select contact')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF00A884), child: Icon(Icons.group_add, color: Colors.white)),
            title: const Text('New group', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {},
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF00A884), child: Icon(Icons.person_add, color: Colors.white)),
            title: const Text('New contact', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.qr_code_scanner),
            onTap: () {
              // Open the New Contact Form Screen
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddContactScreen()));
            },
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF00A884), child: Icon(Icons.calendar_today, color: Colors.white)),
            title: const Text('New event', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {},
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Contacts on OurChat', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          
          // ONLY SHOW SAVED CONTACTS HERE
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).collection('my_contacts').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              
              final contacts = snapshot.data?.docs ?? [];
              if (contacts.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Aapne abhi koi contact save nahi kiya.', style: TextStyle(color: Colors.grey))));

              return Column(
                children: contacts.map((doc) {
                  final userData = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.grey[700], child: const Icon(Icons.person, color: Colors.white)),
                    title: Text(userData['savedName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(userData['phone'] ?? ''),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                        receiverUsername: userData['savedName'] ?? 'Unknown',
                        receiverId: userData['uid'],
                      )));
                    },
                  );
                }).toList(),
              );
            },
          )
        ],
      ),
    );
  }
}

// ================= NEW CONTACT SCREEN (Exact UI from your screenshot) =================
class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});
  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;

  void _saveContact() async {
    String firstName = _firstNameController.text.trim();
    String phone = _phoneController.text.trim();

    if (firstName.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('First name aur Phone zaroori hai.')));
      return;
    }

    setState(() { _isSaving = true; });

    try {
      // 1. Search if this phone exists on OurChat globally
      final query = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: phone).get();
      
      if (query.docs.isNotEmpty) {
        final targetUser = query.docs.first.data();
        if (targetUser['uid'] == FirebaseAuth.instance.currentUser!.uid) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeh aapka khud ka number hai.')));
          return;
        }

        // 2. Save to MY private contact list
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('my_contacts')
            .doc(targetUser['uid'])
            .set({
          'uid': targetUser['uid'],
          'phone': targetUser['phone'],
          'savedName': '$firstName ${_lastNameController.text.trim()}'.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact Saved!')));
        Navigator.pop(context); // Go back to Contact List
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Is number par koi user nahi hai.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New contact'),
        actions: const [Padding(padding: EdgeInsets.all(16.0), child: Icon(Icons.qr_code_scanner))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person),
                labelText: 'First name',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last name',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone),
                labelText: 'Phone (e.g. 03001234567)',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A884),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= CHAT SCREEN =================
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
