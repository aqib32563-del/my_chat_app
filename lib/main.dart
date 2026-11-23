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
      theme: ThemeData(primaryColor: const Color(0xFF075E54)),
      home: const AuthScreen(),
    );
  }
}

// ================= LOGIN / SIGNUP =================
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
        
        // Save Username and Phone Number
        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'email': _emailController.text.trim(),
          'username': '@${_usernameController.text.trim().toLowerCase()}',
          'phone': _phoneController.text.trim(),
          'uid': userCred.user!.uid,
        });
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UserListScreen()));
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'Yeh email registered nahi hai. Pehle Naya Account banayein.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Password galat hai.';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'Yeh email pehle se registered hai.';
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
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up'), backgroundColor: const Color(0xFF075E54)),
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

// ================= USER LIST (Contacts Only) =================
class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});
  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final String myUid = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isAdding = false;

  void _showAddContactDialog() {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Contact'),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone Number (e.g. 03001234567)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String phone = phoneController.text.trim();
                Navigator.pop(context); // Close dialog
                if (phone.isEmpty) return;
                
                setState(() { _isAdding = true; });
                try {
                  // 1. Search in global users
                  final query = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: phone).get();
                  
                  if (query.docs.isNotEmpty) {
                    final targetData = query.docs.first.data();
                    if (targetData['uid'] == myUid) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeh aapka khud ka number hai!')));
                      return;
                    }
                    // 2. Save to MY contacts
                    await FirebaseFirestore.instance.collection('users').doc(myUid).collection('contacts').doc(targetData['uid']).set(targetData);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact added successfully!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Is number par koi user nahi mila.')));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  setState(() { _isAdding = false; });
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OurChat Contacts', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF075E54),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF25D366),
        onPressed: _showAddContactDialog,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() { _searchQuery = val.toLowerCase(); });
              },
              decoration: const InputDecoration(
                hintText: 'Search in my contacts...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_isAdding) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(myUid).collection('contacts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                
                final contacts = snapshot.data?.docs ?? [];
                if (contacts.isEmpty) {
                  return const Center(child: Text('Aapki list khali hai.\nNeeche + dabakar number add karein.', textAlign: TextAlign.center));
                }

                final filteredContacts = contacts.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  String username = data['username'] ?? '';
                  String phone = data['phone'] ?? '';
                  return username.toLowerCase().contains(_searchQuery) || phone.contains(_searchQuery);
                }).toList();

                if (filteredContacts.isEmpty) {
                  return const Center(child: Text('Koi contact nahi mila.'));
                }

                return ListView.builder(
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final userData = filteredContacts[index].data() as Map<String, dynamic>;
                    String displayUsername = userData['username'] ?? 'Unknown';
                    String displayPhone = userData['phone'] ?? '';
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF25D366),
                        child: Text(displayUsername.isNotEmpty ? displayUsername[1].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(displayUsername, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(displayPhone),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              receiverUsername: displayUsername,
                              receiverId: userData['uid'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
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

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
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
      appBar: AppBar(
        title: Text(widget.receiverUsername, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF075E54),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
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
                          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                        ),
                        child: Text(msg['text']),
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
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF075E54),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
