import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// --- 1. THE MAIN LIST SCREEN (Recent Chats) ---
class StudentMessengerScreen extends StatelessWidget {
  const StudentMessengerScreen({super.key});

  final Color _brandBlue = const Color(0xFF2E3192);
  final Color _brandOrange = const Color(0xFFF15A24);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please Login"));

    return Scaffold(
      backgroundColor: Colors.grey[50], // Modern off-white background
      appBar: AppBar(
        title: const Text("Messages", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FIX: Removed .orderBy() to prevent infinite loading due to missing index
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 15),
                  Text("No messages yet", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                ],
              ),
            );
          }

          // FIX: Sort the list here (Client-Side)
          docs.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            Timestamp? t1 = dataA['lastMessageTime'];
            Timestamp? t2 = dataB['lastMessageTime'];
            if (t1 == null) return 1;
            if (t2 == null) return -1;
            return t2.compareTo(t1); // Descending (Newest first)
          });

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String chatId = docs[index].id;

              // 1. Identify the "Other" User
              List participants = data['participants'] ?? [];
              String otherId = participants.firstWhere((id) => id != user.uid, orElse: () => "");

              // 2. Get Name (Safely)
              Map names = data['names'] ?? {};
              String otherName = names[otherId] ?? "User";

              String lastMsg = data['lastMessage'] ?? "";

              // 3. Time Formatting
              Timestamp? time = data['lastMessageTime'];
              String timeStr = time != null
                  ? DateFormat('hh:mm a').format(time.toDate())
                  : "";

              return _ChatListTile(
                chatId: chatId,
                otherId: otherId,
                otherName: otherName,
                lastMessage: lastMsg,
                timeStr: timeStr,
                brandBlue: _brandBlue,
                brandOrange: _brandOrange,
              );
            },
          );
        },
      ),
    );
  }
}

// --- 2. THE LIST CARD WITH UNREAD COUNT ---
class _ChatListTile extends StatelessWidget {
  final String chatId;
  final String otherId;
  final String otherName;
  final String lastMessage;
  final String timeStr;
  final Color brandBlue;
  final Color brandOrange;

  const _ChatListTile({
    required this.chatId,
    required this.otherId,
    required this.otherName,
    required this.lastMessage,
    required this.timeStr,
    required this.brandBlue,
    required this.brandOrange,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Stream specifically to count UNREAD messages
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: otherId) // Messages sent BY them
          .where('isRead', isEqualTo: false)     // That I haven't read
          .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          unreadCount = snapshot.data!.docs.length;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => IndividualChatScreen(otherUserId: otherId, otherUserName: otherName)
                ));
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: brandBlue.withOpacity(0.1),
                      child: Text(
                        otherName.isNotEmpty ? otherName[0] : '?',
                        style: TextStyle(fontWeight: FontWeight.bold, color: brandBlue, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(timeStr, style: TextStyle(fontSize: 12, color: unreadCount > 0 ? brandOrange : Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                                      fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal
                                  ),
                                ),
                              ),
                              if (unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: brandOrange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- 3. THE INDIVIDUAL CHAT SCREEN ---
class IndividualChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const IndividualChatScreen({super.key, required this.otherUserId, required this.otherUserName});

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  late String chatId;

  final Color _brandBlue = const Color(0xFF2E3192);

  @override
  void initState() {
    super.initState();
    _generateChatId();
    _markMessagesAsRead();
  }

  void _generateChatId() {
    List<String> ids = [user!.uid, widget.otherUserId];
    ids.sort();
    chatId = ids.join("_");
  }

  void _markMessagesAsRead() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: widget.otherUserId)
        .where('isRead', isEqualTo: false)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'isRead': true});
      }
    });
  }

  void _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    String msg = _msgController.text.trim();
    _msgController.clear();

    final chatDocRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    await chatDocRef.collection('messages').add({
      'senderId': user!.uid,
      'receiverId': widget.otherUserId,
      'text': msg,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await chatDocRef.set({
      'participants': [user!.uid, widget.otherUserId],
      'names': {
        user!.uid: user!.email!.split('@')[0],
        widget.otherUserId: widget.otherUserName,
      },
      'lastMessage': msg,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean background for chat
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _brandBlue.withOpacity(0.1),
              radius: 18,
              child: Text(widget.otherUserName[0], style: TextStyle(color: _brandBlue, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserName, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat Area
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var msgs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    var data = msgs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == user!.uid;
                    bool isRead = data['isRead'] ?? false;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? _brandBlue : Colors.grey[100],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                data['text'],
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.done_all, size: 14, color: isRead ? Colors.blueAccent.shade100 : Colors.white54)
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    backgroundColor: _brandBlue,
                    radius: 24,
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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