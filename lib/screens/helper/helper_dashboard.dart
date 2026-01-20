import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'helper_profile_screen.dart';
import '../common/chat_screen.dart';
import '../common/chat_list_screen.dart';
import '../../services/session_service.dart';
import '../../services/global.dart';

class HelperDashboard extends StatefulWidget {
  const HelperDashboard({super.key});

  @override
  State<HelperDashboard> createState() => _HelperDashboardState();
}

class _HelperDashboardState extends State<HelperDashboard> with SingleTickerProviderStateMixin {
  String? get currentUid => Global.uid;
  String _helperName = "Helper";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = currentUid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _helperName = data['name'] ?? 'Helper';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _acceptRequest(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(docId).update({
        'status': 'ACCEPTED',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request accepted!"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _rejectRequest(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(docId).update({
        'status': 'REJECTED',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request rejected"), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _markCompleted(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(docId).update({
        'status': 'COMPLETED',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Marked as completed!"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
        automaticallyImplyLeading: false,
        titleSpacing: 16, // Move title to extreme left
        title: const Text("Elderly Ease", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'logout') {
                SessionService().logout();
                FirebaseAuth.instance.signOut();
              } else if (val == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HelperProfileScreen()));
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 15),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                child: Text(_helperName.isNotEmpty ? _helperName[0].toUpperCase() : 'H', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Row(children: [Icon(Icons.person, color: tealGreen), SizedBox(width: 10), Text("Profile")])),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 10), Text("Logout")])),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Incoming", icon: Icon(Icons.inbox, size: 20)),
            Tab(text: "Attended", icon: Icon(Icons.history, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomingTab(),
          _buildAttendedTab(),
        ],
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('requests').snapshots(),
        builder: (context, snapshot) {
          int totalUnread = 0;
          if (snapshot.hasData) {
            // Filter for this helper's requests
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final helperId = (data['helperId'] ?? data['volunteerId'])?.toString().toLowerCase();
              if (helperId == currentUid?.toLowerCase()) {
                // Check both new and old unread count fields
                totalUnread += ((data['unreadCountHelper'] ?? data['unreadCountVolunteer'] ?? 0) as int);
              }
            }
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              FloatingActionButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListScreen()));
                },
                backgroundColor: tealGreen,
                child: const Icon(Icons.chat, color: Colors.white),
              ),
              if (totalUnread > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      totalUnread > 9 ? "9+" : "$totalUnread",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildIncomingTab() {

    return StreamBuilder<QuerySnapshot>(
      // Fetch all requests and filter locally for backward compatibility
      stream: FirebaseFirestore.instance
          .collection('requests')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final allDocs = snapshot.data?.docs ?? [];
        // Filter for this helper (check both helperId and volunteerId for backward compatibility)
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final helperId = (data['helperId'] ?? data['volunteerId'])?.toString().toLowerCase();
          final status = data['status'] ?? 'PENDING';
          return (helperId == currentUid?.toLowerCase()) && (status == 'PENDING' || status == 'ACCEPTED');
        }).toList();
        
        if (docs.isEmpty) {
          return const Center(child: Text("No incoming requests", style: TextStyle(fontSize: 16, color: Colors.grey)));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return _buildRequestCard(data, docId, false);
          },
        );
      },
    );
  }

  Widget _buildAttendedTab() {
    return StreamBuilder<QuerySnapshot>(
      // Fetch all requests and filter locally for backward compatibility
      stream: FirebaseFirestore.instance
          .collection('requests')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final allDocs = snapshot.data?.docs ?? [];
        // Filter for this helper (check both helperId and volunteerId for backward compatibility)
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final helperId = (data['helperId'] ?? data['volunteerId'])?.toString().toLowerCase();
          final status = data['status'] ?? 'PENDING';
          return (helperId == currentUid?.toLowerCase()) && (status == 'COMPLETED' || status == 'REJECTED');
        }).toList();
        
        if (docs.isEmpty) {
          return const Center(child: Text("No attended requests yet", style: TextStyle(fontSize: 16, color: Colors.grey)));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return _buildRequestCard(data, docId, true);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data, String docId, bool isHistory) {
    const tealGreen = Color(0xFF00897B);
    final status = (data['status'] ?? 'PENDING').toString().toUpperCase();
    final statusColor = _getStatusColor(status);
    final elderRating = data['rating'];
    final isRated = data['isRated'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Help Request", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tealGreen)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoRow("👤 Elder:", data['elderName'] ?? "Elder", bold: true),
                      _infoRow("• Service:", data['serviceType'] ?? "General Help", bold: true),
                      _infoRow("• Location:", data['location'] ?? "Not specified"),
                      
                      if (isHistory) ...[
                        if (isRated && elderRating != null) ...[
                          const SizedBox(height: 12),
                          const Divider(thickness: 1.2),
                          const SizedBox(height: 12),
                          Center(
                            child: Column(
                              children: [
                                const Text("Elder's Rating", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ...List.generate(5, (i) => Icon(
                                      i < elderRating ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 24,
                                    )),
                                    const SizedBox(width: 8),
                                    Text("($elderRating/5)", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else if (status == 'COMPLETED' && !isRated) ...[
                          const SizedBox(height: 12),
                          const Divider(thickness: 1.2),
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.hourglass_empty, size: 16, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text(
                                    "Rating Pending",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                      
                      if (!isHistory) ...[
                        const SizedBox(height: 16),
                        if (status == 'PENDING') ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _acceptRequest(docId),
                                  icon: const Text("✅", style: TextStyle(fontSize: 16)),
                                  label: const Text("Accept"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _rejectRequest(docId),
                                  icon: const Text("❌", style: TextStyle(fontSize: 16)),
                                  label: const Text("Reject"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (status == 'ACCEPTED') ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _markCompleted(docId),
                                  icon: const Text("✔️", style: TextStyle(fontSize: 16)),
                                  label: const Text("Mark as Done"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                                      requestId: docId,
                                      otherUserName: data['elderName'] ?? "Elder",
                                      isElder: false,
                                    )));
                                  },
                                  icon: const Icon(Icons.chat, size: 20),
                                  label: const Text("Chat"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: tealGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 17, color: Colors.black87), // Increased from 14
          children: [
            TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const TextSpan(text: " "),
            TextSpan(
              text: value,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'ACCEPTED': return Colors.blue;
      case 'COMPLETED': return Colors.green;
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
