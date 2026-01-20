import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/global.dart';
import '../elder/helper_detail_screen.dart';
import 'chat_screen.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  @override
  Widget build(BuildContext context) {
    const tealGreen = Color(0xFF00897B);
    const lightTeal = Color(0xFFE0F2F1);

    return Scaffold(
      backgroundColor: lightTeal,
      appBar: AppBar(
        title: const Text("Request Status", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: tealGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('elderId', isEqualTo: Global.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text("No requests found."));

          final sortedDocs = List.from(docs);
          sortedDocs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>?;
            final dataB = b.data() as Map<String, dynamic>?;
            final tA = dataA?['timestamp'] as Timestamp?;
            final tB = dataB?['timestamp'] as Timestamp?;
            return (tB?.millisecondsSinceEpoch ?? 0).compareTo(tA?.millisecondsSinceEpoch ?? 0);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final data = sortedDocs[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'PENDING';
              
              return InkWell(
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => HelperDetailScreen(
                     helperId: data['helperId'] ?? data['volunteerId'],
                     helperData: {'name': data['helperName'] ?? data['volunteerName'] ?? 'Helper'},
                   )));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 5))],
                    border: Border(left: BorderSide(color: _getStatusColor(status), width: 6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['serviceType'] ?? "General Help", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: tealGreen)),
                          _getStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _infoRow("Helper:", data['helperName'] ?? data['volunteerName'] ?? 'Searching...'),
                      _infoRow("Location:", data['location'] ?? 'Jayanagar'),
                      
                      if (status == 'ACCEPTED') ...[
                        const SizedBox(height: 15),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [tealGreen, Color(0xFF00695C)]),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: tealGreen.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3))],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                                requestId: docs[index].id,
                                otherUserName: data['helperName'] ?? data['volunteerName'] ?? "Helper",
                                isElder: true,
                              )));
                            },
                            icon: const Icon(Icons.chat, color: Colors.white),
                            label: const Text("Chat with Helper", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                      
                      if (status == 'COMPLETED' && !(data['isRated'] ?? false)) ...[
                        const SizedBox(height: 15),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => HelperDetailScreen(
                                  helperId: data['helperId'] ?? data['volunteerId'],
                                  helperData: {'name': data['helperName'] ?? data['volunteerName'] ?? 'Helper'},
                                )));
                            },
                            icon: const Icon(Icons.star, size: 20, color: Colors.white),
                            label: const Text("Rate Now", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                      
                      if ((data['isRated'] ?? false) && data['rating'] != null) ...[
                        const SizedBox(height: 10),
                        const Divider(thickness: 1.2),
                        const SizedBox(height: 10),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text("Your Rating: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ...List.generate(5, (i) => Icon(
                              i < (data['rating'] ?? 0) ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 22,
                            )),
                            const SizedBox(width: 8),
                            Text("(${data['rating']}/5)", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ] else if (status == 'COMPLETED') ...[
                        const SizedBox(height: 12),
                        const Text("Tap to rate this helper", style: TextStyle(color: tealGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          children: [
            TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w500)),
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

  Widget _getStatusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
