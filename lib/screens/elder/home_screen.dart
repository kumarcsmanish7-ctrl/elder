import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/status_screen.dart';
import 'find_helpers_screen.dart';

import 'helper_detail_screen.dart';
import 'elder_profile_screen.dart';
import '../common/chat_screen.dart';
import '../../services/session_service.dart';
import '../../services/global.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    const tealGreen = Color(0xFF00897B);
    const lightTeal = Color(0xFFE0F2F1);
    final uid = Global.uid ?? '';

    return Scaffold(
      backgroundColor: lightTeal,
      appBar: AppBar(
        title: const Text("Elderly Ease", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: tealGreen,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                SessionService().logout();
                FirebaseAuth.instance.signOut();
              } else if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ElderProfileScreen()));
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 15),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                child: Text(
                  uid.isNotEmpty ? uid[0].toUpperCase() : 'E',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: tealGreen),
                    SizedBox(width: 8),
                    Text("My Profile", style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Active Request Banner
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('elderId', isEqualTo: Global.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

                final allDocs = snapshot.data!.docs;
                final docs = allDocs.where((doc) {
                  final status = (doc.data() as Map<String, dynamic>)['status'] ?? 'PENDING';
                  return status == 'PENDING' || status == 'ACCEPTED' || status == 'COMPLETED';
                }).toList();

                if (docs.isEmpty) return const SizedBox.shrink();
                
                final sortedDocs = List.from(docs);
                sortedDocs.sort((a, b) {
                  final tA = (a.data() as Map)['timestamp'] as Timestamp?;
                  final tB = (b.data() as Map)['timestamp'] as Timestamp?;
                  return (tB?.millisecondsSinceEpoch ?? 0).compareTo(tA?.millisecondsSinceEpoch ?? 0);
                });

                final latestReq = sortedDocs.first;
                final data = latestReq.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'PENDING';
                final helperName = data['helperName'] ?? data['volunteerName'] ?? "Helper";

                if (status == 'COMPLETED' && (data['isRated'] ?? false)) return const SizedBox.shrink();

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: status == 'ACCEPTED' ? Colors.green : tealGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(status == 'ACCEPTED' ? Icons.check_circle : Icons.hourglass_empty, color: status == 'ACCEPTED' ? Colors.green : tealGreen),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusTitle(status, helperName),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: tealGreen),
                              ),
                              const SizedBox(height: 6),
                              Text("Status: $status", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _getStatusColor(status))),
                            ],
                          ),
                      ),
                      const SizedBox(width: 8),
                      if (status == 'ACCEPTED') 
                        IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                              requestId: latestReq.id,
                              otherUserName: helperName,
                              isElder: true,
                            )));
                          },
                          icon: const Icon(Icons.chat, color: Color(0xFF00897B)),
                          tooltip: "Chat with Helper",
                        ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => HelperDetailScreen(
                            helperId: data['helperId'] ?? data['volunteerId'],
                            helperData: {'name': helperName},
                          )));
                        },
                        child: const Text("VIEW", style: TextStyle(fontWeight: FontWeight.bold, color: tealGreen)),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            _buildFeaturesGrid(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    const tealGreen = Color(0xFF00897B);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        children: [
          _buildFeatureCard(
            context,
            "Connect Circle",
            Icons.people,
            const Color(0xFFF1F8F7),
            tealGreen,
            "Find qualified helpers near you",
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FindHelpersScreen())),
          ),
          _buildFeatureCard(
            context,
            "History",
            Icons.history,
            const Color(0xFFE8F5E9),
            Colors.green[700]!,
            "Track your active requests",
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StatusScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon, Color bgColor, Color iconColor, String desc, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 25, backgroundColor: bgColor, child: Icon(icon, color: iconColor, size: 30)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'ACCEPTED': return Colors.blue;
      case 'COMPLETED': return Colors.green;
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusTitle(String status, String helperName) {
    switch (status.toUpperCase()) {
      case 'PENDING': return "Finding you a helper...";
      case 'ACCEPTED': return "Matched with $helperName!";
      case 'COMPLETED': return "Help completed by $helperName";
      case 'REJECTED': return "Request rejected. Trying again?";
      default: return "Finding help...";
    }
  }
}
