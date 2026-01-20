import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/global.dart';
import '../common/chat_screen.dart';
import 'helper_detail_screen.dart';

class ElderRequestHistoryScreen extends StatelessWidget {
  const ElderRequestHistoryScreen({super.key});

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
        title: const Text("Request History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('elderId', isEqualTo: Global.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];
          // Sort locally to avoid Firestore index requirement
          final docs = List<QueryDocumentSnapshot>.from(allDocs);
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>?;
            final dataB = b.data() as Map<String, dynamic>?;
            final tA = dataA?['timestamp'] as Timestamp?;
            final tB = dataB?['timestamp'] as Timestamp?;
            return (tB?.millisecondsSinceEpoch ?? 0).compareTo(tA?.millisecondsSinceEpoch ?? 0);
          });

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No request history yet",
                style: TextStyle(fontSize: 22, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildHistoryCard(context, data, docs[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> data, String requestId) {
    const tealGreen = Color(0xFF00897B);
    final status = (data['status'] ?? 'PENDING').toString().toUpperCase();
    final statusColor = _getStatusColor(status);
    final helperName = data['helperName'] ?? data['volunteerName'] ?? "Helper";
    final serviceType = data['serviceType'] ?? "General Help";
    final location = data['location'] ?? "Not specified";
    final isRated = data['isRated'] ?? false;
    final rating = data['rating'];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Request", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tealGreen)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _infoRow("Helper:", helperName),
                      _infoRow("Service:", serviceType),
                      _infoRow("Location:", location),
                      
                      if (status == 'ACCEPTED') ...[
                        const SizedBox(height: 15),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [tealGreen, Color(0xFF004D40)]),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: tealGreen.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                                requestId: requestId,
                                otherUserName: helperName,
                                isElder: true,
                              )));
                            },
                            icon: const Icon(Icons.chat, color: Colors.white, size: 20),
                            label: const Text("Chat with Helper", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],

                      if (status == 'COMPLETED' && !isRated) ...[
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to helper detail to rate
                              // We construct a minimal map since we might not have full details here
                              Navigator.push(context, MaterialPageRoute(builder: (context) => HelperDetailScreen(
                                helperId: data['helperId'] ?? data['volunteerId'],
                                helperData: {
                                  'name': helperName,
                                  'profession': serviceType,
                                  'area': location,
                                  'phoneNumber': data['helperPhone'] ?? data['volunteerPhone'] // Best effort if available
                                }, 
                              )));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Rate Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],

                      if (isRated && rating != null) ...[
                        const SizedBox(height: 12),
                        const Divider(thickness: 1.5),
                        const SizedBox(height: 12),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text("Your Rating: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ...List.generate(5, (i) => Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 26,
                            )),
                            const SizedBox(width: 10),
                            Text("($rating/5)", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          ],
                        ),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 18, color: Colors.black87), // Increased from 16
          children: [
            TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold)), // Bolder label
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)), // Bolder value
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
}
