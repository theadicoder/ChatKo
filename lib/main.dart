import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

const Color darkBlue = Color(0xFF0D253F);
const Color primaryColor = Color(0xFF128C7E);
const Color secondaryColor = Color(0xFF25D366);
const Color accentColor = Color(0xFFDCF8C6);
const Color backgroundColor = Color(0xFFECE5DD);
const messageLimit = 30;

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (e, st) {
    print(e);
    print(st);
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAuth.instance.signInAnonymously();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final DateFormat formatter = DateFormat('MM/dd HH:mm:SS');

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: primaryColor,
        accentColor: secondaryColor,
        scaffoldBackgroundColor: backgroundColor,
        textTheme: TextTheme(
          headlineSmall: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          hintStyle: TextStyle(color: Colors.black38),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();
  final DateFormat formatter = DateFormat('MM/dd HH:mm:SS');

  ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat App'),
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat')
                  .orderBy('timestamp', descending: true)
                  .limit(messageLimit)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('$snapshot.error'));
                } else if (!snapshot.hasData) {
                  return const Center(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                var docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var data = docs[i].data() as Map<String, dynamic>;
                    bool isSentByUser =
                        true; // Adjust this as per the user ID logic

                    return Align(
                      alignment: isSentByUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5.0, horizontal: 10.0),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 15.0),
                        decoration: BoxDecoration(
                          color: isSentByUser ? primaryColor : accentColor,
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Column(
                          crossAxisAlignment: isSentByUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['message']}',
                              style: TextStyle(
                                color: isSentByUser
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              formatter.format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      data['timestamp'])),
                              style: TextStyle(
                                color: isSentByUser
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
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
                    controller: _controller,
                    decoration: const InputDecoration(
                        hintText: 'Enter your message...'),
                    onSubmitted: (String value) {
                      if (value.trim().isEmpty) return;
                      FirebaseFirestore.instance.collection('chat').add(
                        {
                          'message': value,
                          'timestamp': DateTime.now().millisecondsSinceEpoch
                        },
                      );
                      _controller.clear();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: primaryColor),
                  onPressed: () {
                    String value = _controller.text.trim();
                    if (value.isEmpty) return;
                    FirebaseFirestore.instance.collection('chat').add(
                      {
                        'message': value,
                        'timestamp': DateTime.now().millisecondsSinceEpoch
                      },
                    );
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
