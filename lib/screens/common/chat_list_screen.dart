import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/global.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tealGreen = Color(0xFF00897B);
    const lightTeal = Color(0xFFE0F2F1);
    final rawUid = Global.uid;
    final uid = rawUid?.toLowerCase();

    return Scaffold(
      backgroundColor: lightTeal,
      appBar: AppBar(
        backgroundColor: tealGreen,
        elevation: 0,
        title: const Text("My Chats", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query requests where user is either elder or helper
        stream: FirebaseFirestore.instance.collection('requests').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allRequests = snapshot.data?.docs ?? [];
          
          // Filter locally because Firestore doesn't support OR queries easily across different fields without indices
          final myChats = allRequests.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final elderId = data['elderId']?.toString().toLowerCase();
            // Backward compatibility: check both helperId and volunteerId
            final helperId = (data['helperId'] ?? data['volunteerId'])?.toString().toLowerCase();
            final hasMessage = data['lastMessage'] != null;
            
            // Only show requests where user is a participant AND there is at least one message
            return (elderId == uid || helperId == uid) && hasMessage;
          }).toList();

          // Sort by last message time
          myChats.sort((a, b) {
            final tA = (a.data() as Map)['lastMessageTime'] as Timestamp?;
            final tB = (b.data() as Map)['lastMessageTime'] as Timestamp?;
            return (tB?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch).compareTo(tA?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch);
          });

          if (myChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.message_outlined, size: 80, color: tealGreen.withValues(alpha: 0.3)),
                   const SizedBox(height: 20),
                   const Text("No messages yet", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            itemCount: myChats.length,
            itemBuilder: (context, index) {
              final data = myChats[index].data() as Map<String, dynamic>;
              final requestId = myChats[index].id;
              final isElder = data['elderId'] == uid;
              
              // Backward compatibility: check both new (helperName) and old (volunteerName) fields
              final otherName = isElder 
                  ? (data['helperName'] ?? data['volunteerName'] ?? "Helper") 
                  : (data['elderName'] ?? "Elder");
              final lastMsg = data['lastMessage'] ?? "";
              final lastTime = data['lastMessageTime'] as Timestamp?;
              final unreadCount = (isElder 
                  ? (data['unreadCountElder'] ?? 0) 
                  : (data['unreadCountHelper'] ?? data['unreadCountVolunteer'] ?? 0)) as int;
              
              String timeStr = "";
              if (lastTime != null) {
                final date = lastTime.toDate();
                timeStr = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                      requestId: requestId,
                      otherUserName: otherName,
                      isElder: isElder,
                    )));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Attractive Avatar
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [tealGreen, Color(0xFF4DB6AC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: tealGreen.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Center(
                            child: Text(
                              otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                                  Text(timeStr, style: TextStyle(fontSize: 12, color: unreadCount > 0 ? tealGreen : Colors.grey[400], fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      lastMsg,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: unreadCount > 0 ? Colors.black87 : Colors.grey[600], fontSize: 14, fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal),
                                    ),
                                  ),
                                  if (unreadCount > 0)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: tealGreen, borderRadius: BorderRadius.circular(10)),
                                      child: Text("$unreadCount", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
              );
            },
          );
        },
      ),
    );
  }
}
