import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/global.dart';

class ChatScreen extends StatefulWidget {
  final String requestId;
  final String otherUserName;
  final bool isElder;

  const ChatScreen({
    super.key,
    required this.requestId,
    required this.otherUserName,
    required this.isElder,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _senderName = "User";

  @override
  void initState() {
    super.initState();
    _resetUnreadCount();
    _loadSenderName();
  }

  Future<void> _loadSenderName() async {
    final uid = Global.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        if (mounted) {
          setState(() {
            _senderName = doc.data()?['name'] ?? (widget.isElder ? 'Elder' : 'Helper');
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading sender name: $e");
    }
  }

  Future<void> _resetUnreadCount() async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(widget.requestId).update({
        widget.isElder ? 'unreadCountElder' : 'unreadCountHelper': 0,
      });
    } catch (e) {
      debugPrint("Error resetting unread count: $e");
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .collection('messages')
          .add({
        'text': message,
        'senderId': Global.uid?.toLowerCase(),
        'senderName': _senderName,
        'timestamp': FieldValue.serverTimestamp(),
        'isElder': widget.isElder,
      });

      // Update parent document for the chat list preview/sorting and unread count
      await FirebaseFirestore.instance.collection('requests').doc(widget.requestId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        widget.isElder ? 'unreadCountHelper' : 'unreadCountElder': FieldValue.increment(1),
      });

      _messageController.clear();
      
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sending message: $e"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const tealGreen = Color(0xFF00897B);
    const lightTeal = Color(0xFFE0F2F1);

    return Scaffold(
      backgroundColor: lightTeal,
      appBar: AppBar(
        backgroundColor: tealGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .doc(widget.requestId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      "No messages yet. Start the conversation!",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final currentUid = Global.uid?.toLowerCase();
                    final senderId = data['senderId']?.toString().toLowerCase();
                    final isMe = senderId == currentUid;
                    final text = data['text'] ?? '';
                    final senderName = data['senderName'] ?? 'User';

                    return _buildMessageBubble(text, isMe, senderName);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: tealGreen),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: tealGreen, width: 2),
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: tealGreen,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
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

  Widget _buildMessageBubble(String text, bool isMe, String senderName) {
    const tealGreen = Color(0xFF00897B);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? tealGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                senderName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tealGreen),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
