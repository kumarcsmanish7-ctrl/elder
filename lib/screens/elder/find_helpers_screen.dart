import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'helper_detail_screen.dart';
import 'elder_request_history_screen.dart';
import '../common/chat_screen.dart';
import 'elder_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/session_service.dart';
import '../../services/global.dart';
import '../common/chat_list_screen.dart';

class FindHelpersScreen extends StatefulWidget {
  const FindHelpersScreen({super.key});

  @override
  State<FindHelpersScreen> createState() => _FindHelpersScreenState();
}

class _FindHelpersScreenState extends State<FindHelpersScreen> {
  String? get currentUid => Global.uid;

  String _selectedProfession = "All";
  String _selectedArea = "All Areas";
  String _elderArea = "Jayanagar"; // Elder's actual area
  String _elderName = "Elder"; // Elder's actual name

  final List<String> _professions = ["All", "Nurse", "Caretaker", "Medical Assistant", "Physiotherapist", "Cook", "Housekeeper", "General Helper"];
  final List<String> _areas = ["All Areas", "Jayanagar", "Kengeri", "Pattengere", "Mysore Road", "Rajajinagar", "Malleshwaram", "Koramangala", "Indiranagar", "Whitefield", "Electronic City", "BTM Layout"];

  @override
  void initState() {
    super.initState();
    _loadElderArea();
  }

  Future<void> _loadElderArea() async {
    final uid = currentUid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _elderArea = data['area'] ?? 'Jayanagar';
          _elderName = data['name'] ?? 'Elder';
        });
      }
    } catch (e) {
      debugPrint('Error loading elder area: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const tealGreen = Color(0xFF00897B);
    const lightTeal = Color(0xFFE0F2F1);

    return DefaultTabController(
      length: 2,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('elderId', isEqualTo: currentUid)
            .snapshots(),
        builder: (context, requestSnapshot) {
          final allRequests = requestSnapshot.data?.docs ?? [];
          
          // Map helperId -> latest request (normalize to lowercase for consistency)
          Map<String, DocumentSnapshot> latestRequestByHelper = {};
          for (var doc in allRequests) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            
            final hid = data['helperId']?.toString().toLowerCase();
            if (hid != null) {
              final existing = latestRequestByHelper[hid];
              if (existing == null) {
                latestRequestByHelper[hid] = doc;
              } else {
                final existingData = existing.data() as Map<String, dynamic>?;
                final tExisting = existingData?['timestamp'] as Timestamp?;
                final tNew = data['timestamp'] as Timestamp?;
                
                final msExisting = tExisting?.millisecondsSinceEpoch ?? 0;
                final msNew = tNew?.millisecondsSinceEpoch ?? 0;
                
                if (msNew >= msExisting) {
                  latestRequestByHelper[hid] = doc;
                }
              }
            }
          }

          return Scaffold(
            backgroundColor: lightTeal,
            appBar: AppBar(
              title: const Text("Elderly Ease", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              backgroundColor: tealGreen,
              elevation: 0,
              bottom: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: [
                  Tab(text: "Find Helpers"),
                  Tab(text: "Active Requests"),
                ],
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout') {
                      SessionService().logout();
                      FirebaseAuth.instance.signOut();
                    } else if (value == 'profile') {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ElderProfileScreen()));
                    } else if (value == 'history') {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ElderRequestHistoryScreen()));
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white24,
                      child: Text(
                        (currentUid != null && currentUid!.isNotEmpty) ? currentUid![0].toUpperCase() : 'E',
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
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(Icons.history, color: tealGreen),
                          SizedBox(width: 8),
                          Text("Request History", style: TextStyle(fontWeight: FontWeight.w600)),
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
            body: TabBarView(
              children: [
                // Tab 1: Find Helpers
                Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildFilters(tealGreen),
                    const SizedBox(height: 20),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'helper').where('isAvailable', isEqualTo: true).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                          
                          final docs = snapshot.data?.docs ?? [];
                          var filteredDocs = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            bool professionMatch = _selectedProfession == "All" || data['profession'] == _selectedProfession;
                            bool areaMatch = _selectedArea == "All Areas" || data['area'] == _selectedArea;
                            return professionMatch && areaMatch && doc.id != currentUid;
                          }).toList();

                          if (filteredDocs.isEmpty) return const Center(child: Text("No helpers found.", style: TextStyle(fontSize: 18)));

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final data = filteredDocs[index].data() as Map<String, dynamic>;
                              final docId = filteredDocs[index].id;
                              final latestReq = latestRequestByHelper[docId.toLowerCase()];
                              return _buildHelperCard(data, docId, latestReq);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                // Tab 2: Active Requests
                _buildActiveRequestsTab(allRequests, tealGreen),
              ],
            ),
            floatingActionButton: StreamBuilder<QuerySnapshot>(
              stream: requestSnapshot.data != null ? Stream.value(requestSnapshot.data!) : const Stream.empty(),
              builder: (context, snapshot) {
                int totalUnread = 0;
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalUnread += (data['unreadCountElder'] ?? 0) as int;
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
        },
      ),
    );
  }

  Widget _buildActiveRequestsTab(List<QueryDocumentSnapshot> allRequests, Color tealGreen) {
    final activeRequests = allRequests.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      final status = data['status'] ?? 'PENDING';
      return status == 'PENDING' || status == 'ACCEPTED' || (status == 'COMPLETED' && !(data['isRated'] == true));
    }).toList();

    if (activeRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text("No Active Requests", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[400])),
          ],
        ),
      );
    }

    activeRequests.sort((a, b) {
      final tA = (a.data() as Map)['timestamp'] as Timestamp?;
      final tB = (b.data() as Map)['timestamp'] as Timestamp?;
      final msA = tA?.millisecondsSinceEpoch ?? 0;
      final msB = tB?.millisecondsSinceEpoch ?? 0;
      return msB.compareTo(msA);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: activeRequests.length,
      itemBuilder: (context, index) {
        final reqDoc = activeRequests[index];
        final data = reqDoc.data() as Map<String, dynamic>;
        final status = (data['status'] ?? 'PENDING').toString().toUpperCase();
        final helperName = data['helperName'] ?? "Helper";
        final isRated = data['isRated'] ?? false;

        bool isAccepted = status == 'ACCEPTED';
        bool isCompleted = status == 'COMPLETED';

        return Dismissible(
          key: Key(reqDoc.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.red[400],
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 25),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
          ),
          onDismissed: (direction) {
             FirebaseFirestore.instance.collection('requests').doc(reqDoc.id).delete();
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request removed")));
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAccepted 
                  ? [const Color(0xFF00897B), const Color(0xFF26A69A)] 
                  : isCompleted
                    ? [const Color(0xFFFFA000), const Color(0xFFFF6F00)]
                    : [Colors.white, Colors.white],
              ),
              color: isAccepted || isCompleted ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: (isAccepted ? tealGreen : Colors.black).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 5))],
              border: isAccepted || isCompleted ? null : Border.all(color: tealGreen.withValues(alpha: 0.3)),
            ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: Icon(
                      isCompleted ? Icons.star_rounded : (isAccepted ? Icons.check_circle_rounded : Icons.hourglass_top_rounded), 
                      color: isAccepted || isCompleted ? Colors.white : tealGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusTitle(status, helperName),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isAccepted || isCompleted ? Colors.white : tealGreen),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCompleted ? "Tap 'Rate Now' to finish" : "Current Status: ${status.toLowerCase()}", 
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isAccepted || isCompleted ? Colors.white70 : Colors.grey[600])
                        ),
                        if (status == 'PENDING') ...[
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () => _undoRequest(reqDoc.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.undo, size: 16, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text("Undo Request", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                  if (isAccepted)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                            requestId: reqDoc.id,
                            otherUserName: helperName,
                            isElder: true,
                          )));
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.chat_bubble_rounded, color: tealGreen),
                        ),
                      ),
                    ),
                  if (isCompleted && !isRated)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => HelperDetailScreen(
                          helperId: data['helperId'],
                          helperData: data,
                        )));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange[800],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text("Rate Now", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }

  Widget _buildFilters(Color tealGreen) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterLabel("Filter by Profession", tealGreen),
          _buildFilterDropdown(_selectedProfession, _professions, (val) => setState(() => _selectedProfession = val!)),
          const SizedBox(height: 20),
          _buildFilterLabel("Filter by Location", tealGreen),
          _buildFilterDropdown(_selectedArea, _areas, (val) => setState(() => _selectedArea = val!)),
        ],
      ),
    );
  }

  Widget _buildFilterLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
    );
  }

  Widget _buildFilterDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F8F7), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 16, color: Colors.black),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHelperCard(Map<String, dynamic> data, String docId, DocumentSnapshot? latestReq) {
    const tealGreen = Color(0xFF00897B);
    String status = "NONE";
    if (latestReq != null) {
      final reqData = latestReq.data() as Map<String, dynamic>?;
      status = reqData?['status']?.toString().toUpperCase() ?? "PENDING";
    }

    // Fake rating logic (Strictly 0 and 0) - Match List Screen
    double displayRatingVal = (data['rating'] ?? 0.0).toDouble();
    int displayCountVal = data['ratingCount'] ?? 0;
    
    if (displayRatingVal == 0.0 && displayCountVal == 0) {
      displayRatingVal = 4.0;
      displayCountVal = 3;
    }
    
    final rating = displayRatingVal.toStringAsFixed(1);
    final ratingCount = displayCountVal;

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => HelperDetailScreen(helperId: docId, helperData: data)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFE0F2F1),
              child: Text(
                (data['name'] != null && data['name'].toString().isNotEmpty) 
                    ? data['name'].toString()[0].toUpperCase() 
                    : 'V', 
                style: const TextStyle(fontWeight: FontWeight.bold, color: tealGreen, fontSize: 28)
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? "Helper", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 4),
                  Text("${data['profession'] ?? 'Helper'} · ${data['area'] ?? 'Jayanagar'}", style: const TextStyle(color: Colors.grey, fontSize: 16)),
                  if (data['phoneNumber'] != null && data['phoneNumber'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text("📞 ${data['phoneNumber']}", style: const TextStyle(color: tealGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(rating, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 2),
                      Text("($ratingCount services)", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            _buildRequestButton(docId, data, status, latestReq, tealGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestButton(String docId, Map<String, dynamic> helperData, String status, DocumentSnapshot? latestReq, Color tealGreen) {
    if (status == "PENDING" && latestReq != null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1), // 0.1 * 255
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange, width: 1.5),
        ),
        child: InkWell(
          onTap: () => _undoRequest(latestReq.id),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.undo, size: 16, color: Colors.orange),
                SizedBox(width: 6),
                Text("Undo", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    } else if (status == "ACCEPTED") {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF64DD17)]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
              requestId: latestReq!.id,
              otherUserName: helperData['name'] ?? "Helper",
              isElder: true,
            )));
          },
          icon: const Icon(Icons.check_circle, size: 16, color: Colors.white),
          label: const Text("Processing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    } else if (status == "COMPLETED" && latestReq != null) {
      final reqData = latestReq.data() as Map<String, dynamic>;
      final isRated = reqData['isRated'] ?? false;
      
      if (!isRated) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFA000), Color(0xFFFF6F00)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => HelperDetailScreen(
                helperId: docId,
                helperData: helperData,
                specificRequestId: latestReq.id,
              )));
            },
            icon: const Icon(Icons.star, size: 16, color: Colors.white),
            label: const Text("Rate Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );
      }
    } 
    // If status is COMPLETED or REJECTED or NONE, show Request button
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [tealGreen, const Color(0xFF00796B)]),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: tealGreen.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ElevatedButton(
        onPressed: () => _sendRequest(docId, helperData['name'] ?? 'Helper', helperData['profession']),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text("Request", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Future<void> _sendRequest(String helperId, String name, String? profession) async {
    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'helperId': helperId.toLowerCase(),
        'helperName': name,
        'elderId': currentUid?.toLowerCase(),
        'elderName': _elderName,
        'status': 'PENDING',
        'timestamp': FieldValue.serverTimestamp(),
        'serviceType': profession ?? "General Help",
        'location': _elderArea,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request sent to $name!"), backgroundColor: const Color(0xFF00897B)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _undoRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request undone."), backgroundColor: Colors.grey));
      }
    } catch (e) {
      debugPrint("Error undoing request: $e");
    }
  }



  String _getStatusTitle(String status, String helperName) {
    switch (status.toUpperCase()) {
      case 'PENDING': return "Finding your perfect helper...";
      case 'ACCEPTED': return "Request is processing...";
      case 'COMPLETED': return "Service finished by $helperName ✨";
      case 'REJECTED': return "Helper unavailable. Try another?";
      default: return "Connecting you with helpers...";
    }
  }
}
