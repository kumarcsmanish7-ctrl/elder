import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/chat_screen.dart';
import '../../services/global.dart';

class HelperDetailScreen extends StatefulWidget {
  final String helperId;
  final Map<String, dynamic>? helperData;
  final String? specificRequestId;

  const HelperDetailScreen({
    super.key,
    required this.helperId,
    this.helperData,
    this.specificRequestId,
  });

  @override
  State<HelperDetailScreen> createState() => _HelperDetailScreenState();
}

class _HelperDetailScreenState extends State<HelperDetailScreen> {
  String _selectedRating = "Select Rating";

  Future<void> _submitRating(String requestId) async {
    if (_selectedRating == "Select Rating") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a rating")));
      return;
    }

    try {
      final ratingValue = int.parse(_selectedRating);
      
      // Update the request with the rating
      await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
        'isRated': true,
        'rating': ratingValue,
      });
      
      final vId = widget.helperId.toLowerCase();
      
      // Fetch ALL requests and filter locally to handle case-insensitive matching
      final allRequests = await FirebaseFirestore.instance
          .collection('requests')
          .get();
      
      // Filter for this helper (case-insensitive) - Backward compatible
    final helperRequests = allRequests.docs.where((doc) {
      final data = doc.data();
      final docHelperId = (data['helperId'] ?? data['volunteerId'])?.toString().toLowerCase();
      return docHelperId == vId;
    }).toList();
      
      double sum = 0;
      int count = 0;
      bool foundCurrent = false;

      for (var doc in helperRequests) {
        final data = doc.data();
        final isDocRated = data['isRated'] ?? false;
        final docRating = data['rating'];
        
        if (doc.id == requestId) {
          sum += ratingValue;
          count++;
          foundCurrent = true;
        } else if (isDocRated && docRating != null) {
          sum += (docRating as num).toDouble();
          count++;
        }
      }

      // If for some reason the current request wasn't in the query results, add it
      if (!foundCurrent) {
        sum += ratingValue;
        count++;
      }
      
      final averageRating = count > 0 ? sum / count : ratingValue.toDouble();
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(vId)
          .set({
            'rating': averageRating,
            'ratingCount': count, 
          }, SetOptions(merge: true));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thank you for your rating!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
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
        title: const Text("Elderly Ease", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26)),
        backgroundColor: tealGreen,
        elevation: 0,
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.helperId).snapshots(),
        builder: (context, helperSnapshot) {
          if (helperSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final helperData = helperSnapshot.data?.data() as Map<String, dynamic>? ?? widget.helperData ?? {};
          final name = helperData['name'] ?? "Helper";
          final profession = helperData['profession'] ?? "General Helper";
          final area = helperData['area'] ?? "Jayanagar";
          final services = helperData['servicesOffered'] != null ? List<String>.from(helperData['servicesOffered']) : ["Elderly Care"];
          
          // Fake rating logic (Strictly 0 and 0) - Match List Screen
          double displayRatingVal = (helperData['rating'] ?? 0.0).toDouble();
          int displayCountVal = helperData['ratingCount'] ?? 0;
          
          if (displayRatingVal == 0.0 && displayCountVal == 0) {
            displayRatingVal = 4.0;
            displayCountVal = 3;
          }
          
          final rating = displayRatingVal.toStringAsFixed(1);

          // Now listen to the request status in real-time
          // Fetch all requests for this elder and filter locally for case-insensitive matching
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('requests')
                .where('elderId', isEqualTo: Global.uid?.toLowerCase())
                .snapshots(),
            builder: (context, requestSnapshot) {
              // ... (rest is same) ... //
              // Reusing variables later

              String currentStatus = "PENDING";
              String? requestId;
              bool isRated = false;

              if (requestSnapshot.hasData && requestSnapshot.data!.docs.isNotEmpty) {
                // Filter for this specific helper (case-insensitive)
                final vId = widget.helperId.toLowerCase();
                final matchingRequests = requestSnapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final docHelperId = data['helperId']?.toString().toLowerCase();
                  return docHelperId == vId;
                }).toList();
                
                if (matchingRequests.isNotEmpty) {
                  DocumentSnapshot<Object?>? targetDoc;
                  
                  // Priority: Use specific request ID if provided
                  if (widget.specificRequestId != null) {
                    try {
                      targetDoc = matchingRequests.firstWhere((doc) => doc.id == widget.specificRequestId);
                    } catch (e) {
                      // Not found in this helper list (shouldn't happen strictly)
                    }
                  }
                  
                  // Fallback: Use latest request
                  if (targetDoc == null) {
                    matchingRequests.sort((a, b) {
                      final dataA = a.data() as Map<String, dynamic>?;
                      final dataB = b.data() as Map<String, dynamic>?;
                      final tA = dataA?['timestamp'] as Timestamp?;
                      final tB = dataB?['timestamp'] as Timestamp?;
                      return (tB?.millisecondsSinceEpoch ?? 0).compareTo(tA?.millisecondsSinceEpoch ?? 0);
                    });
                    targetDoc = matchingRequests.first;
                  }

                  final latestRequest = targetDoc.data() as Map<String, dynamic>;
                  currentStatus = latestRequest['status'] ?? 'PENDING';
                  requestId = targetDoc.id;
                  isRated = latestRequest['isRated'] ?? false;
                }
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 25, 25, 0),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: tealGreen, width: 2)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, size: 22, color: tealGreen),
                              SizedBox(width: 8),
                              Text("Go Back", style: TextStyle(color: tealGreen, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Main Central Card
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.92,
                        margin: const EdgeInsets.symmetric(vertical: 30),
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 6))],
                        ),
                        child: Column(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 45,
                              backgroundColor: const Color(0xFFE0F2F1),
                              child: Text(
                                (name.isNotEmpty) ? name[0].toUpperCase() : 'H', 
                                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: tealGreen)
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: tealGreen)),
                            const SizedBox(height: 30),

                            // Details
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _elderDetailRow("Role:", profession),
                                  const SizedBox(height: 8),
                                  _elderDetailRow("Location:", area),
                                  const SizedBox(height: 8),
                                  if (helperData['phoneNumber'] != null && helperData['phoneNumber'].toString().isNotEmpty)
                                    _elderDetailRow("Contact:", helperData['phoneNumber']),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      const Text("Rating: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      const Icon(Icons.star, size: 24, color: Colors.amber),
                                      const SizedBox(width: 8),
                                      Text(rating, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Text(
                                        "($displayCountVal services attended)",
                                        style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 35),
                                  const Text("Services Offered:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: tealGreen)),
                                  const SizedBox(height: 15),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: services.map((s) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(color: const Color(0xFFF1F8F7), borderRadius: BorderRadius.circular(12), border: Border.all(color: tealGreen.withValues(alpha: 0.2))),
                                      child: Text(s, style: const TextStyle(color: tealGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                                    )).toList(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Status Section (Real-time)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 25),
                              decoration: BoxDecoration(
                                color: _getStatusBackgroundColor(currentStatus),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: _getStatusColor(currentStatus), width: 2),
                              ),
                              child: Column(
                                children: [
                                  const Text("Current Status:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getStatusInfo(currentStatus, name), 
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: _getStatusColor(currentStatus), fontWeight: FontWeight.bold, fontSize: 24),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 25),
                            
                            if (currentStatus == 'ACCEPTED' && requestId != null) ...[
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                                      requestId: requestId!,
                                      otherUserName: name,
                                      isElder: true,
                                    )));
                                  },
                                  icon: const Icon(Icons.chat, size: 28),
                                  label: const Text("Chat with Helper", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: tealGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 25),
                            ],

                            // Rating Section (Only show when COMPLETED and not rated)
                            if (currentStatus == 'COMPLETED' && !isRated && requestId != null) ...[
                              Builder(
                                builder: (context) {
                                  final safeRequestId = requestId!; // Safe to use ! here because of the null check above
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(25),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F8F7),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(color: tealGreen.withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text("Rate this Helper", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: tealGreen)),
                                        const SizedBox(height: 20),
                                        const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.star, color: Colors.amber, size: 36),
                                            Icon(Icons.star, color: Colors.amber, size: 36),
                                            Icon(Icons.star, color: Colors.amber, size: 36),
                                            Icon(Icons.star, color: Colors.amber, size: 36),
                                            Icon(Icons.star, color: Colors.amber, size: 36),
                                          ],
                                        ),
                                        const SizedBox(height: 25),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey, width: 2)),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _selectedRating,
                                              isExpanded: true,
                                              iconSize: 36,
                                              onChanged: (val) => setState(() => _selectedRating = val!),
                                              items: ["Select Rating", "1", "2", "3", "4", "5"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))).toList(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            onPressed: () => _submitRating(safeRequestId),
                                            style: ElevatedButton.styleFrom(backgroundColor: tealGreen, foregroundColor: Colors.white),
                                            child: const Text("Submit Rating", style: TextStyle(fontSize: 18)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ] else if (currentStatus == 'COMPLETED' && isRated) ...[
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                                child: const Center(child: Text("Thank you for rating!", style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold))),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _elderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
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

  Color _getStatusBackgroundColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange[50]!;
      case 'ACCEPTED': return Colors.blue[50]!;
      case 'COMPLETED': return Colors.green[50]!;
      case 'REJECTED': return Colors.red[50]!;
      default: return Colors.grey[50]!;
    }
  }

  String _getStatusInfo(String status, String name) {
    switch (status.toUpperCase()) {
      case 'PENDING': return "Request Pending...";
      case 'ACCEPTED': return "Matched with $name!";
      case 'COMPLETED': return "Help Completed";
      case 'REJECTED': return "Request Rejected";
      default: return "No Active Request";
    }
  }
}
