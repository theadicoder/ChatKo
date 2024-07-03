import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

const Color darkBlue = Color.fromARGB(255, 18, 32, 47);
const Color primaryColor = Color(0xFF6C63FF);
const int messageLimit = 30;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.signInAnonymously();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: darkBlue,
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.white24,
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white,
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DateFormat formatter = DateFormat('MM/dd HH:mm:ss');
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Enter a new message',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'You can type a message into this field and hit the enter key '
              'to add it to the stream. The security rules for the '
              'Firestore database only allow certain words, though! Check '
              'the comments in the code to the left for details.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FractionallySizedBox(
              widthFactor: 0.75,
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Enter your message and hit Enter',
                ),
                onSubmitted: (String value) {
                  _sendMessage(value);
                  _messageController.clear();
                },
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'The latest messages',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chat')
                    .orderBy('timestamp', descending: true)
                    .limit(messageLimit)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return const Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      return Card(
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: DefaultTextStyle.merge(
                            style: const TextStyle(color: Colors.white),
                            child: Text(formatter.format(
                                DateTime.fromMillisecondsSinceEpoch(
                                    docs[i]['timestamp'] as int))),
                          ),
                          title: Text('${docs[i]['message']}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String message) async {
    await FirebaseFirestore.instance.collection('chat').add(
      {
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
